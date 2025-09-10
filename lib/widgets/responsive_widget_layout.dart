import 'package:flutter/material.dart';

/// Responsive widget layout helper for determining widget sizes
class ResponsiveWidgetLayout {
  /// Widget size breakpoints based on typical home screen widget dimensions
  static const double xsMaxWidth = 150;
  static const double smallMaxWidth = 300;
  static const double mediumMaxWidth = 400;

  static const double xsMaxHeight = 150;
  static const double smallMaxHeight = 150;
  static const double mediumMaxHeight = 300;

  /// Determine widget layout type based on available space
  static WidgetLayoutType getLayoutType(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;

    // Extra Small: Minimal space, show only percentage
    if (width <= xsMaxWidth && height <= xsMaxHeight) {
      return WidgetLayoutType.extraSmall;
    }

    // Small: Horizontal rectangle, show stats with progress
    if (width <= smallMaxWidth && height <= smallMaxHeight) {
      return WidgetLayoutType.small;
    }

    // Medium: Square or small rectangle, show stats + holiday
    if (width <= mediumMaxWidth && height <= mediumMaxHeight) {
      return WidgetLayoutType.medium;
    }

    // Large: Big widget, show full calendar
    return WidgetLayoutType.large;
  }

  /// Get responsive breakpoints for Flutter widgets
  static Map<String, double> getBreakpoints() {
    return {'mobile': 480, 'tablet': 800, 'desktop': 1000};
  }

  /// Build responsive widget based on layout type
  static Widget buildResponsiveWidget({
    required BuildContext context,
    required WidgetLayoutType layoutType,
    required Map<String, dynamic> data,
    VoidCallback? onTap,
  }) {
    switch (layoutType) {
      case WidgetLayoutType.extraSmall:
        return _buildExtraSmallLayout(context, data, onTap);
      case WidgetLayoutType.small:
        return _buildSmallLayout(context, data, onTap);
      case WidgetLayoutType.medium:
        return _buildMediumLayout(context, data, onTap);
      case WidgetLayoutType.large:
        return _buildLargeLayout(context, data, onTap);
    }
  }

  /// Extra Small Layout: Show only percentage
  static Widget _buildExtraSmallLayout(
    BuildContext context,
    Map<String, dynamic> data,
    VoidCallback? onTap,
  ) {
    final percentage = data['percentage'] ?? 0;
    final monthName = data['monthName']?.toString().substring(0, 3) ?? 'Jan';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text(
              monthName,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Small Layout: Show stats with progress bar
  static Widget _buildSmallLayout(
    BuildContext context,
    Map<String, dynamic> data,
    VoidCallback? onTap,
  ) {
    final monthName = data['monthName'] ?? '';
    final year = data['year'] ?? '';
    final attendedDays = data['attendedDays'] ?? 0;
    final totalDays = data['totalDays'] ?? 0;
    final percentage = data['percentage'] ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$monthName $year',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$attendedDays / $totalDays days',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.outline.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Medium Layout: Show stats with next holiday
  static Widget _buildMediumLayout(
    BuildContext context,
    Map<String, dynamic> data,
    VoidCallback? onTap,
  ) {
    final monthName = data['monthName'] ?? '';
    final year = data['year'] ?? '';
    final attendedDays = data['attendedDays'] ?? 0;
    final totalDays = data['totalDays'] ?? 0;
    final percentage = data['percentage'] ?? 0;
    final nextHoliday = data['nextHoliday'];

    String holidayText = 'No upcoming holidays';
    if (nextHoliday != null) {
      holidayText = 'Next: ${nextHoliday['name']} on ${nextHoliday['date']}';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$monthName $year',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$percentage%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.outline.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Attendance: $attendedDays / $totalDays days',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.celebration,
                    size: 16,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      holidayText,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.8),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Large Layout: Show full calendar view
  static Widget _buildLargeLayout(
    BuildContext context,
    Map<String, dynamic> data,
    VoidCallback? onTap,
  ) {
    final monthName = data['monthName'] ?? '';
    final year = data['year'] ?? '';
    final attendedDays = data['attendedDays'] ?? 0;
    final totalDays = data['totalDays'] ?? 0;
    final percentage = data['percentage'] ?? 0;
    final calendarData =
        data['calendarData'] as List<Map<String, dynamic>>? ?? [];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$monthName $year',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$percentage%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Calendar Grid
            Expanded(child: _buildCalendarGrid(context, calendarData)),

            const SizedBox(height: 12),

            // Footer Stats
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Attended: $attendedDays days',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Total: $totalDays days',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build calendar grid for large layout
  static Widget _buildCalendarGrid(
    BuildContext context,
    List<Map<String, dynamic>> calendarData,
  ) {
    if (calendarData.isEmpty) {
      return const Center(child: Text('No calendar data available'));
    }

    // Calculate grid dimensions
    final daysInMonth = calendarData.length;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: daysInMonth,
      itemBuilder: (context, index) {
        final dayData = calendarData[index];
        return _buildCalendarDay(context, dayData);
      },
    );
  }

  /// Build individual calendar day
  static Widget _buildCalendarDay(
    BuildContext context,
    Map<String, dynamic> dayData,
  ) {
    final day = dayData['day'] ?? 0;
    final isAttended = dayData['isAttended'] ?? false;
    final isHoliday = dayData['isHoliday'] ?? false;
    final isToday = dayData['isToday'] ?? false;
    final isWorkingDay = dayData['isWorkingDay'] ?? true;

    Color backgroundColor = Colors.transparent;
    Color textColor = Theme.of(context).colorScheme.onSurface;
    Widget? icon;

    if (isHoliday) {
      backgroundColor = Theme.of(
        context,
      ).colorScheme.secondary.withOpacity(0.2);
      icon = Icon(
        Icons.celebration,
        size: 12,
        color: Theme.of(context).colorScheme.secondary,
      );
    } else if (isAttended) {
      backgroundColor = Theme.of(context).colorScheme.primary.withOpacity(0.2);
      icon = Icon(
        Icons.check,
        size: 12,
        color: Theme.of(context).colorScheme.primary,
      );
    } else if (!isWorkingDay) {
      textColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.4);
    }

    if (isToday) {
      backgroundColor = Theme.of(context).colorScheme.primary;
      textColor = Theme.of(context).colorScheme.onPrimary;
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
        border: isToday
            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
            : null,
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              day.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: textColor,
              ),
            ),
          ),
          if (icon != null) Positioned(top: 2, right: 2, child: icon),
        ],
      ),
    );
  }
}

/// Widget layout types for responsive design
enum WidgetLayoutType {
  extraSmall, // XS: Only percentage
  small, // S: Stats with progress
  medium, // M: Stats with holiday
  large, // L: Full calendar
}
