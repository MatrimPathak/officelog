import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/attendance_provider.dart';
import '../themes/app_themes.dart';
import '../utils/attendance_calculator.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  int _selectedYear = DateTime.now().year;
  List<Map<String, dynamic>> _yearlyData = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadYearlyData();
  }

  Future<void> _loadYearlyData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final attendanceProvider = Provider.of<AttendanceProvider>(
        context,
        listen: false,
      );
      final data = await attendanceProvider.getYearlyDetails(_selectedYear);

      // Filter data to start from September for the app start year (2025)
      // and show all months for subsequent years
      final filteredData = _filterDataFromAppStart(data);

      setState(() {
        _yearlyData = filteredData;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Get available years starting from app launch (September 2025)
  List<int> _getAvailableYears() {
    const appStartYear = 2025;
    final currentYear = DateTime.now().year;
    final currentMonth = DateTime.now().month;

    List<int> years = [];

    // If we're in 2025 and haven't reached September yet, don't show any years
    if (currentYear == 2025 && currentMonth < 9) {
      return [];
    }

    for (int year = appStartYear; year <= currentYear; year++) {
      years.add(year);
    }

    return years.reversed.toList(); // Most recent first
  }

  // Filter data to start from September for the app start year
  List<Map<String, dynamic>> _filterDataFromAppStart(
    List<Map<String, dynamic>> data,
  ) {
    const appStartYear = 2025;
    const appStartMonth = 9; // September

    if (_selectedYear == appStartYear) {
      // For 2025, only show September onwards
      return data.where((monthData) {
        final month = monthData['month'] as int;
        return month >= appStartMonth;
      }).toList();
    } else {
      // For other years, show all months
      return data;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Summary'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedYear,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                items: _getAvailableYears().map((year) {
                  return DropdownMenuItem(
                    value: year,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          year.toString(),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (year) {
                  if (year != null) {
                    setState(() {
                      _selectedYear = year;
                    });
                    _loadYearlyData();
                  }
                },
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadYearlyData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Year Summary Cards
                    _buildSummaryCards(),
                    const SizedBox(height: 16),

                    // Quarterly Stats
                    _buildQuarterlyStats(),
                    const SizedBox(height: 16),

                    // Monthly Chart
                    _buildMonthlyChart(),
                    const SizedBox(height: 16),

                    // Monthly Details List
                    _buildMonthlyDetailsList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCards() {
    return Consumer<AttendanceProvider>(
      builder: (context, attendanceProvider, child) {
        // Get current month data using AttendanceCalculator
        final currentMonth = DateTime.now().month;
        final currentYear = DateTime.now().year;
        final attendedDates = attendanceProvider.attendedDates;

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: Future.wait([
            AttendanceCalculator.calculateAttendance(
              currentYear,
              currentMonth,
              attendedDates,
            ),
            AttendanceCalculator.calculateYearlyAttendance(
              _selectedYear,
              attendedDates,
            ),
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            if (snapshot.hasError) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text('Error loading stats: ${snapshot.error}'),
                  ),
                ),
              );
            }

            final results = snapshot.data ?? [];
            if (results.length < 2) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text('No attendance data available for this year'),
                  ),
                ),
              );
            }

            final currentMonthStats = results[0];
            final yearlyStats = results[1];

            // Find best performing month from _yearlyData
            final bestMonth = _yearlyData.isNotEmpty
                ? _yearlyData.reduce(
                    (a, b) =>
                        (a['percentage'] as double) >
                            (b['percentage'] as double)
                        ? a
                        : b,
                  )
                : null;

            return Column(
              children: [
                // Current Month Stats Card (highlighted)
                Card(
                  elevation: 4,
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${AttendanceCalculator.getMonthName(currentMonth)} $currentYear',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatColumn(
                              'Required',
                              '${currentMonthStats['requiredDays']} days',
                              Icons.assignment,
                              Colors.blue,
                            ),
                            _buildStatColumn(
                              'Attended',
                              '${currentMonthStats['attendedDays']} days',
                              Icons.check_circle,
                              AppThemes.getSuccessColor(context),
                            ),
                            _buildStatColumn(
                              'Attendance',
                              '${currentMonthStats['attendancePercentage'].toStringAsFixed(1)}%',
                              Icons.percent,
                              _getComplianceColor(
                                currentMonthStats['attendancePercentage']
                                    as double,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Yearly Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'YTD Present',
                        '${yearlyStats['attendedDays']} days',
                        Icons.check_circle,
                        AppThemes.getSuccessColor(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'Best Month',
                        bestMonth != null
                            ? '${bestMonth['monthName']} ${(bestMonth['percentage'] as double).toStringAsFixed(1)}%'
                            : 'N/A',
                        Icons.star,
                        AppThemes.getAccentColor(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Required Days',
                        '${yearlyStats['requiredDays']} days',
                        Icons.assignment,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'Overall Attendance',
                        '${yearlyStats['attendancePercentage'].toStringAsFixed(1)}%',
                        Icons.percent,
                        _getComplianceColor(
                          yearlyStats['attendancePercentage'] as double,
                        ),
                        isLarge: true,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isLarge = false,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: isLarge ? 28 : 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 18,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Color _getComplianceColor(double percentage) {
    if (percentage >= 80) {
      return AppThemes.getSuccessColor(context);
    } else if (percentage >= 60) {
      return Colors.orange;
    } else {
      return AppThemes.getErrorColor(context);
    }
  }

  Widget _buildQuarterlyStats() {
    return Consumer<AttendanceProvider>(
      builder: (context, attendanceProvider, child) {
        final attendedDates = attendanceProvider.attendedDates;

        if (attendedDates.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics,
                      color: AppThemes.getAccentColor(context),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '📊 Quarterly Stats',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Show quarters for the selected year
                ...List.generate(4, (index) {
                  final quarter = index + 1;

                  return FutureBuilder<Map<String, dynamic>>(
                    future: AttendanceCalculator.calculateQuarterAttendance(
                      _selectedYear,
                      quarter,
                      attendedDates,
                    ),
                    builder: (context, quarterSnapshot) {
                      if (quarterSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (quarterSnapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text('Error: ${quarterSnapshot.error}'),
                        );
                      }

                      final quarterStats = quarterSnapshot.data ?? {};

                      final attendedDays =
                          quarterStats['attendedDays'] as int? ?? 0;
                      final requiredDays =
                          quarterStats['requiredDays'] as int? ?? 0;
                      final percentage =
                          quarterStats['attendancePercentage'] as double? ??
                          0.0;
                      final quarterName = 'Q$quarter';

                      // Skip quarters with no required days
                      if (requiredDays == 0) return const SizedBox.shrink();

                      final percentageColor = _getComplianceColor(percentage);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Quarter header
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '$quarterName $_selectedYear',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Text(
                                  '${percentage.toStringAsFixed(1)}%',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: percentageColor,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Attendance details
                            Text(
                              'Attendance: $attendedDays / $requiredDays days required',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),

                            // Progress bar
                            LinearProgressIndicator(
                              value: requiredDays > 0 ? percentage / 100 : 0,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                percentageColor,
                              ),
                              minHeight: 6,
                            ),

                            // Compliance status
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: percentageColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: percentageColor.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    percentage >= 60
                                        ? Icons.check_circle
                                        : percentage >= 55
                                        ? Icons.warning
                                        : Icons.error,
                                    color: percentageColor,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      percentage >= 60
                                          ? 'Meeting attendance requirement'
                                          : percentage >= 55
                                          ? 'Borderline - needs improvement'
                                          : 'Below requirement - attention needed',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: percentageColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthlyChart() {
    return Consumer<AttendanceProvider>(
      builder: (context, attendanceProvider, child) {
        final attendedDates = attendanceProvider.attendedDates;

        if (attendedDates.isEmpty) {
          return const SizedBox.shrink();
        }

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: Future.wait([
            for (int month = 1; month <= 12; month++)
              AttendanceCalculator.calculateAttendance(
                _selectedYear,
                month,
                attendedDates,
              ),
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            if (snapshot.hasError) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(child: Text('Error: ${snapshot.error}')),
                ),
              );
            }

            final monthlyResults = snapshot.data ?? [];
            List<BarChartGroupData> chartData = [];

            for (int i = 0; i < monthlyResults.length; i++) {
              final monthStats = monthlyResults[i];
              final month = i + 1;

              // Only include months with some data
              if ((monthStats['requiredDays'] as int? ?? 0) > 0 ||
                  (monthStats['attendedDays'] as int? ?? 0) > 0) {
                final percentage =
                    monthStats['attendancePercentage'] as double? ?? 0.0;
                chartData.add(
                  BarChartGroupData(
                    x: month,
                    barRods: [
                      BarChartRodData(
                        toY: percentage,
                        color: _getComplianceColor(percentage),
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  ),
                );
              }
            }

            if (chartData.isEmpty) {
              return const SizedBox.shrink();
            }

            return Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Attendance Percentage',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 180,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 100,
                          barTouchData: BarTouchData(enabled: false),
                          titlesData: FlTitlesData(
                            show: true,
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= 1 &&
                                      value.toInt() <= 12) {
                                    return Text(
                                      AttendanceCalculator.getShortMonthName(
                                        value.toInt(),
                                      ),
                                      style: const TextStyle(fontSize: 10),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    '${value.toInt()}%',
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: chartData,
                        ),
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

  Widget _buildMonthlyDetailsList() {
    return Consumer<AttendanceProvider>(
      builder: (context, attendanceProvider, child) {
        final attendedDates = attendanceProvider.attendedDates;

        if (attendedDates.isEmpty) {
          return const SizedBox.shrink();
        }

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: Future.wait([
            for (int month = 1; month <= 12; month++)
              AttendanceCalculator.calculateAttendance(
                _selectedYear,
                month,
                attendedDates,
              ),
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            if (snapshot.hasError) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(child: Text('Error: ${snapshot.error}')),
                ),
              );
            }

            final monthlyResults = snapshot.data ?? [];
            List<Map<String, dynamic>> monthlyData = [];

            for (int i = 0; i < monthlyResults.length; i++) {
              final monthStats = Map<String, dynamic>.from(monthlyResults[i]);
              final month = i + 1;

              // Only include months with some required days or attended days
              if ((monthStats['requiredDays'] as int? ?? 0) > 0 ||
                  (monthStats['attendedDays'] as int? ?? 0) > 0) {
                monthStats['monthName'] = AttendanceCalculator.getMonthName(
                  month,
                );
                monthlyData.add(monthStats);
              }
            }

            if (monthlyData.isEmpty) {
              return const SizedBox.shrink();
            }

            return Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...monthlyData.map((month) => _buildMonthDetailItem(month)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMonthDetailItem(Map<String, dynamic> month) {
    final percentage = month['attendancePercentage'] as double;
    final attendedDays = month['attendedDays'] as int;
    final requiredDays = month['requiredDays'] as int;
    final workingDays = month['workingDays'] as int;
    final monthName = month['monthName'] as String;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          border: Border.all(
            color: _getComplianceColor(percentage).withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(8),
          color: _getComplianceColor(percentage).withValues(alpha: 0.05),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month header with percentage
            Row(
              children: [
                Expanded(
                  child: Text(
                    monthName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getComplianceColor(
                      percentage,
                    ).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getComplianceColor(
                        percentage,
                      ).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: _getComplianceColor(percentage),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Attendance details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDetailStat(
                  'Required',
                  '$requiredDays days',
                  Icons.assignment,
                ),
                _buildDetailStat(
                  'Attended',
                  '$attendedDays days',
                  Icons.check_circle,
                ),
                _buildDetailStat(
                  'Working Days',
                  '$workingDays days',
                  Icons.calendar_month,
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Progress bar
            LinearProgressIndicator(
              value: requiredDays > 0
                  ? (attendedDays / requiredDays).clamp(0.0, 1.0)
                  : 0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getComplianceColor(percentage),
              ),
              minHeight: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }
}
