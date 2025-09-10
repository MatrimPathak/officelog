import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/holiday_provider.dart';
import '../themes/app_themes.dart';

class AttendanceCalendar extends StatefulWidget {
  final Function(DateTime)? onDateSelected;
  final Function(DateTime)? onMonthChanged;

  const AttendanceCalendar({
    super.key,
    this.onDateSelected,
    this.onMonthChanged,
  });

  @override
  State<AttendanceCalendar> createState() => _AttendanceCalendarState();
}

class _AttendanceCalendarState extends State<AttendanceCalendar> {
  DateTime _focusedDay = DateTime.now();
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    // Initialize focused day to current month
    _focusedDay = DateTime.now();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _handleDateSelection(BuildContext context, DateTime selectedDay) {
    final attendanceProvider = Provider.of<AttendanceProvider>(
      context,
      listen: false,
    );
    attendanceProvider.selectDate(selectedDay);

    // Update focused day to the selected day's month to keep the calendar on that month
    setState(() {
      _focusedDay = DateTime(selectedDay.year, selectedDay.month, 1);
    });

    if (widget.onDateSelected != null) {
      widget.onDateSelected!(selectedDay);
    }
  }

  void _handleMonthChange(DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
    });

    if (widget.onMonthChanged != null) {
      widget.onMonthChanged!(focusedDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AttendanceProvider, HolidayProvider>(
      builder: (context, attendanceProvider, holidayProvider, child) {
        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TableCalendar<DateTime>(
              firstDay: DateTime.utc(2025, 9, 1), // App starts September 2025
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.sunday,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondary,
                  fontWeight: FontWeight.bold,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                todayTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                markerDecoration: BoxDecoration(
                  color: AppThemes.getSuccessColor(context),
                  shape: BoxShape.circle,
                ),
                defaultTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                weekendTextStyle: TextStyle(
                  color: AppThemes.getMutedColor(context),
                ),
                holidayTextStyle: TextStyle(
                  color: AppThemes.getMutedColor(context),
                ),
              ),
              selectedDayPredicate: (day) {
                return attendanceProvider.isDateSelected(day);
              },
              eventLoader: (day) {
                return attendanceProvider.isDateAttended(day) ? [day] : [];
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  final isAttended = attendanceProvider.isDateAttended(day);
                  final isHoliday = holidayProvider.isHoliday(day);

                  if (isAttended || isHoliday) {
                    return Positioned(
                      bottom: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isAttended)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: AppThemes.getSuccessColor(context),
                                shape: BoxShape.circle,
                              ),
                            ),
                          if (isHoliday)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: AppThemes.getAccentColor(context),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    );
                  }
                  return null;
                },
                todayBuilder: (context, day, focusedDay) {
                  final isAttended = attendanceProvider.isDateAttended(day);
                  final isHoliday = holidayProvider.isHoliday(day);

                  return FutureBuilder<bool>(
                    future: attendanceProvider.hasUnsyncedAttendance(day),
                    builder: (context, snapshot) {
                      // Check if widget is still mounted before using context
                      if (_disposed || !mounted) {
                        return _buildSimpleDayContent(
                          day,
                          isAttended,
                          isHoliday,
                        );
                      }

                      final hasUnsynced = snapshot.data ?? false;

                      return Container(
                        margin: const EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          color: isHoliday
                              ? AppThemes.getAccentColor(
                                  context,
                                ).withValues(alpha: 0.3)
                              : isAttended
                              ? AppThemes.getSuccessColor(
                                  context,
                                ).withValues(alpha: 0.3)
                              : Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: hasUnsynced
                                ? Colors.orange
                                : Theme.of(context).colorScheme.primary,
                            width: 2,
                            style: hasUnsynced
                                ? BorderStyle.none
                                : BorderStyle.solid,
                          ),
                        ),
                        child: hasUnsynced
                            ? DashedCircleBorder(
                                color: Colors.orange,
                                strokeWidth: 2,
                                child: _buildDayContent(
                                  context,
                                  day,
                                  isAttended,
                                  isHoliday,
                                ),
                              )
                            : _buildDayContent(
                                context,
                                day,
                                isAttended,
                                isHoliday,
                              ),
                      );
                    },
                  );
                },
                holidayBuilder: (context, day, focusedDay) {
                  final isHoliday = holidayProvider.isHoliday(day);
                  if (!isHoliday) return null;

                  return Container(
                    margin: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: AppThemes.getAccentColor(context),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
                selectedBuilder: (context, day, focusedDay) {
                  return Container(
                    margin: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
              onDaySelected: (selectedDay, focusedDay) {
                _handleDateSelection(context, selectedDay);
              },
              onPageChanged: (focusedDay) {
                _handleMonthChange(focusedDay);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDayContent(
    BuildContext context,
    DateTime day,
    bool isAttended,
    bool isHoliday,
  ) {
    return Center(
      child: Stack(
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              color: isHoliday
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isAttended)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: AppThemes.getSuccessColor(context),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 10),
              ),
            ),
          if (isHoliday && !isAttended)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: AppThemes.getAccentColor(context),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.celebration,
                  color: Colors.white,
                  size: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSimpleDayContent(DateTime day, bool isAttended, bool isHoliday) {
    return Container(
      margin: const EdgeInsets.all(4.0),
      decoration: const BoxDecoration(
        color: Colors.grey,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// Custom widget for dashed circle border
class DashedCircleBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  const DashedCircleBorder({
    super.key,
    required this.child,
    this.color = Colors.black,
    this.strokeWidth = 1.0,
    this.dashWidth = 4.0,
    this.dashSpace = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DashedCirclePainter(
        color: color,
        strokeWidth: strokeWidth,
        dashWidth: dashWidth,
        dashSpace: dashSpace,
      ),
      child: child,
    );
  }
}

class DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DashedCirclePainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final circumference = 2 * 3.14159 * radius;
    final dashCount = (circumference / (dashWidth + dashSpace)).floor();
    final actualDashWidth = circumference / dashCount / 2;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = (i * 2 * actualDashWidth / radius) - (3.14159 / 2);
      final sweepAngle = actualDashWidth / radius;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
