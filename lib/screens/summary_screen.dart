import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/attendance_provider.dart';
import '../themes/app_themes.dart';
import '../utils/working_days_calculator.dart';

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
    if (_yearlyData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text('No attendance data available for this year'),
          ),
        ),
      );
    }

    final totalDaysAttended = _yearlyData.fold<int>(
      0,
      (sum, month) => sum + (month['attendedDays'] as int),
    );
    final totalWorkingDays = _yearlyData.fold<int>(
      0,
      (sum, month) => sum + (month['totalDays'] as int),
    );
    final averagePercentage = totalWorkingDays > 0
        ? (totalDaysAttended / totalWorkingDays) * 100
        : 0.0;

    // Find best month
    final bestMonth = _yearlyData.isNotEmpty
        ? _yearlyData.reduce(
            (a, b) => (a['percentage'] as double) > (b['percentage'] as double)
                ? a
                : b,
          )
        : null;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'YTD Present',
                '$totalDaysAttended days',
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
                'Total Working Days',
                '$totalWorkingDays days',
                Icons.calendar_month,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Overall Attendance',
                '${averagePercentage.toStringAsFixed(1)}%',
                Icons.percent,
                averagePercentage >= 80
                    ? AppThemes.getSuccessColor(context)
                    : averagePercentage >= 60
                    ? Colors.orange
                    : AppThemes.getErrorColor(context),
                isLarge: true,
              ),
            ),
          ],
        ),
      ],
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

  Widget _buildQuarterlyStats() {
    if (_yearlyData.isEmpty) {
      return const SizedBox.shrink();
    }

    final attendanceProvider = Provider.of<AttendanceProvider>(
      context,
      listen: false,
    );

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
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Show quarters starting from current month
            ...List.generate(4, (index) {
              final currentMonth = DateTime.now().month;
              final currentQuarter = WorkingDaysCalculator.getQuarter(
                currentMonth,
              );
              final quarter = currentQuarter + index;

              // Skip quarters beyond Q4
              if (quarter > 4) return const SizedBox.shrink();

              final quarterStats = attendanceProvider.getQuarterStats(
                _selectedYear,
                quarter,
              );

              final attendedDays = quarterStats['attendedDays'] as int;
              final totalDays = quarterStats['totalDays'] as int;
              final percentage = quarterStats['percentage'] as double;
              final quarterName = quarterStats['quarterName'] as String;

              // Determine color based on percentage
              Color percentageColor;
              if (percentage >= 80) {
                percentageColor = AppThemes.getSuccessColor(context);
              } else if (percentage >= 60) {
                percentageColor = Colors.orange;
              } else {
                percentageColor = AppThemes.getErrorColor(context);
              }

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
                            style: Theme.of(context).textTheme.titleMedium
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
                      'Attendance: $attendedDays / $totalDays days',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),

                    // Progress bar
                    LinearProgressIndicator(
                      value: totalDays > 0 ? percentage / 100 : 0,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        percentageColor,
                      ),
                      minHeight: 6,
                    ),

                    // Target info
                    if (quarterStats['targetInfo'] != null) ...[
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
                                  : Icons.info,
                              color: percentageColor,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                quarterStats['targetInfo']['message'] as String,
                                style: Theme.of(context).textTheme.bodySmall
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
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyChart() {
    if (_yearlyData.isEmpty) {
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
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                          if (value.toInt() >= 1 && value.toInt() <= 12) {
                            final monthNames = [
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
                            return Text(
                              monthNames[value.toInt() - 1],
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
                  barGroups: _yearlyData.map((month) {
                    return BarChartGroupData(
                      x: month['month'] as int,
                      barRods: [
                        BarChartRodData(
                          toY: month['percentage'] as double,
                          color: _getBarColor(month['percentage'] as double),
                          width: 16,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBarColor(double percentage) {
    if (percentage >= 90) return AppThemes.getSuccessColor(context);
    if (percentage >= 75) return Colors.lightGreen;
    if (percentage >= 60) return AppThemes.getAccentColor(context);
    return AppThemes.getErrorColor(context);
  }

  Widget _buildMonthlyDetailsList() {
    if (_yearlyData.isEmpty) {
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
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._yearlyData.map((month) => _buildMonthDetailItem(month)),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthDetailItem(Map<String, dynamic> month) {
    final percentage = month['percentage'] as double;
    final attendedDays = month['attendedDays'] as int;
    final totalDays = month['totalDays'] as int;
    final monthName = month['monthName'] as String;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              monthName,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              '$attendedDays/$totalDays',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getBarColor(percentage).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getBarColor(percentage).withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: _getBarColor(percentage),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
