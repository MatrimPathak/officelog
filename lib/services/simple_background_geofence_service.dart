import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';
import '../models/attendance_model.dart';
import '../utils/working_days_calculator.dart';
import '../services/notification_service.dart';
import '../services/office_service.dart';
import 'dart:convert';
import 'dart:math' as math;
import '../core/logger/app_logger.dart';

/// Simple background geofencing service using Timer-based location checks
/// This approach avoids complex dependencies while providing effective auto check-in
class SimpleBackgroundGeofenceService {
  static const String _serviceEnabledKey = 'simple_geofence_enabled';
  static const String _lastAutoCheckInKey = 'last_auto_checkin';
  static const String _offlineAttendanceKey = 'offline_attendance_queue';
  static const String _lastLocationCheckKey = 'last_location_check';

  static Timer? _locationTimer;
  static bool _isInitialized = false;
  static bool _isChecking = false;

  /// Initialize the service
  static Future<bool> initialize() async {
    try {
      if (_isInitialized) return true;

      // Initialize Firebase if not already done
      await _ensureFirebaseInitialized();

      _isInitialized = true;
      // Removed malformed log call
      return true;
    } catch (e) {
      // Removed malformed log call
      return false;
    }
  }

  /// Start background monitoring with periodic location checks
  static Future<bool> startMonitoring() async {
    try {
      if (!await initialize()) return false;

      // Check if already monitoring
      if (await isMonitoring()) {
        // Removed malformed log call
        return true;
      }

      // Request location permissions
      if (!await _hasLocationPermissions()) {
        // Removed malformed log call
        return false;
      }

      // Get user's office location
      final officeService = OfficeService();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final office = await officeService.getUserOffice(user.uid);
      if (office == null) {
        // Removed malformed log call
        return false;
      }

      // Start periodic location checking
      _startPeriodicLocationCheck();

      // Mark service as enabled
      await _setServiceEnabled(true);

      AppLogger.info('Simple background geofencing started for office: ${office.name}', tag: 'SimpleBackgroundGeofenceService');
      return true;
    } catch (e) {
      // Removed malformed log call
      return false;
    }
  }

  /// Stop background monitoring
  static Future<void> stopMonitoring() async {
    try {
      _locationTimer?.cancel();
      _locationTimer = null;

      // Mark service as disabled
      await _setServiceEnabled(false);

      // Removed malformed log call
    } catch (e) {
      AppLogger.error('Error occurred: $e', tag: 'SimpleBackgroundGeofenceService');
    }
  }

  /// Check if monitoring is active
  static Future<bool> isMonitoring() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_serviceEnabledKey) ?? false;
      return enabled && _locationTimer != null;
    } catch (e) {
      return false;
    }
  }

  /// Start periodic location checking
  static void _startPeriodicLocationCheck() {
    // Cancel any existing timer
    _locationTimer?.cancel();

    // Start new timer - check every 5 minutes
    _locationTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      await _performLocationCheck();
    });

    // Also do an immediate check
    _performLocationCheck();
  }

  /// Perform a single location check
  static Future<void> _performLocationCheck() async {
    if (_isChecking) return; // Prevent concurrent checks

    try {
      _isChecking = true;

      // Check if service should still be running
      if (!await isMonitoring()) {
        _locationTimer?.cancel();
        _locationTimer = null;
        return;
      }

      // Check if it's a working day
      final now = DateTime.now();
      if (!WorkingDaysCalculator.isWorkingDay(now)) {
        // Removed malformed log call
        return;
      }

      // Check if already checked in today
      if (await _hasCheckedInToday()) {
        // Removed malformed log call
        return;
      }

      // Get current location
      final position = await _getCurrentLocationSafe();
      if (position == null) {
        // Removed malformed log call
        return;
      }

      // Check if within office geofence
      final isWithinOffice = await _checkIfWithinOffice(
        position.latitude,
        position.longitude,
      );

      if (isWithinOffice) {
        // Removed malformed log call
        await _performAutoCheckIn();
      } else {
        final distance = await _getDistanceToOffice(position);
        AppLogger.debug('User outside office area (${distance}m away)', tag: 'SimpleBackgroundGeofenceService');
      }

      // Record last check time
      await _recordLocationCheck();
    } catch (e) {
      AppLogger.error('Error occurred: $e', tag: 'SimpleBackgroundGeofenceService');
    } finally {
      _isChecking = false;
    }
  }

  /// Perform automatic check-in
  static Future<void> _performAutoCheckIn() async {
    try {
      await _ensureFirebaseInitialized();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Check if already auto-checked in today
      if (await _hasAutoCheckedInToday()) {
        return;
      }

      final attendance = AttendanceModel(
        date: dateStr,
        status: 'auto_present',
        method: 'geofence',
        note: 'Auto check-in via background location',
        synced: false,
        createdAt: now,
      );

      try {
        // Try to save online first
        final firestore = FirebaseFirestore.instance;

        // Write to new schema only
        final docRef = firestore
            .collection('users')
            .doc(user.uid)
            .collection('attendance')
            .doc(dateStr);
        await docRef.set(attendance.copyWith(synced: true).toMap());
        // Removed malformed log call
      } catch (e) {
        // Removed malformed log call

        // Save to offline queue
        await _saveOfflineAttendance(attendance);
      }

      // Record auto check-in timestamp
      await _recordAutoCheckIn();

      // Show notification
      await NotificationService.showAutoCheckInNotification(date: now);

      // Removed malformed log call
    } catch (e) {
      AppLogger.error('Error occurred: $e', tag: 'SimpleBackgroundGeofenceService');
    }
  }

  /// Sync offline attendance data
  static Future<void> syncOfflineAttendance() async {
    try {
      await _ensureFirebaseInitialized();

      final prefs = await SharedPreferences.getInstance();
      final offlineDataJson = prefs.getString(_offlineAttendanceKey);

      if (offlineDataJson == null) return;

      final List<dynamic> offlineQueue = json.decode(offlineDataJson);
      if (offlineQueue.isEmpty) return;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      for (final attendanceData in offlineQueue) {
        final attendance = AttendanceModel.fromMap(attendanceData);

        // Write to new schema
        final docRef = firestore
            .collection('users')
            .doc(user.uid)
            .collection('attendance')
            .doc(attendance.date);

        batch.set(docRef, attendance.copyWith(synced: true).toMap());
      }

      await batch.commit();

      // Clear offline queue
      await prefs.remove(_offlineAttendanceKey);

      // Removed malformed log call
    } catch (e) {
      // Removed malformed log call
    }
  }

  // Private helper methods

  static Future<void> _ensureFirebaseInitialized() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      // Firebase already initialized
    }
  }

  static Future<bool> _hasLocationPermissions() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      LocationPermission permission = await Geolocator.checkPermission();
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      return false;
    }
  }

  static Future<Position?> _getCurrentLocationSafe() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 30),
      );
    } catch (e) {
      AppLogger.error('Error occurred: $e', tag: 'SimpleBackgroundGeofenceService');
      return null;
    }
  }

  static Future<bool> _checkIfWithinOffice(double lat, double lng) async {
    try {
      final officeService = OfficeService();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final office = await officeService.getUserOffice(user.uid);
      if (office == null) return false;

      final distance = _calculateDistance(
        lat,
        lng,
        office.latitude,
        office.longitude,
      );
      return distance <= office.radius;
    } catch (e) {
      return false;
    }
  }

  static Future<double?> _getDistanceToOffice(Position position) async {
    try {
      final officeService = OfficeService();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final office = await officeService.getUserOffice(user.uid);
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

  static Future<bool> _hasCheckedInToday() async {
    try {
      await _ensureFirebaseInitialized();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Check new schema
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('attendance')
          .doc(dateStr)
          .get();

      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> _hasAutoCheckedInToday() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastAutoCheckIn = prefs.getString(_lastAutoCheckInKey);

      if (lastAutoCheckIn == null) return false;

      final lastDate = DateTime.parse(lastAutoCheckIn);
      final today = DateTime.now();

      return lastDate.year == today.year &&
          lastDate.month == today.month &&
          lastDate.day == today.day;
    } catch (e) {
      return false;
    }
  }

  static Future<void> _recordAutoCheckIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _lastAutoCheckInKey,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      AppLogger.error('Error occurred: $e', tag: 'SimpleBackgroundGeofenceService');
    }
  }

  static Future<void> _recordLocationCheck() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _lastLocationCheckKey,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      AppLogger.error('Error occurred: $e', tag: 'SimpleBackgroundGeofenceService');
    }
  }

  static Future<void> _saveOfflineAttendance(AttendanceModel attendance) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingDataJson = prefs.getString(_offlineAttendanceKey);

      List<dynamic> offlineQueue = [];
      if (existingDataJson != null) {
        offlineQueue = json.decode(existingDataJson);
      }

      offlineQueue.add(attendance.toMap());

      await prefs.setString(_offlineAttendanceKey, json.encode(offlineQueue));
      // Removed malformed log call
    } catch (e) {
      AppLogger.error('Error occurred: $e', tag: 'SimpleBackgroundGeofenceService');
    }
  }

  static double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadius = 6371000; // Earth's radius in meters

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLng = _degreesToRadians(lng2 - lng1);

    double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  static Future<void> _setServiceEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_serviceEnabledKey, enabled);
    } catch (e) {
      AppLogger.error('Error occurred: $e', tag: 'SimpleBackgroundGeofenceService');
    }
  }

  /// Get last location check time for debugging
  static Future<DateTime?> getLastLocationCheck() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getString(_lastLocationCheckKey);
      return lastCheck != null ? DateTime.parse(lastCheck) : null;
    } catch (e) {
      return null;
    }
  }

  /// Manual trigger for testing
  static Future<bool> triggerLocationCheck() async {
    await _performLocationCheck();
    return true;
  }
}
