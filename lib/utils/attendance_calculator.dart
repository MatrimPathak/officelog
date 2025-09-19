import '../services/holiday_service.dart';
import '../models/holiday_model.dart';

/// Helper class for calculating dynamic attendance statistics
/// Based on the 3-day weekly rule: 3 days per complete week (Mon-Fri)
class AttendanceCalculator {
  static final HolidayService _holidayService = HolidayService();
  static List<HolidayModel>? _cachedHolidays;
  static DateTime? _lastHolidayFetch;
  static const Duration _holidayCacheDuration = Duration(hours: 1);

  /// Get holidays with caching to avoid repeated Firebase calls
  static Future<List<HolidayModel>> _getHolidays() async {
    final now = DateTime.now();

    // Check if cache is valid
    if (_cachedHolidays != null &&
        _lastHolidayFetch != null &&
        now.difference(_lastHolidayFetch!) < _holidayCacheDuration) {
      return _cachedHolidays!;
    }

    // Fetch fresh holidays
    _cachedHolidays = await _holidayService.getAllHolidays();
    _lastHolidayFetch = now;

    return _cachedHolidays!;
  }

  /// Calculate attendance statistics for a given month using provided holidays
  ///
  /// [year] - The year to calculate for
  /// [month] - The month to calculate for (1-12)
  /// [attendedDays] - List of dates the user attended
  /// [holidays] - List of holidays to exclude from working days
  ///
  /// Returns a map with:
  /// - requiredDays: Number of days required based on 3-day weekly rule
  /// - workingDays: Total working days in the month (Mon-Fri, excluding holidays)
  /// - attendedDays: Number of days actually attended
  /// - attendancePercentage: Percentage of required days attended
  /// - weeks: Number of complete weeks in the month
  /// - compliance: Compliance status (good/borderline/poor)
  /// - remainingDays: Days still needed to meet requirement
  static Map<String, dynamic> calculateAttendanceWithHolidays(
    int year,
    int month,
    List<DateTime> attendedDates,
    List<HolidayModel> holidays,
  ) {
    // Calculate complete weeks in the month
    final weeks = _getCompleteWeeksInMonth(year, month);

    // Required days = 3 days per complete week
    final requiredDays = weeks * 3;

    // Calculate total working days (Mon-Fri, excluding holidays)
    final workingDays = _getWorkingDaysInMonth(year, month, holidays);

    // Filter attended dates to current month and working days only
    final monthAttendedDays = _filterWorkingDaysFromList(
      attendedDates
          .where((date) => date.year == year && date.month == month)
          .toList(),
      holidays,
    );

    // Calculate attendance percentage
    final attendancePercentage = requiredDays > 0
        ? (monthAttendedDays / requiredDays) * 100
        : 0.0;

    // Calculate remaining days needed
    final remainingDays = (requiredDays - monthAttendedDays)
        .clamp(0, double.infinity)
        .toInt();

    // Determine compliance status
    String compliance;
    if (attendancePercentage >= 60) {
      compliance = 'good';
    } else if (attendancePercentage >= 55) {
      compliance = 'borderline';
    } else {
      compliance = 'poor';
    }

    return {
      'requiredDays': requiredDays,
      'workingDays': workingDays,
      'attendedDays': monthAttendedDays,
      'attendancePercentage': attendancePercentage,
      'weeks': weeks,
      'compliance': compliance,
      'remainingDays': remainingDays,
      'year': year,
      'month': month,
    };
  }

  /// Calculate attendance statistics for a given month (async version that fetches holidays)
  static Future<Map<String, dynamic>> calculateAttendance(
    int year,
    int month,
    List<DateTime> attendedDates,
  ) async {
    final holidays = await _getHolidays();
    return calculateAttendanceWithHolidays(
      year,
      month,
      attendedDates,
      holidays,
    );
  }

  /// Calculate attendance for current month
  static Future<Map<String, dynamic>> calculateCurrentMonthAttendance(
    List<DateTime> attendedDates,
  ) async {
    final now = DateTime.now();
    return await calculateAttendance(now.year, now.month, attendedDates);
  }

  /// Calculate attendance for a specific quarter
  static Future<Map<String, dynamic>> calculateQuarterAttendance(
    int year,
    int quarter,
    List<DateTime> attendedDates,
  ) async {
    final months = _getQuarterMonths(quarter);
    int totalRequiredDays = 0;
    int totalWorkingDays = 0;
    int totalAttendedDays = 0;
    int totalWeeks = 0;

    for (int month = months['start']!; month <= months['end']!; month++) {
      final monthData = await calculateAttendance(year, month, attendedDates);
      totalRequiredDays += monthData['requiredDays'] as int;
      totalWorkingDays += monthData['workingDays'] as int;
      totalAttendedDays += monthData['attendedDays'] as int;
      totalWeeks += monthData['weeks'] as int;
    }

    final attendancePercentage = totalRequiredDays > 0
        ? (totalAttendedDays / totalRequiredDays) * 100
        : 0.0;

    String compliance;
    if (attendancePercentage >= 60) {
      compliance = 'good';
    } else if (attendancePercentage >= 55) {
      compliance = 'borderline';
    } else {
      compliance = 'poor';
    }

    return {
      'requiredDays': totalRequiredDays,
      'workingDays': totalWorkingDays,
      'attendedDays': totalAttendedDays,
      'attendancePercentage': attendancePercentage,
      'weeks': totalWeeks,
      'compliance': compliance,
      'quarter': quarter,
      'year': year,
    };
  }

  /// Calculate yearly attendance summary
  static Future<Map<String, dynamic>> calculateYearlyAttendance(
    int year,
    List<DateTime> attendedDates,
  ) async {
    int totalRequiredDays = 0;
    int totalWorkingDays = 0;
    int totalAttendedDays = 0;
    int totalWeeks = 0;

    for (int month = 1; month <= 12; month++) {
      final monthData = await calculateAttendance(year, month, attendedDates);
      totalRequiredDays += monthData['requiredDays'] as int;
      totalWorkingDays += monthData['workingDays'] as int;
      totalAttendedDays += monthData['attendedDays'] as int;
      totalWeeks += monthData['weeks'] as int;
    }

    final attendancePercentage = totalRequiredDays > 0
        ? (totalAttendedDays / totalRequiredDays) * 100
        : 0.0;

    String compliance;
    if (attendancePercentage >= 60) {
      compliance = 'good';
    } else if (attendancePercentage >= 55) {
      compliance = 'borderline';
    } else {
      compliance = 'poor';
    }

    return {
      'requiredDays': totalRequiredDays,
      'workingDays': totalWorkingDays,
      'attendedDays': totalAttendedDays,
      'attendancePercentage': attendancePercentage,
      'weeks': totalWeeks,
      'compliance': compliance,
      'year': year,
    };
  }

  // Private helper methods

  /// Get number of complete weeks (Mon-Fri) in a month
  static int _getCompleteWeeksInMonth(int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);

    // Find the first Monday of the month (or the Monday of the week containing the first day)
    DateTime firstMonday = firstDay;
    while (firstMonday.weekday != DateTime.monday) {
      firstMonday = firstMonday.add(const Duration(days: 1));
      // If we go past the month while looking for first Monday, no complete weeks
      if (firstMonday.month != month) {
        return 0;
      }
    }

    // Count complete weeks (Monday to Friday only)
    int completeWeeks = 0;
    DateTime currentWeekStart = firstMonday;

    while (currentWeekStart.month == month && currentWeekStart.year == year) {
      // Check if the entire work week (Monday to Friday) falls within the month
      final weekEnd = currentWeekStart.add(const Duration(days: 4)); // Friday

      if (weekEnd.month == month &&
          weekEnd.year == year &&
          weekEnd.day <= lastDay.day) {
        completeWeeks++;
        currentWeekStart = currentWeekStart.add(const Duration(days: 7));
      } else {
        break; // Week extends beyond the month
      }
    }

    return completeWeeks;
  }

  /// Get total working days (Mon-Fri, excluding holidays) in a month
  static int _getWorkingDaysInMonth(
    int year,
    int month,
    List<HolidayModel> holidays,
  ) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    int workingDays = 0;

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      if (_isWorkingDay(date, holidays)) {
        workingDays++;
      }
    }

    return workingDays;
  }

  /// Filter a list of dates to only include working days
  static int _filterWorkingDaysFromList(
    List<DateTime> dates,
    List<HolidayModel> holidays,
  ) {
    if (dates.isEmpty) return 0;

    int workingDayCount = 0;

    for (final date in dates) {
      if (_isWorkingDay(date, holidays)) {
        workingDayCount++;
      }
    }

    return workingDayCount;
  }

  /// Check if a date is a working day (Mon-Fri, excluding holidays)
  static bool _isWorkingDay(DateTime date, List<HolidayModel> holidays) {
    if (_isWeekend(date)) return false;

    // Check if date matches any holiday
    return !holidays.any((holiday) => holiday.matchesDate(date));
  }

  /// Check if a date is a weekend
  static bool _isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  /// Get start and end months for a quarter
  static Map<String, int> _getQuarterMonths(int quarter) {
    switch (quarter) {
      case 1:
        return {'start': 1, 'end': 3};
      case 2:
        return {'start': 4, 'end': 6};
      case 3:
        return {'start': 7, 'end': 9};
      case 4:
        return {'start': 10, 'end': 12};
      default:
        return {'start': 1, 'end': 3};
    }
  }

  /// Get month name from month number
  static String getMonthName(int month) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return monthNames[month - 1];
  }

  /// Get short month name from month number
  static String getShortMonthName(int month) {
    const monthNames = [
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
    return monthNames[month - 1];
  }
}
