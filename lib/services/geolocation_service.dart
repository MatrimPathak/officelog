import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/logger/app_logger.dart';
import '../services/office_service.dart';
import '../services/attendance_service.dart';
import '../services/notification_service.dart';
import '../utils/working_days_calculator.dart';
import 'dart:math' as math;

class GeolocationService {
  static const String _lastAutoCheckInKey = 'last_auto_checkin';
  static const String _geofenceEnabledKey = 'geofence_enabled';

  final OfficeService _officeService = OfficeService();
  final AttendanceService _attendanceService = AttendanceService();

  // Request location permissions
  static Future<bool> requestLocationPermissions() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      // Request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      // Accept whileInUse or always permission
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      AppLogger.error('Error requesting location permissions: $e', tag: 'GeolocationService');
      return false;
    }
  }

  // Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      // Check permissions first
      if (!await requestLocationPermissions()) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      AppLogger.error('Error getting current location: $e', tag: 'GeolocationService');
      return null;
    }
  }

  // Check if user is within office geofence
  Future<bool> isWithinOfficeGeofence() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      // Get current location
      final position = await getCurrentLocation();
      if (position == null) return false;

      // Get user's office
      final office = await _officeService.getUserOffice(user.uid);
      if (office == null) return false;

      // Calculate distance
      final distance = _calculateDistance(
        position.latitude,
        position.longitude,
        office.latitude,
        office.longitude,
      );

      return distance <= office.radius;
    } catch (e) {
      AppLogger.error('Error checking geofence: $e', tag: 'GeolocationService');
      return false;
    }
  }

  // Perform automatic check-in if conditions are met
  Future<bool> performAutoCheckIn() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final today = DateTime.now();

      // Check if it's a working day
      if (!WorkingDaysCalculator.isWorkingDay(today)) {
        return false;
      }

      // Check if already checked in today (auto or manual)
      final hasMarked = await _attendanceService.hasMarkedAttendanceToday(
        user.uid,
      );
      if (hasMarked) {
        return false;
      }

      // Check if already auto-checked in today to prevent duplicates
      if (await _hasAutoCheckedInToday()) {
        return false;
      }

      // Check if within office geofence
      if (!await isWithinOfficeGeofence()) {
        return false;
      }

      // Perform auto check-in
      await _attendanceService.markAttendanceForDate(user.uid, today);

      // Record that we auto-checked in today
      await _recordAutoCheckIn();

      // Show notification
      await NotificationService.showNotification(
        title: 'Auto Check-in Successful',
        body: 'Attendance logged automatically via geo check-in',
        id: 2,
      );

      return true;
    } catch (e) {
      AppLogger.error('Error performing auto check-in: $e', tag: 'GeolocationService');
      return false;
    }
  }

  // Start location monitoring for geofence
  Future<void> startGeofenceMonitoring() async {
    try {
      if (!await requestLocationPermissions()) {
        return;
      }

      // Enable geofence monitoring
      await _setGeofenceEnabled(true);

      // Note: For production, you might want to use a more sophisticated
      // background location service or WorkManager
      AppLogger.info('Geofence monitoring started', tag: 'GeolocationService');
    } catch (e) {
      AppLogger.error('Error starting geofence monitoring: $e', tag: 'GeolocationService');
    }
  }

  // Stop location monitoring
  Future<void> stopGeofenceMonitoring() async {
    try {
      await _setGeofenceEnabled(false);
      AppLogger.info('Geofence monitoring stopped', tag: 'GeolocationService');
    } catch (e) {
      AppLogger.error('Error stopping geofence monitoring: $e', tag: 'GeolocationService');
    }
  }

  // Check if geofence monitoring is enabled
  Future<bool> isGeofenceEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_geofenceEnabledKey) ?? false;
  }

  // Get distance to office
  Future<double?> getDistanceToOffice() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final position = await getCurrentLocation();
      if (position == null) return null;

      final office = await _officeService.getUserOffice(user.uid);
      if (office == null) return null;

      return _calculateDistance(
        position.latitude,
        position.longitude,
        office.latitude,
        office.longitude,
      );
    } catch (e) {
      return null;
    }
  }

  // Get office location details
  Future<Map<String, dynamic>?> getOfficeLocationInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final office = await _officeService.getUserOffice(user.uid);
      if (office == null) return null;

      final position = await getCurrentLocation();
      final distance = position != null
          ? _calculateDistance(
              position.latitude,
              position.longitude,
              office.latitude,
              office.longitude,
            )
          : null;

      return {
        'office': office,
        'currentLocation': position != null
            ? {'lat': position.latitude, 'lng': position.longitude}
            : null,
        'distance': distance,
        'withinRange': distance != null ? distance <= office.radius : false,
      };
    } catch (e) {
      return null;
    }
  }

  // Private helper methods
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // Earth's radius in meters

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  Future<bool> _hasAutoCheckedInToday() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastAutoCheckIn = prefs.getString(_lastAutoCheckInKey);

      if (lastAutoCheckIn == null) return false;

      final lastCheckInDate = DateTime.parse(lastAutoCheckIn);
      final today = DateTime.now();

      return lastCheckInDate.year == today.year &&
          lastCheckInDate.month == today.month &&
          lastCheckInDate.day == today.day;
    } catch (e) {
      return false;
    }
  }

  Future<void> _recordAutoCheckIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _lastAutoCheckInKey,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      AppLogger.error('Error recording auto check-in: $e', tag: 'GeolocationService');
    }
  }

  Future<void> _setGeofenceEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_geofenceEnabledKey, enabled);
    } catch (e) {
      AppLogger.error('Error setting geofence enabled: $e', tag: 'GeolocationService');
    }
  }

  // Test geofence functionality
  Future<Map<String, dynamic>> testGeofence() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'No user logged in'};
      }

      final position = await getCurrentLocation();
      if (position == null) {
        return {'success': false, 'error': 'Could not get location'};
      }

      final office = await _officeService.getUserOffice(user.uid);
      if (office == null) {
        return {'success': false, 'error': 'No office assigned to user'};
      }

      final distance = _calculateDistance(
        position.latitude,
        position.longitude,
        office.latitude,
        office.longitude,
      );

      final withinRange = distance <= office.radius;

      return {
        'success': true,
        'currentLocation': {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
        'office': {
          'name': office.name,
          'latitude': office.latitude,
          'longitude': office.longitude,
          'radius': office.radius,
        },
        'distance': distance,
        'withinRange': withinRange,
        'canAutoCheckIn':
            withinRange && WorkingDaysCalculator.isWorkingDay(DateTime.now()),
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
