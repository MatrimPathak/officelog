import 'package:flutter/foundation.dart';
import '../models/holiday_model.dart';
import '../services/holiday_service.dart';
import '../core/logger/app_logger.dart';

class HolidayProvider with ChangeNotifier {
  final HolidayService _holidayService = HolidayService();

  List<HolidayModel> _holidays = [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastUpdated = DateTime.now();

  List<HolidayModel> get holidays => _holidays;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastUpdated => _lastUpdated;

  // Get holidays for a specific month
  List<HolidayModel> getHolidaysForMonth(int year, int month) {
    return _holidays.where((holiday) {
      final holidayDate = holiday.toDateTime();

      // Check year and month
      return holidayDate.year == year && holidayDate.month == month;
    }).toList();
  }

  // Check if a specific date is a holiday
  bool isHoliday(DateTime date) {
    return _holidays.any((holiday) => holiday.matchesDate(date));
  }

  // Get holiday for a specific date
  HolidayModel? getHolidayForDate(DateTime date) {
    try {
      return _holidays.firstWhere((holiday) => holiday.matchesDate(date));
    } catch (e) {
      return null;
    }
  }

  // Load all holidays
  Future<void> loadHolidays() async {
    _setLoading(true);
    _clearError();

    try {
      _holidays = await _holidayService.getAllHolidays();
      _lastUpdated = DateTime.now();

      notifyListeners();
    } catch (e) {
      _setError('Failed to load holidays: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load holidays for a specific month
  Future<void> loadHolidaysForMonth(int year, int month) async {
    _setLoading(true);
    _clearError();

    try {
      final monthHolidays = await _holidayService.getHolidaysForMonth(
        year,
        month,
      );

      // Update the main holidays list with new data
      for (final holiday in monthHolidays) {
        final existingIndex = _holidays.indexWhere((h) => h.id == holiday.id);
        if (existingIndex >= 0) {
          _holidays[existingIndex] = holiday;
        } else {
          _holidays.add(holiday);
        }
      }

      _lastUpdated = DateTime.now();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load holidays for month: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Refresh holidays from server
  Future<void> refreshHolidays() async {
    _setLoading(true);
    _clearError();

    try {
      _holidays = await _holidayService.refreshHolidays();
      _lastUpdated = DateTime.now();
      notifyListeners();
    } catch (e) {
      _setError('Failed to refresh holidays: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Add a new holiday (admin function)
  Future<bool> addHoliday(HolidayModel holiday) async {
    _setLoading(true);
    _clearError();

    try {
      await _holidayService.addHoliday(holiday);
      _holidays.add(holiday);
      _lastUpdated = DateTime.now();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add holiday: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update a holiday (admin function)
  Future<bool> updateHoliday(HolidayModel holiday) async {
    _setLoading(true);
    _clearError();

    try {
      await _holidayService.updateHoliday(holiday);

      final index = _holidays.indexWhere((h) => h.id == holiday.id);
      if (index >= 0) {
        _holidays[index] = holiday;
      }

      _lastUpdated = DateTime.now();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update holiday: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete a holiday (admin function)
  Future<bool> deleteHoliday(String holidayId) async {
    _setLoading(true);
    _clearError();

    try {
      await _holidayService.deleteHoliday(holidayId);
      _holidays.removeWhere((h) => h.id == holidayId);
      _lastUpdated = DateTime.now();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete holiday: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Check if holidays need to be loaded for a month
  bool needsHolidaysForMonth(int year, int month) {
    final monthHolidays = getHolidaysForMonth(year, month);

    // If we have no holidays for this month and it's been more than an hour
    // since last update, we should refresh
    if (monthHolidays.isEmpty) {
      final hoursSinceUpdate = DateTime.now()
          .difference(_lastUpdated ?? DateTime.now())
          .inHours;
      return hoursSinceUpdate > 1;
    }

    return false;
  }

  // Initialize holidays (call this on app start)
  Future<void> initializeHolidays() async {
    try {
      await _holidayService.initializeDefaultHolidays();
      await loadHolidays();
    } catch (e) {
      AppLogger.error('Operation failed: $e', tag: 'HolidayProvider');
    }
  }

  // Get holiday statistics
  Map<String, dynamic> getHolidayStats() {
    final now = DateTime.now();
    final thisYear = now.year;
    final thisMonth = now.month;

    final thisYearHolidays = _holidays.where((holiday) {
      final holidayDate = holiday.toDateTime();
      return holidayDate.year == thisYear;
    }).toList();

    final thisMonthHolidays = getHolidaysForMonth(thisYear, thisMonth);

    final upcomingHolidays = thisYearHolidays.where((holiday) {
      final holidayDate = holiday.toDateTime();
      return holidayDate.isAfter(now);
    }).toList();

    upcomingHolidays.sort((a, b) {
      final aDate = a.toDateTime();
      final bDate = b.toDateTime();
      return aDate.compareTo(bDate);
    });

    return {
      'totalHolidays': _holidays.length,
      'thisYearHolidays': thisYearHolidays.length,
      'thisMonthHolidays': thisMonthHolidays.length,
      'upcomingHolidays': upcomingHolidays.take(3).toList(),
      'nextHoliday': upcomingHolidays.isNotEmpty
          ? upcomingHolidays.first
          : null,
    };
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
    _holidays.clear();
    _lastUpdated = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
