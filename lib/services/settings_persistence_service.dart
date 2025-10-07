import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../core/logger/app_logger.dart';

/// Centralized service for managing all app settings persistence
/// Ensures all user preferences are properly saved and restored
class SettingsPersistenceService {
  // Settings keys
  static const String _reminderEnabledKey = 'reminder_enabled';
  static const String _reminderTimeHourKey = 'reminder_time_hour';
  static const String _reminderTimeMinuteKey = 'reminder_time_minute';
  static const String _autoCheckInEnabledKey = 'auto_checkin_enabled';
  static const String _legacyGeofenceEnabledKey = 'simple_geofence_enabled';
  static const String _batteryOptimizationAskedKey =
      'battery_optimization_asked';
  static const String _themeKey = 'theme_mode';
  static const String _firstLaunchKey = 'first_launch';
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _lastSyncTimeKey = 'last_sync_time';
  static const String _lastLocationCheckKey = 'last_location_check';
  static const String _lastAutoCheckInKey = 'last_auto_checkin_date';
  static const String _locationPermissionAskedKey = 'location_permission_asked';
  static const String _notificationPermissionAskedKey =
      'notification_permission_asked';

  /// Initialize settings service and restore all settings on app start
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Set first launch flag if not set
      if (!prefs.containsKey(_firstLaunchKey)) {
        await prefs.setBool(_firstLaunchKey, true);
        // Removed malformed log call
        await _setDefaultSettings();
      }

      // Removed malformed log call
    } catch (e) {
      // Removed malformed log call
    }
  }

  /// Set default settings for first-time users
  static Future<void> _setDefaultSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Set default reminder settings (disabled by default)
      await prefs.setBool(_reminderEnabledKey, false);
      await prefs.setInt(_reminderTimeHourKey, 10);
      await prefs.setInt(_reminderTimeMinuteKey, 0);

      // Set default auto check-in settings (disabled by default)
      await prefs.setBool(_autoCheckInEnabledKey, false);
      await prefs.setBool(_legacyGeofenceEnabledKey, false);

      // Set default theme (system)
      await prefs.setString(_themeKey, 'system');

      // Set default permission flags
      await prefs.setBool(_batteryOptimizationAskedKey, false);
      await prefs.setBool(_locationPermissionAskedKey, false);
      await prefs.setBool(_notificationPermissionAskedKey, false);

      // Removed malformed log call
    } catch (e) {
      // Removed malformed log call
    }
  }

  /// Reminder Settings
  static Future<bool> isReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_reminderEnabledKey) ?? false;
  }

  static Future<void> setReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reminderEnabledKey, enabled);
  }

  static Future<TimeOfDay> getReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_reminderTimeHourKey) ?? 10;
    final minute = prefs.getInt(_reminderTimeMinuteKey) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static Future<void> setReminderTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_reminderTimeHourKey, time.hour);
    await prefs.setInt(_reminderTimeMinuteKey, time.minute);
  }

  /// Auto Check-in Settings
  static Future<bool> isAutoCheckInEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoCheckInEnabledKey) ?? false;
  }

  static Future<void> setAutoCheckInEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoCheckInEnabledKey, enabled);
  }

  static Future<bool> isLegacyGeofenceEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_legacyGeofenceEnabledKey) ?? false;
  }

  static Future<void> setLegacyGeofenceEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_legacyGeofenceEnabledKey, enabled);
  }

  /// Theme Settings
  static Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? 'system';
  }

  static Future<void> setThemeMode(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme);
  }

  /// Permission Settings
  static Future<bool> hasBatteryOptimizationBeenAsked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_batteryOptimizationAskedKey) ?? false;
  }

  static Future<void> setBatteryOptimizationAsked(bool asked) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_batteryOptimizationAskedKey, asked);
  }

  static Future<bool> hasLocationPermissionBeenAsked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_locationPermissionAskedKey) ?? false;
  }

  static Future<void> setLocationPermissionAsked(bool asked) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_locationPermissionAskedKey, asked);
  }

  static Future<bool> hasNotificationPermissionBeenAsked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationPermissionAskedKey) ?? false;
  }

  static Future<void> setNotificationPermissionAsked(bool asked) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationPermissionAskedKey, asked);
  }

  /// App State Settings
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstLaunchKey) ?? true;
  }

  static Future<void> setFirstLaunchComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLaunchKey, false);
  }

  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  static Future<void> setOnboardingCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, completed);
  }

  /// Sync and Data Settings
  static Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString(_lastSyncTimeKey);
    return timestamp != null ? DateTime.parse(timestamp) : null;
  }

  static Future<void> setLastSyncTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncTimeKey, time.toIso8601String());
  }

  static Future<DateTime?> getLastLocationCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString(_lastLocationCheckKey);
    return timestamp != null ? DateTime.parse(timestamp) : null;
  }

  static Future<void> setLastLocationCheck(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastLocationCheckKey, time.toIso8601String());
  }

  static Future<DateTime?> getLastAutoCheckIn() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString(_lastAutoCheckInKey);
    return timestamp != null ? DateTime.parse(timestamp) : null;
  }

  static Future<void> setLastAutoCheckIn(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastAutoCheckInKey, time.toIso8601String());
  }

  /// Get all settings as a map for debugging
  static Future<Map<String, dynamic>> getAllSettings() async {
    return {
      'reminder_enabled': await isReminderEnabled(),
      'reminder_time': await getReminderTime(),
      'auto_checkin_enabled': await isAutoCheckInEnabled(),
      'legacy_geofence_enabled': await isLegacyGeofenceEnabled(),
      'theme_mode': await getThemeMode(),
      'battery_optimization_asked': await hasBatteryOptimizationBeenAsked(),
      'location_permission_asked': await hasLocationPermissionBeenAsked(),
      'notification_permission_asked':
          await hasNotificationPermissionBeenAsked(),
      'first_launch': await isFirstLaunch(),
      'onboarding_completed': await isOnboardingCompleted(),
      'last_sync_time': await getLastSyncTime(),
      'last_location_check': await getLastLocationCheck(),
      'last_auto_checkin': await getLastAutoCheckIn(),
    };
  }

  /// Export settings for backup
  static Future<Map<String, dynamic>> exportSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    final settings = <String, dynamic>{};

    for (final key in allKeys) {
      final value = prefs.get(key);
      settings[key] = value;
    }

    return settings;
  }

  /// Import settings from backup
  static Future<bool> importSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      for (final entry in settings.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value is bool) {
          await prefs.setBool(key, value);
        } else if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is double) {
          await prefs.setDouble(key, value);
        } else if (value is String) {
          await prefs.setString(key, value);
        } else if (value is List<String>) {
          await prefs.setStringList(key, value);
        }
      }

      // Removed malformed log call
      return true;
    } catch (e) {
      // Removed malformed log call
      return false;
    }
  }

  /// Reset all settings to defaults
  static Future<void> resetAllSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await _setDefaultSettings();
      // Removed malformed log call
    } catch (e) {
      // Removed malformed log call
    }
  }

  /// Clean up old/unused settings keys
  static Future<void> cleanupOldSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();

      // List of old keys that might exist from previous versions
      const oldKeys = [
        'old_reminder_key',
        'deprecated_setting',
        'unused_preference',
        // Add any old keys here that need cleanup
      ];

      for (final oldKey in oldKeys) {
        if (allKeys.contains(oldKey)) {
          await prefs.remove(oldKey);
          // Removed malformed log call
        }
      }
    } catch (e) {
      // Removed malformed log call
    }
  }

  /// Validate settings integrity
  static Future<bool> validateSettings() async {
    try {
      final settings = await getAllSettings();

      // Validate reminder time
      final reminderTime = settings['reminder_time'] as TimeOfDay;
      if (reminderTime.hour < 0 ||
          reminderTime.hour > 23 ||
          reminderTime.minute < 0 ||
          reminderTime.minute > 59) {
        await setReminderTime(const TimeOfDay(hour: 10, minute: 0));
        // Removed malformed log call
      }

      // Validate theme mode
      final themeMode = settings['theme_mode'] as String;
      if (!['light', 'dark', 'system'].contains(themeMode)) {
        await setThemeMode('system');
        // Removed malformed log call
      }

      // Removed malformed log call
      return true;
    } catch (e) {
      // Removed malformed log call
      return false;
    }
  }

  /// Get settings summary for debugging
  static Future<String> getSettingsSummary() async {
    final settings = await getAllSettings();
    final buffer = StringBuffer();

    buffer.writeln('📱 OfficeLog Settings Summary');
    buffer.writeln('=' * 30);

    for (final entry in settings.entries) {
      buffer.writeln('${entry.key}: ${entry.value}');
    }

    return buffer.toString();
  }
}
