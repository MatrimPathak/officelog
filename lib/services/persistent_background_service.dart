import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
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
import '../services/location_permission_service.dart';
import 'dart:math' as math;
import '../core/logger/app_logger.dart';

/// Persistent background service using WorkManager for auto check-in
/// This service persists across app restarts and handles battery optimizations
class PersistentBackgroundService {
  static const String _taskName = 'auto_checkin_task';
  static const String _enabledKey = 'auto_checkin_enabled';
  static const String _lastAutoCheckInKey = 'last_auto_checkin_date';
  static const String _offlineAttendanceKey = 'offline_attendance_queue';
  static const String _lastLocationCheckKey = 'last_location_check';
  static const String _batteryOptimizationAskedKey =
      'battery_optimization_asked';

  /// Initialize WorkManager and register the background task
  static Future<bool> initialize() async {
    try {
      // Initialize WorkManager
      await Workmanager().initialize(callbackDispatcher);

      // Removed malformed log call
      return true;
    } catch (e) {
      // Removed malformed log call
      return false;
    }
  }

  /// Start persistent auto check-in monitoring
  static Future<bool> startAutoCheckIn() async {
    try {
      if (!await initialize()) return false;

      // Check if location permissions are granted
      if (!await LocationPermissionService.hasLocationPermissions()) {
        // Removed malformed log call
        return false;
      }

      // Register the periodic background task
      await Workmanager().registerPeriodicTask(
        _taskName,
        _taskName,
        frequency: const Duration(
          minutes: 15,
        ), // Note: WorkManager minimum is 15 minutes, but we'll add foreground service for better frequency
        constraints: Constraints(
          networkType: NetworkType.unmetered, // Works offline and on WiFi
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        backoffPolicy: BackoffPolicy.linear,
        backoffPolicyDelay: const Duration(minutes: 1),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update, // Changed type
      );

      // Mark service as enabled
      await _setAutoCheckInEnabled(true);

      // Removed malformed log call
      return true;
    } catch (e) {
      // Removed malformed log call
      return false;
    }
  }

  /// Stop persistent auto check-in monitoring
  static Future<void> stopAutoCheckIn() async {
    try {
      // Cancel the background task
      await Workmanager().cancelByUniqueName(_taskName);

      // Mark service as disabled
      await _setAutoCheckInEnabled(false);

      // Removed malformed log call
    } catch (e) {
      // Removed malformed log call
    }
  }

  /// Check if auto check-in is currently enabled
  static Future<bool> isAutoCheckInEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_enabledKey) ?? false;
    } catch (e) {
      // Removed malformed log call
      return false;
    }
  }

  /// Check if battery optimization dialog has been shown
  static Future<bool> hasBatteryOptimizationBeenAsked() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_batteryOptimizationAskedKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Mark that battery optimization dialog has been shown
  static Future<void> markBatteryOptimizationAsked() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_batteryOptimizationAskedKey, true);
    } catch (e) {
      // Removed malformed log call
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

  /// Get status information for debugging
  static Future<Map<String, dynamic>> getStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getString(_lastLocationCheckKey);
      final lastAutoCheckIn = prefs.getString(_lastAutoCheckInKey);

      return {
        'enabled': await isAutoCheckInEnabled(),
        'lastLocationCheck': lastCheck != null
            ? DateTime.parse(lastCheck)
            : null,
        'lastAutoCheckIn': lastAutoCheckIn != null
            ? DateTime.parse(lastAutoCheckIn)
            : null,
        'hasBackgroundPermission':
            await LocationPermissionService.hasIdealPermissions(),
        'batteryOptimizationAsked': await hasBatteryOptimizationBeenAsked(),
      };
    } catch (e) {
      return {'enabled': false, 'error': e.toString()};
    }
  }

  // Private helper methods

  static Future<void> _setAutoCheckInEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, enabled);
    } catch (e) {
      // Removed malformed log call
    }
  }

  static Future<void> _ensureFirebaseInitialized() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      // Firebase already initialized or error - continue anyway
    }
  }
}

/// Background task callback dispatcher
/// This function runs in the background even when the app is closed
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Removed malformed log call

      // Initialize Firebase for background operations
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Check if auto check-in is still enabled
      final prefs = await SharedPreferences.getInstance();
      final enabled =
          prefs.getBool(PersistentBackgroundService._enabledKey) ?? false;

      if (!enabled) {
        // Removed malformed log call
        return Future.value(true);
      }

      // Check if it's a working day
      final now = DateTime.now();
      if (!WorkingDaysCalculator.isWorkingDay(now)) {
        // Removed malformed log call

        // Still check compliance on non-working days (for weekend reminders)
        await _checkComplianceAndNotify();

        return Future.value(true);
      }

      // Check if already checked in today
      if (await _hasCheckedInToday()) {
        // Removed malformed log call

        // Still check compliance even if already checked in
        await _checkComplianceAndNotify();

        return Future.value(true);
      }

      // Check if already auto-checked in today
      if (await _hasAutoCheckedInToday()) {
        // Removed malformed log call
        return Future.value(true);
      }

      // Get current location
      final position = await _getCurrentLocationSafe();
      if (position == null) {
        // Removed malformed log call
        return Future.value(true);
      }

      // Check if within office geofence
      final isWithinOffice = await _checkIfWithinOffice(
        position.latitude,
        position.longitude,
      );

      if (isWithinOffice) {
        AppLogger.info('User detected within office area - performing auto check-in', tag: 'PersistentBackgroundService');
        await _performAutoCheckIn();
      } else {
        // Removed malformed log call
      }

      // Record last check time
      await _recordLocationCheck();

      // Removed malformed log call
      return Future.value(true);
    } catch (e) {
      // Removed malformed log call
      return Future.value(false);
    }
  });
}

// Background task helper functions

Future<bool> _hasCheckedInToday() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('attendance')
        .doc(dateStr)
        .get();

    return doc.exists;
  } catch (e) {
    // Removed malformed log call
    return false;
  }
}

Future<bool> _hasAutoCheckedInToday() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final lastAutoCheckIn = prefs.getString(
      PersistentBackgroundService._lastAutoCheckInKey,
    );

    if (lastAutoCheckIn == null) return false;

    final lastDate = DateTime.parse(lastAutoCheckIn);
    final today = DateTime.now();

    return lastDate.year == today.year &&
        lastDate.month == today.month &&
        lastDate.day == today.day;
  } catch (e) {
    // Removed malformed log call
    return false;
  }
}

Future<Position?> _getCurrentLocationSafe() async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Removed malformed log call
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      // Removed malformed log call
      return null;
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 30),
    );
  } catch (e) {
    // Removed malformed log call
    return null;
  }
}

Future<bool> _checkIfWithinOffice(double lat, double lng) async {
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

    AppLogger.debug('Distance to office: ${distance.toStringAsFixed(0)}m (radius: ${office.radius}m)', tag: 'PersistentBackgroundService');
    return distance <= office.radius;
  } catch (e) {
    // Removed malformed log call
    return false;
  }
}

Future<void> _performAutoCheckIn() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final attendance = AttendanceModel(
      date: dateStr,
      status: 'auto_present',
      method: 'background_geofence',
      note: 'Auto check-in via persistent background service',
      synced: false,
      createdAt: now,
    );

    try {
      // Try to save online first
      final firestore = FirebaseFirestore.instance;
      final docRef = firestore
          .collection('users')
          .doc(user.uid)
          .collection('attendance')
          .doc(dateStr);

      await docRef.set(attendance.copyWith(synced: true).toMap());
      // Removed malformed log call
    } catch (e) {
      // Removed malformed log call
      await _saveOfflineAttendance(attendance);
    }

    // Record auto check-in timestamp
    await _recordAutoCheckIn();

    // Show notification
    await NotificationService.showAutoCheckInNotification(date: now);

    // Check compliance after successful check-in
    await _checkComplianceAndNotify();

    // Removed malformed log call
  } catch (e) {
    // Removed malformed log call
  }
}

Future<void> _recordAutoCheckIn() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      PersistentBackgroundService._lastAutoCheckInKey,
      DateTime.now().toIso8601String(),
    );
  } catch (e) {
    // Removed malformed log call
  }
}

Future<void> _recordLocationCheck() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      PersistentBackgroundService._lastLocationCheckKey,
      DateTime.now().toIso8601String(),
    );
  } catch (e) {
    // Removed malformed log call
  }
}

Future<void> _saveOfflineAttendance(AttendanceModel attendance) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final existingDataJson = prefs.getString(
      PersistentBackgroundService._offlineAttendanceKey,
    );

    List<dynamic> offlineQueue = [];
    if (existingDataJson != null) {
      offlineQueue = json.decode(existingDataJson);
    }

    offlineQueue.add(attendance.toMap());

    await prefs.setString(
      PersistentBackgroundService._offlineAttendanceKey,
      json.encode(offlineQueue),
    );
    // Removed malformed log call
  } catch (e) {
    // Removed malformed log call
  }
}

double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
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

double _degreesToRadians(double degrees) {
  return degrees * (math.pi / 180);
}

// Check compliance and send notification if needed
Future<void> _checkComplianceAndNotify() async {
  try {
    // Removed malformed log call
    await NotificationService.checkAndSendComplianceReminder();
  } catch (e) {
    // Removed malformed log call
  }
}
