import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as auth_provider;
import '../providers/attendance_provider.dart';
import '../providers/holiday_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/attendance_calendar.dart';
import '../widgets/office_log_logo.dart';
import '../themes/app_themes.dart';
import '../utils/working_days_calculator.dart';
import '../utils/attendance_calculator.dart';
import '../services/admin_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _currentMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Initialize services and load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final attendanceProvider = Provider.of<AttendanceProvider>(
        context,
        listen: false,
      );
      final holidayProvider = Provider.of<HolidayProvider>(
        context,
        listen: false,
      );

      // Initialize services first
      attendanceProvider.initializeServices();
      holidayProvider.initializeHolidays();

      // Then load attendance data
      attendanceProvider.loadCurrentMonthAttendance();
    });
  }

  void _onMonthChanged(DateTime focusedDay) {
    setState(() {
      _currentMonth = focusedDay;
    });

    // Load attendance data for the new month
    Provider.of<AttendanceProvider>(
      context,
      listen: false,
    ).loadMonthAttendance(focusedDay.year, focusedDay.month);

    // Load holidays for the new month
    Provider.of<HolidayProvider>(
      context,
      listen: false,
    ).loadHolidaysForMonth(focusedDay.year, focusedDay.month);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Consumer2<auth_provider.AuthProvider, ThemeProvider>(
          builder: (context, authProvider, themeProvider, child) {
            final user = authProvider.user;

            return AppBar(
              title: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      // Tap action: Navigate to Profile Screen
                      Navigator.of(context).pushNamed('/profile');
                    },
                    onLongPress: () async {
                      // Long press action: Check admin access
                      final isAdmin = await AdminService.isCurrentUserAdmin();
                      if (isAdmin) {
                        if (mounted) {
                          Navigator.of(context).pushNamed('/admin');
                        }
                      } else {
                        if (mounted) {
                          AdminService.showAccessDeniedMessage(context);
                        }
                      }
                    },
                    child: CircleAvatar(
                      radius: 18,
                      backgroundImage: user?.photoURL != null
                          ? NetworkImage(user!.photoURL!)
                          : null,
                      backgroundColor: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                      child: user?.photoURL == null
                          ? Text(
                              user?.displayName
                                      ?.substring(0, 1)
                                      .toUpperCase() ??
                                  'U',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: OfficeLogAppBarTitle()),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: () => Navigator.of(context).pushNamed('/settings'),
                  icon: const Icon(Icons.settings),
                  tooltip: 'Settings',
                ),
              ],
            );
          },
        ),
      ),
      body: Consumer2<auth_provider.AuthProvider, AttendanceProvider>(
        builder: (context, authProvider, attendanceProvider, child) {
          final user = authProvider.user;

          if (user == null) {
            return const Center(child: Text('No user logged in'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              await attendanceProvider.loadCurrentMonthAttendance();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Calendar
                  AttendanceCalendar(onMonthChanged: _onMonthChanged),

                  const SizedBox(height: 16),

                  // Status Card (Offline sync, holidays, etc.)
                  _buildStatusCard(context),

                  // Only show spacing if status card is visible
                  Consumer2<AttendanceProvider, HolidayProvider>(
                    builder:
                        (context, attendanceProvider, holidayProvider, child) {
                          return FutureBuilder<Map<String, dynamic>>(
                            future: _getStatusCardData(attendanceProvider),
                            builder: (context, snapshot) {
                              final statusData = snapshot.data;

                              // Only show SizedBox if status card is visible
                              if (statusData != null &&
                                  (statusData['hasOfflineData'] ||
                                      statusData['isHoliday'] ||
                                      statusData['withinGeofence'])) {
                                return const SizedBox(height: 16);
                              }

                              return const SizedBox.shrink();
                            },
                          );
                        },
                  ),

                  // Stats Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Consumer<AttendanceProvider>(
                            builder: (context, attendanceProvider, child) {
                              return FutureBuilder<Map<String, dynamic>>(
                                future:
                                    AttendanceCalculator.calculateAttendance(
                                      _currentMonth.year,
                                      _currentMonth.month,
                                      attendanceProvider.attendedDates,
                                    ),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(20.0),
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }

                                  if (snapshot.hasError) {
                                    return Center(
                                      child: Text(
                                        'Error loading stats: ${snapshot.error}',
                                      ),
                                    );
                                  }

                                  final stats = snapshot.data ?? {};

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${AttendanceCalculator.getMonthName(_currentMonth.month)} ${_currentMonth.year} Stats',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.of(
                                              context,
                                            ).pushNamed('/summary'),
                                            child: const Text('View Summary'),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      // Monthly Compliance Card
                                      _buildMonthlyComplianceCard(
                                        context,
                                        stats,
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4), // Space for bottom button
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Consumer<AttendanceProvider>(
        builder: (context, attendanceProvider, child) {
          final rawSelectedDate =
              attendanceProvider.selectedDate ?? DateTime.now();
          // Normalize both dates to midnight for proper comparison
          final selectedDate = DateTime(
            rawSelectedDate.year,
            rawSelectedDate.month,
            rawSelectedDate.day,
          );
          final isSelectedDateAttended = attendanceProvider.isDateAttended(
            selectedDate,
          );
          final today = DateTime.now();
          final todayDateOnly = DateTime(today.year, today.month, today.day);
          final isFutureDate = selectedDate.isAfter(todayDateOnly);
          final isWorkingDay = WorkingDaysCalculator.isWorkingDay(selectedDate);
          final nonWorkingReason = WorkingDaysCalculator.getNonWorkingDayReason(
            selectedDate,
          );

          return Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      (attendanceProvider.isLoading ||
                          isFutureDate ||
                          !isWorkingDay)
                      ? null
                      : () async {
                          if (isSelectedDateAttended) {
                            // Show delete confirmation dialog
                            _showDeleteAttendanceDialog(
                              context,
                              selectedDate,
                              attendanceProvider,
                            );
                          } else {
                            // Mark attendance
                            final scaffoldMessenger = ScaffoldMessenger.of(
                              context,
                            );
                            // Cache theme colors before async operation
                            final successColor = AppThemes.getSuccessColor(
                              context,
                            );
                            final errorColor = AppThemes.getErrorColor(context);

                            final success = await attendanceProvider
                                .markAttendanceForDate(selectedDate);
                            if (success && mounted) {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Attendance recorded for ${_formatDate(selectedDate)}!',
                                  ),
                                  backgroundColor: successColor,
                                ),
                              );
                            } else if (mounted &&
                                attendanceProvider.errorMessage != null) {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    attendanceProvider.errorMessage!,
                                  ),
                                  backgroundColor: errorColor,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: (isFutureDate || !isWorkingDay)
                        ? AppThemes.getMutedColor(context)
                        : isSelectedDateAttended
                        ? AppThemes.getErrorColor(context)
                        : Theme.of(context).colorScheme.primary,
                    foregroundColor: (isFutureDate || !isWorkingDay)
                        ? AppThemes.getMutedColor(context)
                        : isSelectedDateAttended
                        ? Colors.white
                        : Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: attendanceProvider.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isSelectedDateAttended
                                  ? Icons.delete
                                  : Icons.login,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isSelectedDateAttended
                                  ? 'Delete Attendance for ${_formatDate(selectedDate)}'
                                  : isFutureDate
                                  ? 'Future Date'
                                  : !isWorkingDay
                                  ? nonWorkingReason ?? ''
                                  : 'Log Attendance for ${_formatDate(selectedDate)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthlyComplianceCard(
    BuildContext context,
    Map<String, dynamic> stats,
  ) {
    // Get color based on attendance percentage
    Color getComplianceColor(double percentage) {
      if (percentage >= 80) {
        return AppThemes.getSuccessColor(context);
      } else if (percentage >= 60) {
        return Colors.orange;
      } else {
        return AppThemes.getErrorColor(context);
      }
    }

    // Get icon based on compliance status
    IconData getComplianceIcon(String compliance) {
      switch (compliance) {
        case 'good':
          return Icons.check_circle;
        case 'borderline':
          return Icons.warning;
        case 'poor':
          return Icons.error;
        default:
          return Icons.analytics;
      }
    }

    final percentage = stats['attendancePercentage'] as double;
    final compliance = stats['compliance'] as String;
    final color = getComplianceColor(percentage);
    final icon = getComplianceIcon(compliance);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: color, size: 24),
              const SizedBox(width: 12),
              Text(
                '📊 Monthly Attendance',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const Spacer(),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 20),

          // Main stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildComplianceItem(
                context,
                'Required',
                '${stats['requiredDays']}',
                Colors.blue,
              ),
              _buildComplianceItem(
                context,
                'Attended',
                '${stats['attendedDays']}',
                AppThemes.getSuccessColor(context),
              ),
              _buildComplianceItem(
                context,
                'Remaining',
                '${stats['remainingDays']}',
                stats['remainingDays'] > 0
                    ? Colors.orange
                    : AppThemes.getSuccessColor(context),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Progress section
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progress',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: color.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                        ),
                        const SizedBox(width: 8),
                        if (percentage >= 60)
                          const Text('✅', style: TextStyle(fontSize: 16))
                        else if (percentage >= 55)
                          const Text('⚠️', style: TextStyle(fontSize: 16))
                        else
                          const Text('❌', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  percentage >= 60
                      ? 'On Track'
                      : percentage >= 55
                      ? 'Borderline'
                      : 'Behind',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: color.withValues(alpha: 0.8)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
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
    return '${date.day} ${months[date.month - 1]}';
  }

  void _showDeleteAttendanceDialog(
    BuildContext context,
    DateTime selectedDate,
    AttendanceProvider attendanceProvider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Delete Attendance'),
            ],
          ),
          content: Text(
            'Are you sure you want to delete your attendance for ${_formatDate(selectedDate)}?\n\nThis action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();

                // Cache theme colors before async operation
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final successColor = AppThemes.getSuccessColor(context);
                final errorColor = AppThemes.getErrorColor(context);

                final success = await attendanceProvider
                    .deleteAttendanceForDate(selectedDate);

                if (success && mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Attendance deleted for ${_formatDate(selectedDate)}!',
                      ),
                      backgroundColor: successColor,
                    ),
                  );
                } else if (mounted && attendanceProvider.errorMessage != null) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(attendanceProvider.errorMessage!),
                      backgroundColor: errorColor,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemes.getErrorColor(context),
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    return Consumer2<AttendanceProvider, HolidayProvider>(
      builder: (context, attendanceProvider, holidayProvider, child) {
        return FutureBuilder<Map<String, dynamic>>(
          future: _getStatusCardData(attendanceProvider),
          builder: (context, snapshot) {
            final statusData = snapshot.data;

            // Don't show the card if there's nothing to display
            if (statusData == null ||
                (!statusData['hasOfflineData'] &&
                    !statusData['isHoliday'] &&
                    !statusData['withinGeofence'])) {
              return const SizedBox.shrink();
            }

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Offline sync status
                    if (statusData['hasOfflineData'])
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.sync_problem, color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${statusData['offlineCount']} unsynced attendance records',
                                style: TextStyle(color: Colors.orange[700]),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                await attendanceProvider.forceSyncOfflineData();
                              },
                              child: const Text('Sync'),
                            ),
                          ],
                        ),
                      ),

                    // Today's holiday status
                    if (statusData['isHoliday'])
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppThemes.getAccentColor(
                            context,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppThemes.getAccentColor(
                              context,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.celebration,
                              color: AppThemes.getAccentColor(context),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Today is ${statusData['holidayName']}',
                                style: TextStyle(
                                  color: AppThemes.getAccentColor(context),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Geofence status
                    if (statusData['withinGeofence'])
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'You are at the office location',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    statusData['canAutoCheckIn']
                                        ? 'Auto check-in will happen automatically if enabled in settings'
                                        : 'Already checked in today',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Helper method to gather all status data
  Future<Map<String, dynamic>> _getStatusCardData(
    AttendanceProvider attendanceProvider,
  ) async {
    try {
      final offlineCount = await attendanceProvider.getOfflineAttendanceCount();
      final holidayName = await attendanceProvider.getHolidayName(
        DateTime.now(),
      );
      final withinGeofence = await attendanceProvider.isWithinOfficeGeofence();
      final today = DateTime.now();
      final isAttended = attendanceProvider.isDateAttended(today);
      final isWorkingDay = WorkingDaysCalculator.isWorkingDay(today);

      return {
        'hasOfflineData': offlineCount > 0,
        'offlineCount': offlineCount,
        'isHoliday': holidayName != null,
        'holidayName': holidayName,
        'withinGeofence': withinGeofence == true,
        'canAutoCheckIn': !isAttended && isWorkingDay,
      };
    } catch (e) {
      return {
        'hasOfflineData': false,
        'isHoliday': false,
        'withinGeofence': false,
        'canAutoCheckIn': false,
      };
    }
  }
}
