class WorkingDaysCalculator {
  // Holiday names map - this is the single source of truth for holidays
  static const Map<String, String> holidayNames = {
    '1-1': 'New Year\'s Day',
    '1-26': 'Republic Day',
    '3-8': 'Holi',
    '4-14': 'Ambedkar Jayanti',
    '4-17': 'Ram Navami',
    '5-1': 'Labour Day',
    '8-15': 'Independence Day',
    '8-27': 'Ganesh Chaturthi',
    '8-29': 'Wellness Day at Pega',
    '10-2': 'Gandhi Jayanti',
    '10-12': 'Dussehra',
    '11-1': 'Diwali',
    '11-15': 'Guru Nanak Jayanti',
    '12-25': 'Christmas',
  };

  // Check if a date is a weekend
  static bool isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  // Check if a date is a holiday based on the names map
  static bool isHoliday(DateTime date) {
    final monthDayKey = '${date.month}-${date.day}';
    return holidayNames.containsKey(monthDayKey);
  }

  // Check if a date is a working day
  static bool isWorkingDay(DateTime date) {
    return !isWeekend(date) && !isHoliday(date);
  }

  // Get total working days in a month
  static int getWorkingDaysInMonth(int year, int month) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    int workingDays = 0;

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      if (isWorkingDay(date)) {
        workingDays++;
      }
    }

    return workingDays;
  }

  // Get working days in a date range
  static int getWorkingDaysInRange(DateTime startDate, DateTime endDate) {
    int workingDays = 0;
    DateTime currentDate = startDate;

    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      if (isWorkingDay(currentDate)) {
        workingDays++;
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return workingDays;
  }

  // Get working days from start of month to a specific date
  static int getWorkingDaysUpToDate(DateTime date) {
    final startOfMonth = DateTime(date.year, date.month, 1);
    return getWorkingDaysInRange(startOfMonth, date);
  }

  // Get list of working days in a month
  static List<DateTime> getWorkingDaysList(int year, int month) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    List<DateTime> workingDays = [];

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      if (isWorkingDay(date)) {
        workingDays.add(date);
      }
    }

    return workingDays;
  }

  // Get holiday name for a specific date
  static String? getHolidayName(DateTime date) {
    final monthDayKey = '${date.month}-${date.day}';
    return holidayNames[monthDayKey];
  }

  // Get weekend name
  static String getWeekendName(DateTime date) {
    switch (date.weekday) {
      case DateTime.saturday:
        return 'Weekend – Saturday';
      case DateTime.sunday:
        return 'Weekend – Sunday';
      default:
        return 'Weekend';
    }
  }

  // Get non-working day reason
  static String? getNonWorkingDayReason(DateTime date) {
    if (isWeekend(date)) {
      return getWeekendName(date);
    } else if (isHoliday(date)) {
      return 'Holiday – ${getHolidayName(date)}';
    }
    return null;
  }

  // Get remaining working days from a specific date to end of month
  static int getRemainingWorkingDaysInMonth(DateTime fromDate) {
    final endOfMonth = DateTime(fromDate.year, fromDate.month + 1, 0);

    // If fromDate is beyond the end of month, return 0
    if (fromDate.isAfter(endOfMonth)) {
      return 0;
    }

    // Start from the day after fromDate
    final startDate = fromDate.add(const Duration(days: 1));
    return getWorkingDaysInRange(startDate, endOfMonth);
  }

  // Get working days from start of month up to (but not including) a specific date
  static int getWorkingDaysBeforeDate(DateTime date) {
    final startOfMonth = DateTime(date.year, date.month, 1);
    final dayBefore = date.subtract(const Duration(days: 1));

    // If date is at or before start of month, return 0
    if (date.isBefore(startOfMonth) || date.isAtSameMomentAs(startOfMonth)) {
      return 0;
    }

    return getWorkingDaysInRange(startOfMonth, dayBefore);
  }

  // Get quarter number (1-4) for a given month
  static int getQuarter(int month) {
    if (month >= 1 && month <= 3) return 1;
    if (month >= 4 && month <= 6) return 2;
    if (month >= 7 && month <= 9) return 3;
    if (month >= 10 && month <= 12) return 4;
    return 1; // Default fallback
  }

  // Get quarter name (Q1, Q2, Q3, Q4)
  static String getQuarterName(int quarter) {
    return 'Q$quarter';
  }

  // Get quarter name with month range (Q1 (Jan–Mar), Q2 (Apr–Jun), etc.)
  static String getQuarterNameWithRange(int quarter) {
    switch (quarter) {
      case 1:
        return 'Q1 (Jan–Mar)';
      case 2:
        return 'Q2 (Apr–Jun)';
      case 3:
        return 'Q3 (Jul–Sep)';
      case 4:
        return 'Q4 (Oct–Dec)';
      default:
        return 'Q$quarter';
    }
  }

  // Get start and end months for a quarter
  static Map<String, int> getQuarterMonths(int quarter) {
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

  // Get total working days in a quarter
  static int getWorkingDaysInQuarter(int year, int quarter) {
    final months = getQuarterMonths(quarter);
    int totalWorkingDays = 0;

    for (int month = months['start']!; month <= months['end']!; month++) {
      totalWorkingDays += getWorkingDaysInMonth(year, month);
    }

    return totalWorkingDays;
  }

  // Get working days in a quarter up to a specific date
  static int getWorkingDaysInQuarterUpToDate(DateTime date) {
    final quarter = getQuarter(date.month);
    final months = getQuarterMonths(quarter);
    int totalWorkingDays = 0;

    for (int month = months['start']!; month <= months['end']!; month++) {
      if (month < date.month) {
        // Full month
        totalWorkingDays += getWorkingDaysInMonth(date.year, month);
      } else if (month == date.month) {
        // Partial month up to the given date
        totalWorkingDays += getWorkingDaysUpToDate(date);
      }
      // Skip future months
    }

    return totalWorkingDays;
  }

  // Get remaining working days in a quarter from a specific date
  static int getRemainingWorkingDaysInQuarter(DateTime fromDate) {
    final quarter = getQuarter(fromDate.month);
    final months = getQuarterMonths(quarter);
    int remainingWorkingDays = 0;

    for (int month = months['start']!; month <= months['end']!; month++) {
      if (month > fromDate.month) {
        // Future months - count all working days
        remainingWorkingDays += getWorkingDaysInMonth(fromDate.year, month);
      } else if (month == fromDate.month) {
        // Current month - count remaining days
        remainingWorkingDays += getRemainingWorkingDaysInMonth(fromDate);
      }
      // Skip past months
    }

    return remainingWorkingDays;
  }
}
