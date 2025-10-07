import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/attendance_service.dart';
import '../utils/working_days_calculator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/logger/app_logger.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _reminderTimeKey = 'reminder_time';
  static const String _reminderEnabledKey = 'reminder_enabled';
  static const String _complianceReminderEnabledKey =
      'compliance_reminder_enabled';
  static const int _dailyNotificationId = 1;
  static const int _complianceNotificationId = 2;

  // Initialize the notification service
  static Future<void> initialize() async {
    // Initialize timezone data
    tz.initializeTimeZones();

    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _notifications.initialize(initializationSettings);

    // Request permissions
    await requestPermissions();
  }

  // Request notification permissions
  static Future<bool> requestPermissions() async {
    try {
      // For Android 13+, request POST_NOTIFICATIONS permission
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        final granted = await androidImplementation
            .requestNotificationsPermission();
        return granted ?? true; // Default to true if we can't determine
      }

      return true; // Assume granted for older Android versions
    } catch (e) {
      AppLogger.error('Error occurred: $e', tag: 'NotificationService');
      return true; // Don't block the user if we can't request
    }
  }

  // Schedule daily reminder notification
  static Future<void> scheduleDailyReminder({
    int hour = 10,
    int minute = 0,
  }) async {
    try {
      // Save reminder time
      await _saveReminderTime(hour, minute);
      await _setReminderEnabled(true);

      // Cancel existing notification
      await _notifications.cancel(_dailyNotificationId);

      // Schedule new notification
      await _notifications.zonedSchedule(
        _dailyNotificationId,
        'Attendance Reminder',
        'Don\'t forget to log your attendance for today!',
        _nextInstanceOfTime(hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'attendance_reminder',
            'Attendance Reminders',
            channelDescription: 'Daily reminders to log attendance',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      AppLogger.error('Operation failed: $e', tag: 'NotificationService');
    }
  }

  // Cancel daily reminder
  static Future<void> cancelDailyReminder() async {
    try {
      await _notifications.cancel(_dailyNotificationId);
      await _setReminderEnabled(false);
    } catch (e) {
      AppLogger.error('Operation failed: $e', tag: 'NotificationService');
    }
  }

  // Check if reminder is enabled
  static Future<bool> isReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_reminderEnabledKey) ?? false;
  }

  // Get reminder time
  static Future<Map<String, int>> getReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'hour': prefs.getInt('${_reminderTimeKey}_hour') ?? 10,
      'minute': prefs.getInt('${_reminderTimeKey}_minute') ?? 0,
    };
  }

  // Update reminder time
  static Future<void> updateReminderTime(int hour, int minute) async {
    if (await isReminderEnabled()) {
      await scheduleDailyReminder(hour: hour, minute: minute);
    } else {
      await _saveReminderTime(hour, minute);
    }
  }

  // Show instant notification
  static Future<void> showNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    try {
      await _notifications.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'instant_notifications',
            'Instant Notifications',
            channelDescription: 'Immediate notifications for attendance events',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      AppLogger.error('Operation failed: $e', tag: 'NotificationService');
    }
  }

  // Show auto check-in success notification
  static Future<void> showAutoCheckInNotification({DateTime? date}) async {
    try {
      final now = date ?? DateTime.now();
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final monthStr = months[now.month - 1];
      final dateStr = '$monthStr ${now.day}';

      await _notifications.show(
        999, // Unique ID for auto check-in notifications
        '✅ Auto Check-in Successful',
        'OfficeLog: Attendance automatically logged for $dateStr, ${now.year} via geofence detection',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'auto_checkin',
            'Auto Check-in',
            channelDescription:
                'Notifications for automatic attendance check-in',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: Colors.blue, // Blue color for auto check-in
            ledColor: Colors.blue,
            ledOnMs: 1000,
            ledOffMs: 500,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      AppLogger.error('Operation failed: $e', tag: 'NotificationService');
    }
  }

  // Show auto check-in failure notification
  static Future<void> showAutoCheckInFailureNotification({
    DateTime? date,
    String? reason,
  }) async {
    try {
      final now = date ?? DateTime.now();
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final monthStr = months[now.month - 1];
      final dateStr = '$monthStr ${now.day}';
      final reasonText = reason ?? 'Location or network issue';

      await _notifications.show(
        998, // Unique ID for auto check-in failure notifications
        '⚠️ Auto Check-in Failed',
        'OfficeLog: Could not auto check-in for $dateStr, ${now.year}. Reason: $reasonText. Please check-in manually.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'auto_checkin_failed',
            'Auto Check-in Failed',
            channelDescription:
                'Notifications for failed automatic attendance check-in',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: Colors.red, // Red color for failures
            ledColor: Colors.red,
            ledOnMs: 1000,
            ledOffMs: 500,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      AppLogger.error('Operation failed: $e', tag: 'NotificationService');
    }
  }

  // Check if should suppress notification (already logged today)
  static Future<bool> shouldSuppressReminder() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return true;

      final today = DateTime.now();

      // Don't remind on non-working days
      if (!WorkingDaysCalculator.isWorkingDay(today)) {
        return true;
      }

      // Check if attendance is already logged
      final attendanceService = AttendanceService();
      final hasMarked = await attendanceService.hasMarkedAttendanceToday(
        user.uid,
      );

      return hasMarked;
    } catch (e) {
      return false; // If can't check, show reminder
    }
  }

  // Handle notification tap
  static void onNotificationTap(NotificationResponse response) {
    // Handle notification tap - could navigate to attendance screen
    // Removed malformed log call
  }

  // Private helper methods
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  static Future<void> _saveReminderTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${_reminderTimeKey}_hour', hour);
    await prefs.setInt('${_reminderTimeKey}_minute', minute);
  }

  static Future<void> _setReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reminderEnabledKey, enabled);
  }

  // Initialize and setup default reminder
  static Future<void> setupDefaultReminder() async {
    try {
      await initialize();

      // Check if reminder is already configured
      final isEnabled = await isReminderEnabled();
      if (!isEnabled) {
        // Setup default 10:00 AM reminder
        await scheduleDailyReminder(hour: 10, minute: 0);
      }
    } catch (e) {
      AppLogger.error('Operation failed: $e', tag: 'NotificationService');
    }
  }

  // Get all pending notifications (for debugging)
  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    await _setReminderEnabled(false);
  }

  // Compliance notification methods

  // Check and send compliance reminder if needed
  static Future<void> checkAndSendComplianceReminder() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Check if compliance reminders are enabled
      if (!await isComplianceReminderEnabled()) return;

      final today = DateTime.now();

      // Only check on working days
      if (!WorkingDaysCalculator.isWorkingDay(today)) return;

      // Get current month attendance data
      final attendanceService = AttendanceService();
      final attendedDates = await attendanceService.getMonthlyAttendance(
        user.uid,
        today.year,
        today.month,
      );

      // Calculate compliance
      final compliance = WorkingDaysCalculator.calculateCurrentMonthCompliance(
        attendedDates,
      );
      final stillNeeded = compliance['stillNeeded'] as int;
      final compliancePercent = compliance['compliance'] as double;

      // Send notification if compliance is below 60% and still need more days
      if (compliancePercent < 60 && stillNeeded > 0) {
        await _sendComplianceReminderNotification(stillNeeded);
      }
    } catch (e) {
      // Removed malformed log call
    }
  }

  // Send compliance reminder notification
  static Future<void> _sendComplianceReminderNotification(
    int stillNeeded,
  ) async {
    try {
      await _notifications.show(
        _complianceNotificationId,
        'Attendance Reminder',
        'You still need $stillNeeded more days this month to meet 60% attendance.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'compliance_reminder',
            'Compliance Reminders',
            channelDescription: 'Reminders when attendance compliance is low',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: Colors.orange,
            ledColor: Colors.orange,
            ledOnMs: 1000,
            ledOffMs: 500,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      // Removed malformed log call
    }
  }

  // Enable compliance reminders
  static Future<void> enableComplianceReminders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_complianceReminderEnabledKey, true);
  }

  // Disable compliance reminders
  static Future<void> disableComplianceReminders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_complianceReminderEnabledKey, false);
    await _notifications.cancel(_complianceNotificationId);
  }

  // Check if compliance reminders are enabled
  static Future<bool> isComplianceReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_complianceReminderEnabledKey) ??
        true; // Default to true
  }
}
