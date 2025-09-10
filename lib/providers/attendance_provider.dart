import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/attendance_service.dart';
import '../services/cache_service.dart';
import '../services/holiday_service.dart';
import '../services/geolocation_service.dart';
import '../services/notification_service.dart';
import '../utils/working_days_calculator.dart';
import '../models/attendance_model.dart';

class AttendanceProvider with ChangeNotifier {
  final AttendanceService _attendanceService = AttendanceService();
  final HolidayService _holidayService = HolidayService();
  final GeolocationService _geolocationService = GeolocationService();

  List<DateTime> _attendedDates = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasMarkedToday = false;
  DateTime? _selectedDate;

  List<DateTime> get attendedDates => _attendedDates;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMarkedToday => _hasMarkedToday;
  DateTime? get selectedDate => _selectedDate;

  // Calculate attendance stats for current month (working days only)
  Map<String, dynamic> get currentMonthStats {
    final now = DateTime.now();
    final totalWorkingDays = WorkingDaysCalculator.getWorkingDaysInMonth(
      now.year,
      now.month,
    );
    final attendedWorkingDays = _attendedDates
        .where(
          (date) =>
              date.year == now.year &&
              date.month == now.month &&
              WorkingDaysCalculator.isWorkingDay(date),
        )
        .length;
    final percentage = totalWorkingDays > 0
        ? (attendedWorkingDays / totalWorkingDays) * 100
        : 0.0;

    return {
      'attendedDays': attendedWorkingDays,
      'totalDays': totalWorkingDays,
      'percentage': percentage,
    };
  }

  // Calculate attendance stats for a specific month (working days only)
  Map<String, dynamic> getMonthStats(int year, int month) {
    final totalWorkingDays = WorkingDaysCalculator.getWorkingDaysInMonth(
      year,
      month,
    );
    final attendedWorkingDays = _attendedDates
        .where(
          (date) =>
              date.year == year &&
              date.month == month &&
              WorkingDaysCalculator.isWorkingDay(date),
        )
        .length;
    final percentage = totalWorkingDays > 0
        ? (attendedWorkingDays / totalWorkingDays) * 100
        : 0.0;

    // Calculate 60% target information
    final targetInfo = _calculate60PercentTarget(
      year,
      month,
      attendedWorkingDays,
    );

    return {
      'attendedDays': attendedWorkingDays,
      'totalDays': totalWorkingDays,
      'percentage': percentage,
      'year': year,
      'month': month,
      'targetInfo': targetInfo,
    };
  }

  // Calculate attendance stats for current quarter
  Map<String, dynamic> get currentQuarterStats {
    final now = DateTime.now();
    return getQuarterStats(
      now.year,
      WorkingDaysCalculator.getQuarter(now.month),
    );
  }

  // Calculate attendance stats for a specific quarter
  Map<String, dynamic> getQuarterStats(int year, int quarter) {
    final months = WorkingDaysCalculator.getQuarterMonths(quarter);
    int totalWorkingDays = 0;
    int attendedWorkingDays = 0;

    // Calculate for each month in the quarter
    for (int month = months['start']!; month <= months['end']!; month++) {
      totalWorkingDays += WorkingDaysCalculator.getWorkingDaysInMonth(
        year,
        month,
      );

      final monthAttendedDays = _attendedDates
          .where(
            (date) =>
                date.year == year &&
                date.month == month &&
                WorkingDaysCalculator.isWorkingDay(date),
          )
          .length;

      attendedWorkingDays += monthAttendedDays;
    }

    final percentage = totalWorkingDays > 0
        ? (attendedWorkingDays / totalWorkingDays) * 100
        : 0.0;

    // Calculate 60% target information for the quarter
    final targetInfo = _calculateQuarterly60PercentTarget(
      year,
      quarter,
      attendedWorkingDays,
    );

    return {
      'attendedDays': attendedWorkingDays,
      'totalDays': totalWorkingDays,
      'percentage': percentage,
      'year': year,
      'quarter': quarter,
      'quarterName': WorkingDaysCalculator.getQuarterNameWithRange(quarter),
      'targetInfo': targetInfo,
    };
  }

  // Calculate 60% target information
  Map<String, dynamic> _calculate60PercentTarget(
    int year,
    int month,
    int attendedDays,
  ) {
    final now = DateTime.now();

    // Only calculate for current month or future months
    final isCurrentMonth = year == now.year && month == now.month;
    final isFutureMonth =
        year > now.year || (year == now.year && month > now.month);

    if (!isCurrentMonth && !isFutureMonth) {
      // For past months, just show if target was met
      final totalWorkingDays = WorkingDaysCalculator.getWorkingDaysInMonth(
        year,
        month,
      );
      final targetDays = (0.6 * totalWorkingDays).ceil();
      return {
        'status': attendedDays >= targetDays ? 'met' : 'missed',
        'message': attendedDays >= targetDays
            ? '✅ Target met'
            : '❌ Target missed',
        'color': attendedDays >= targetDays ? 'green' : 'red',
        'daysNeeded': 0,
        'targetDays': targetDays,
      };
    }

    // For current month: A = Days Attended, W = Working Days so far, R = Remaining Working Days
    final totalWorkingDays = WorkingDaysCalculator.getWorkingDaysInMonth(
      year,
      month,
    );
    final remainingWorkingDays = isCurrentMonth
        ? WorkingDaysCalculator.getRemainingWorkingDaysInMonth(now)
        : totalWorkingDays;

    // Calculate X = ceil(0.6 × (W + R) - A)
    final targetTotalDays = (0.6 * totalWorkingDays).ceil();
    final daysNeeded = (targetTotalDays - attendedDays)
        .clamp(0, double.infinity)
        .toInt();

    if (daysNeeded <= 0) {
      return {
        'status': 'met',
        'message': '✅ Target met',
        'color': 'green',
        'daysNeeded': 0,
        'targetDays': targetTotalDays,
      };
    }

    if (daysNeeded > remainingWorkingDays) {
      return {
        'status': 'not_achievable',
        'message': '❌ Not achievable this month',
        'color': 'red',
        'daysNeeded': daysNeeded,
        'targetDays': targetTotalDays,
        'remainingDays': remainingWorkingDays,
      };
    }

    return {
      'status': 'achievable',
      'message': 'Required for 60%: $daysNeeded more days',
      'color': 'yellow',
      'daysNeeded': daysNeeded,
      'targetDays': targetTotalDays,
      'remainingDays': remainingWorkingDays,
    };
  }

  // Calculate 60% target information for quarterly attendance
  Map<String, dynamic> _calculateQuarterly60PercentTarget(
    int year,
    int quarter,
    int attendedDays,
  ) {
    final now = DateTime.now();
    final currentQuarter = WorkingDaysCalculator.getQuarter(now.month);
    final isCurrentQuarter = year == now.year && quarter == currentQuarter;
    final isFutureQuarter =
        year > now.year || (year == now.year && quarter > currentQuarter);

    if (!isCurrentQuarter && !isFutureQuarter) {
      // For past quarters, just show if target was met
      final totalWorkingDays = WorkingDaysCalculator.getWorkingDaysInQuarter(
        year,
        quarter,
      );
      final targetDays = (0.6 * totalWorkingDays).ceil();
      return {
        'status': attendedDays >= targetDays ? 'met' : 'missed',
        'message': attendedDays >= targetDays
            ? '✅ Target met'
            : '❌ Target missed',
        'color': attendedDays >= targetDays ? 'green' : 'red',
        'daysNeeded': 0,
        'targetDays': targetDays,
      };
    }

    // For current quarter: calculate based on working days up to now
    final totalWorkingDays = WorkingDaysCalculator.getWorkingDaysInQuarter(
      year,
      quarter,
    );
    final remainingWorkingDays = isCurrentQuarter
        ? WorkingDaysCalculator.getRemainingWorkingDaysInQuarter(now)
        : totalWorkingDays;

    // Calculate X = ceil(0.6 × TotalWorkingDays - AttendedDays)
    final targetTotalDays = (0.6 * totalWorkingDays).ceil();
    final daysNeeded = (targetTotalDays - attendedDays)
        .clamp(0, double.infinity)
        .toInt();

    if (daysNeeded <= 0) {
      return {
        'status': 'met',
        'message': '✅ Target met',
        'color': 'green',
        'daysNeeded': 0,
        'targetDays': targetTotalDays,
      };
    }

    if (daysNeeded > remainingWorkingDays) {
      return {
        'status': 'not_achievable',
        'message': '❌ Not achievable this quarter',
        'color': 'red',
        'daysNeeded': daysNeeded,
        'targetDays': targetTotalDays,
        'remainingDays': remainingWorkingDays,
      };
    }

    return {
      'status': 'achievable',
      'message': '🎯 Need $daysNeeded more days',
      'color': 'orange',
      'daysNeeded': daysNeeded,
      'targetDays': targetTotalDays,
      'remainingDays': remainingWorkingDays,
    };
  }

  // Load attendance for current month
  Future<void> loadCurrentMonthAttendance() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _setLoading(true);
    _clearError();

    try {
      final now = DateTime.now();
      _attendedDates = await _attendanceService.getMonthlyAttendance(
        user.uid,
        now.year,
        now.month,
      );

      // Check if user has marked attendance today
      _hasMarkedToday = await _attendanceService.hasMarkedAttendanceToday(
        user.uid,
      );

      notifyListeners();
    } catch (e) {
      _setError('Failed to load attendance: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Mark attendance for today
  Future<bool> markAttendance() async {
    return await markAttendanceForDate(DateTime.now());
  }

  // Mark attendance for a specific date
  Future<bool> markAttendanceForDate(DateTime date) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    _setLoading(true);
    _clearError();

    try {
      await _attendanceService.markAttendanceForDate(user.uid, date);

      // Update local state
      if (!_attendedDates.any(
        (attendedDate) =>
            attendedDate.year == date.year &&
            attendedDate.month == date.month &&
            attendedDate.day == date.day,
      )) {
        _attendedDates.add(date);
      }

      // Update today's status if marking today
      if (date.year == DateTime.now().year &&
          date.month == DateTime.now().month &&
          date.day == DateTime.now().day) {
        _hasMarkedToday = true;
      }

      // Cache the updated data with sync to both local and Firestore
      await CacheService.cacheAttendanceWithSync(
        user.uid,
        date.year,
        date.month,
        _attendedDates
            .where(
              (attendedDate) =>
                  attendedDate.year == date.year &&
                  attendedDate.month == date.month,
            )
            .toList(),
      );

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to mark attendance: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete attendance for a specific date
  Future<bool> deleteAttendanceForDate(DateTime date) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    _setLoading(true);
    _clearError();

    try {
      await _attendanceService.deleteAttendanceForDate(user.uid, date);

      // Update local state - remove the date from attended dates
      _attendedDates.removeWhere(
        (attendedDate) =>
            attendedDate.year == date.year &&
            attendedDate.month == date.month &&
            attendedDate.day == date.day,
      );

      // Update today's status if deleting today
      if (date.year == DateTime.now().year &&
          date.month == DateTime.now().month &&
          date.day == DateTime.now().day) {
        _hasMarkedToday = false;
      }

      // Delete from cache with sync to both local and Firestore
      await CacheService.deleteAttendanceWithSync(
        user.uid,
        date.year,
        date.month,
        date,
      );

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete attendance: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Load attendance for a specific month with enhanced caching and offline support
  Future<void> loadMonthAttendance(int year, int month) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _setLoading(true);
    _clearError();

    try {
      // Try to get data with offline support
      _attendedDates = await _attendanceService.getMonthlyAttendanceWithOffline(
        user.uid,
        year,
        month,
      );

      _updateTodayStatus();
      notifyListeners();
      _setLoading(false);

      // Try to sync any offline data in the background
      _syncOfflineDataInBackground(user.uid);
    } catch (e) {
      // If online fails, try to get cached data
      try {
        List<DateTime>? attendanceData =
            await CacheService.getAttendanceWithFallback(user.uid, year, month);

        if (attendanceData != null) {
          _attendedDates = attendanceData;
          _updateTodayStatus();
          notifyListeners();
        } else {
          _setError('Failed to load attendance: $e');
        }
      } catch (cacheError) {
        _setError('Failed to load attendance: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Update today's status
  void _updateTodayStatus() {
    final today = DateTime.now();
    _hasMarkedToday = _attendedDates.any(
      (date) =>
          date.year == today.year &&
          date.month == today.month &&
          date.day == today.day,
    );
  }

  // Load attendance for a specific month (returns list)
  Future<List<DateTime>> loadMonthAttendanceList(int year, int month) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      return await _attendanceService.getMonthlyAttendance(
        user.uid,
        year,
        month,
      );
    } catch (e) {
      _setError('Failed to load month attendance: $e');
      return [];
    }
  }

  // Get yearly summary
  Future<Map<String, int>> getYearlySummary(int year) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    try {
      return await _attendanceService.getYearlySummary(user.uid, year);
    } catch (e) {
      _setError('Failed to get yearly summary: $e');
      return {};
    }
  }

  // Get detailed monthly data for a year
  Future<List<Map<String, dynamic>>> getYearlyDetails(int year) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      return await _attendanceService.getYearlyDetails(user.uid, year);
    } catch (e) {
      _setError('Failed to get yearly details: $e');
      return [];
    }
  }

  // Check if a specific date is marked as attended
  bool isDateAttended(DateTime date) {
    return _attendedDates.any(
      (attendedDate) =>
          attendedDate.year == date.year &&
          attendedDate.month == date.month &&
          attendedDate.day == date.day,
    );
  }

  // Select a date
  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  // Clear selected date
  void clearSelectedDate() {
    _selectedDate = null;
    notifyListeners();
  }

  // Check if a date is selected
  bool isDateSelected(DateTime date) {
    return _selectedDate != null &&
        _selectedDate!.year == date.year &&
        _selectedDate!.month == date.month &&
        _selectedDate!.day == date.day;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Reset provider state when user logs out/switches accounts
  void resetUserData() {
    _attendedDates.clear();
    _hasMarkedToday = false;
    _selectedDate = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  // Sync offline data when app starts
  Future<void> syncOfflineDataOnStart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Check if there's offline data to sync
      if (await CacheService.hasOfflineData(user.uid)) {
        await CacheService.syncOfflineData(user.uid);
      }

      // Sync attendance service offline data
      if (await _attendanceService.hasOfflineData(user.uid)) {
        await _attendanceService.syncOfflineAttendance(user.uid);
      }

      // Force sync all cached data to Firestore
      await CacheService.forceSyncToFirestore(user.uid);

      // Reload current month after sync
      await loadCurrentMonthAttendance();
    } catch (e) {
      print('Failed to sync offline data on start: $e');
    }
  }

  // Background sync for offline data
  Future<void> _syncOfflineDataInBackground(String userId) async {
    try {
      if (await _attendanceService.hasOfflineData(userId)) {
        await _attendanceService.syncOfflineAttendance(userId);
        // Reload data after successful sync
        final now = DateTime.now();
        await loadMonthAttendance(now.year, now.month);
      }
    } catch (e) {
      // Silent fail for background sync
      print('Background sync failed: $e');
    }
  }

  // Check if a date has unsynced offline attendance
  Future<bool> hasUnsyncedAttendance(DateTime date) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      return await _attendanceService.hasUnsyncedAttendance(user.uid, date);
    } catch (e) {
      return false;
    }
  }

  // Get attendance details for a specific date
  Future<AttendanceModel?> getAttendanceDetails(DateTime date) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      return await _attendanceService.getAttendanceForDate(user.uid, date);
    } catch (e) {
      return null;
    }
  }

  // Check if a date is a holiday
  Future<bool> isHoliday(DateTime date) async {
    try {
      return await _holidayService.isHoliday(date);
    } catch (e) {
      return false;
    }
  }

  // Get holiday for a specific date
  Future<String?> getHolidayName(DateTime date) async {
    try {
      final holiday = await _holidayService.getHolidayForDate(date);
      return holiday?.name;
    } catch (e) {
      return null;
    }
  }

  // Try automatic check-in if conditions are met
  Future<bool> tryAutoCheckIn() async {
    try {
      return await _geolocationService.performAutoCheckIn();
    } catch (e) {
      print('Auto check-in failed: $e');
      return false;
    }
  }

  // Get distance to office
  Future<double?> getDistanceToOffice() async {
    try {
      return await _geolocationService.getDistanceToOffice();
    } catch (e) {
      return null;
    }
  }

  // Check if within office geofence
  Future<bool> isWithinOfficeGeofence() async {
    try {
      return await _geolocationService.isWithinOfficeGeofence();
    } catch (e) {
      return false;
    }
  }

  // Setup notifications
  Future<void> setupNotifications() async {
    try {
      await NotificationService.setupDefaultReminder();
    } catch (e) {
      print('Failed to setup notifications: $e');
    }
  }

  // Initialize all services
  Future<void> initializeServices() async {
    try {
      // Initialize notifications
      await NotificationService.initialize();

      // Setup default reminder if not configured
      if (!await NotificationService.isReminderEnabled()) {
        await NotificationService.scheduleDailyReminder();
      }

      // Initialize geofence monitoring
      await _geolocationService.startGeofenceMonitoring();

      // Sync offline data
      await syncOfflineDataOnStart();
    } catch (e) {
      print('Failed to initialize services: $e');
    }
  }

  // Get offline attendance count
  Future<int> getOfflineAttendanceCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;

    try {
      final offlineAttendance = await _attendanceService.getOfflineAttendance(
        user.uid,
      );
      return offlineAttendance.length;
    } catch (e) {
      return 0;
    }
  }

  // Force sync offline data
  Future<bool> forceSyncOfflineData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    _setLoading(true);
    _clearError();

    try {
      await _attendanceService.syncOfflineAttendance(user.uid);
      await loadCurrentMonthAttendance();
      return true;
    } catch (e) {
      _setError('Failed to sync offline data: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
