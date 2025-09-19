import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/notification_service.dart';
import '../services/geolocation_service.dart';
import '../services/persistent_background_service.dart';
import '../services/simple_background_geofence_service.dart';
import '../services/battery_optimization_service.dart';
import '../services/settings_persistence_service.dart';
import '../services/location_permission_service.dart';
import '../services/feedback_service.dart';
import '../themes/app_themes.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'dart:io';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  TimeOfDay? _reminderTime;
  bool _reminderEnabled = false;
  bool _autoCheckInEnabled = false;
  bool _isLoading = true;
  bool _isRefreshing = false;
  Map<String, dynamic>? _autoCheckInStatus;
  DateTime? _lastRefresh;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final reminderTime = await NotificationService.getReminderTime();
      final reminderEnabled = await NotificationService.isReminderEnabled();
      final autoCheckInEnabled =
          await PersistentBackgroundService.isAutoCheckInEnabled();
      final autoCheckInStatus = await PersistentBackgroundService.getStatus();

      setState(() {
        _reminderTime = TimeOfDay(
          hour: reminderTime['hour']!,
          minute: reminderTime['minute']!,
        );
        _reminderEnabled = reminderEnabled;
        _autoCheckInEnabled = autoCheckInEnabled;
        _autoCheckInStatus = autoCheckInStatus;
        _lastRefresh = DateTime.now();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? const TimeOfDay(hour: 10, minute: 0),
    );

    if (picked != null) {
      await NotificationService.updateReminderTime(picked.hour, picked.minute);
      setState(() {
        _reminderTime = picked;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reminder time updated to ${picked.format(context)}'),
            backgroundColor: AppThemes.getSuccessColor(context),
          ),
        );
      }
    }
  }

  Future<void> _toggleReminder(bool enabled) async {
    try {
      if (enabled) {
        await NotificationService.scheduleDailyReminder(
          hour: _reminderTime?.hour ?? 10,
          minute: _reminderTime?.minute ?? 0,
        );
      } else {
        await NotificationService.cancelDailyReminder();
      }

      setState(() {
        _reminderEnabled = enabled;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(enabled ? 'Reminder enabled' : 'Reminder disabled'),
            backgroundColor: AppThemes.getSuccessColor(context),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update reminder: $e'),
            backgroundColor: AppThemes.getErrorColor(context),
          ),
        );
      }
    }
  }

  Future<void> _refreshServiceStatus() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      final status = await PersistentBackgroundService.getStatus();
      setState(() {
        _autoCheckInStatus = status;
        _lastRefresh = DateTime.now();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Service status refreshed'),
            backgroundColor: AppThemes.getSuccessColor(context),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh status: $e'),
            backgroundColor: AppThemes.getErrorColor(context),
          ),
        );
      }
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  Future<void> _toggleAutoCheckIn(bool enabled) async {
    try {
      if (enabled) {
        // Request location permissions first
        final hasPermission =
            await LocationPermissionService.requestLocationPermissions();
        if (!hasPermission) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Location permission is required for auto check-in. Please allow location access in the next dialog.',
                ),
                backgroundColor: AppThemes.getErrorColor(context),
                duration: const Duration(seconds: 4),
              ),
            );
          }
          return;
        }

        // Show battery optimization dialog if not asked before
        // Show setup guidance dialog
        if (!await PersistentBackgroundService.hasBatteryOptimizationBeenAsked()) {
          await PersistentBackgroundService.markBatteryOptimizationAsked();

          if (mounted) {
            _showAutoCheckInSetupDialog();
          }
        }

        // Start both background services for better coverage
        final persistentSuccess =
            await PersistentBackgroundService.startAutoCheckIn();
        final simpleSuccess =
            await SimpleBackgroundGeofenceService.startMonitoring();

        if (!persistentSuccess && !simpleSuccess) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Failed to start auto check-in service. Please check permissions.',
                ),
                backgroundColor: AppThemes.getErrorColor(context),
              ),
            );
          }
          return;
        }

        // Disable notifications when auto check-in is enabled
        if (_reminderEnabled) {
          await NotificationService.cancelDailyReminder();
          setState(() {
            _reminderEnabled = false;
          });
        }
      } else {
        await PersistentBackgroundService.stopAutoCheckIn();
        await SimpleBackgroundGeofenceService.stopMonitoring();
      }

      // Reload status
      final status = await PersistentBackgroundService.getStatus();

      setState(() {
        _autoCheckInEnabled = enabled;
        _autoCheckInStatus = status;
        _lastRefresh = DateTime.now();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled
                  ? 'Auto Check-In enabled - monitoring every 5 minutes in foreground and 15 minutes in background!'
                  : 'Auto Check-In disabled',
            ),
            backgroundColor: AppThemes.getSuccessColor(context),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update auto check-in: $e'),
            backgroundColor: AppThemes.getErrorColor(context),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Notifications Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notifications',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Reminder toggle
                  SwitchListTile(
                    title: const Text('Daily Reminder'),
                    subtitle: Text(
                      _autoCheckInEnabled
                          ? 'Disabled when auto check-in is enabled'
                          : 'Get reminded to log attendance',
                    ),
                    value: _reminderEnabled && !_autoCheckInEnabled,
                    onChanged: _autoCheckInEnabled ? null : _toggleReminder,
                  ),

                  // Reminder time
                  if (_reminderEnabled && !_autoCheckInEnabled)
                    ListTile(
                      title: const Text('Reminder Time'),
                      subtitle: Text(
                        _reminderTime?.format(context) ?? '10:00 AM',
                      ),
                      trailing: const Icon(Icons.access_time),
                      onTap: _updateReminderTime,
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Auto Check-in Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Auto Check-in',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Persistent Auto Check-in toggle (New improved version)
                  SwitchListTile(
                    title: Row(
                      children: [
                        const Text('Auto Check-In'),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Text(
                            'NEW',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Works in background even after restart'),
                        if (_autoCheckInStatus != null &&
                            _autoCheckInEnabled) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: _autoCheckInStatus!['enabled'] == true
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _autoCheckInStatus!['enabled'] == true
                                    ? 'Running in background'
                                    : 'Not running',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _autoCheckInStatus!['enabled'] == true
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    value: _autoCheckInEnabled,
                    onChanged: _toggleAutoCheckIn,
                  ),

                  // Status and debugging info
                  if (_autoCheckInEnabled && _autoCheckInStatus != null) ...[
                    const Divider(),
                    ListTile(
                      title: Row(
                        children: [
                          const Text('Service Status'),
                          if (_lastRefresh != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '(${_formatDateTime(_lastRefresh)})',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_autoCheckInStatus!['lastLocationCheck'] != null)
                            Text(
                              'Last check: ${_formatDateTime(_autoCheckInStatus!['lastLocationCheck'])}',
                            ),
                          if (_autoCheckInStatus!['lastAutoCheckIn'] != null)
                            Text(
                              'Last auto check-in: ${_formatDateTime(_autoCheckInStatus!['lastAutoCheckIn'])}',
                            ),
                          FutureBuilder<String>(
                            future:
                                LocationPermissionService.getPermissionStatusDescription(),
                            builder: (context, snapshot) {
                              final status = snapshot.data ?? 'Checking...';
                              final isIdeal =
                                  _autoCheckInStatus!['hasBackgroundPermission'] ==
                                  true;
                              return Text(
                                'Location: ${isIdeal ? '✅' : '⚠️'} $status',
                                style: TextStyle(
                                  color: isIdeal ? null : Colors.orange,
                                ),
                              );
                            },
                          ),
                          Text(
                            'Battery optimization: ${_autoCheckInStatus!['batteryOptimizationAsked'] == true ? 'Asked' : 'Not asked'}',
                          ),
                          if (_autoCheckInStatus!['error'] != null)
                            Text(
                              'Error: ${_autoCheckInStatus!['error']}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          if (_autoCheckInStatus!['hasBackgroundPermission'] !=
                              true)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.orange.shade900.withValues(
                                          alpha: 0.3,
                                        )
                                      : Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.orange.shade600
                                        : Colors.orange.shade200,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '💡 For best reliability:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color:
                                            Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.orange.shade300
                                            : Colors.orange.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '• Go to Settings > Apps > OfficeLog > Permissions\n'
                                      '• Set Location to "Allow all the time"',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.orange.shade100
                                            : Colors.orange.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        onPressed: _openAppPermissionSettings,
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          side: BorderSide(
                                            color:
                                                Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.orange.shade400
                                                : Colors.orange.shade600,
                                          ),
                                          foregroundColor:
                                              Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.orange.shade300
                                              : Colors.orange.shade700,
                                        ),
                                        child: const Text(
                                          'Open Permission Settings',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: _isRefreshing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh),
                        onPressed: _isRefreshing ? null : _refreshServiceStatus,
                      ),
                    ),

                    // Battery optimization settings
                    ListTile(
                      title: const Text('Battery Optimization'),
                      subtitle: const Text(
                        'Configure device settings for reliable background operation',
                      ),
                      trailing: const Icon(Icons.battery_saver),
                      onTap: () =>
                          BatteryOptimizationService.showManufacturerSpecificHelp(
                            context,
                          ),
                    ),
                  ],

                  // Test geofence
                  if (_autoCheckInEnabled)
                    ListTile(
                      title: const Text('Test Location'),
                      subtitle: const Text(
                        'Check if you\'re within office range',
                      ),
                      trailing: const Icon(Icons.location_searching),
                      onTap: _testGeofence,
                    ),

                  // Privacy note
                  if (_autoCheckInEnabled) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.blue.shade900.withValues(alpha: 0.3)
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.blue.shade600
                              : Colors.blue.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.privacy_tip,
                                size: 16,
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.blue.shade300
                                    : Colors.blue.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Privacy Information',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.blue.shade300
                                      : Colors.blue.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '• Location is only used to detect when you\'re near your office\n'
                            '• No location data is stored or shared with third parties\n'
                            '• You can disable this feature anytime in Settings',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.blue.shade100
                                  : Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Data Management Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Management',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sync offline data
                  Consumer<AttendanceProvider>(
                    builder: (context, attendanceProvider, child) {
                      return FutureBuilder<int>(
                        future: attendanceProvider.getOfflineAttendanceCount(),
                        builder: (context, snapshot) {
                          final offlineCount = snapshot.data ?? 0;
                          return ListTile(
                            title: const Text('Sync Offline Data'),
                            subtitle: Text(
                              offlineCount > 0
                                  ? '$offlineCount unsynced records'
                                  : 'All data synced',
                            ),
                            trailing: offlineCount > 0
                                ? const Icon(
                                    Icons.sync_problem,
                                    color: Colors.orange,
                                  )
                                : const Icon(Icons.sync, color: Colors.green),
                            onTap: offlineCount > 0
                                ? () async {
                                    final success = await attendanceProvider
                                        .forceSyncOfflineData();
                                    if (success && mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            'Data synced successfully',
                                          ),
                                          backgroundColor:
                                              AppThemes.getSuccessColor(
                                                context,
                                              ),
                                        ),
                                      );
                                    }
                                  }
                                : null,
                          );
                        },
                      );
                    },
                  ),

                  // Sync offline feedback
                  FutureBuilder<int>(
                    future: FeedbackService().getOfflineFeedbackCount(),
                    builder: (context, snapshot) {
                      final offlineFeedbackCount = snapshot.data ?? 0;

                      if (offlineFeedbackCount == 0) {
                        return const SizedBox.shrink();
                      }

                      return ListTile(
                        title: const Text('Sync Offline Feedback'),
                        subtitle: Text(
                          '$offlineFeedbackCount unsynced feedback',
                        ),
                        trailing: Icon(
                          Icons.feedback,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.orange.shade300
                              : Colors.orange.shade600,
                        ),
                        onTap: () async {
                          final feedbackService = FeedbackService();
                          final success = await feedbackService
                              .syncOfflineFeedback();

                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Feedback synced successfully',
                                ),
                                backgroundColor: AppThemes.getSuccessColor(
                                  context,
                                ),
                              ),
                            );
                            // Refresh the page to update the count
                            setState(() {});
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Failed to sync feedback'),
                                backgroundColor: AppThemes.getErrorColor(
                                  context,
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),

                  // Settings validation and backup
                  ListTile(
                    title: const Text('Settings Management'),
                    subtitle: const Text(
                      'Backup, restore, and validate settings',
                    ),
                    trailing: const Icon(Icons.settings_backup_restore),
                    onTap: _showSettingsManagement,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Theme Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appearance',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return SwitchListTile(
                        title: const Text('Dark Mode'),
                        subtitle: const Text('Use dark theme'),
                        value: themeProvider.isDarkMode,
                        onChanged: (value) => themeProvider.toggleTheme(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Support Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Support',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Feedback button
                  ListTile(
                    leading: Icon(
                      Icons.feedback,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.blue.shade300
                          : Theme.of(context).primaryColor,
                    ),
                    title: const Text(
                      'Feedback',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: const Text('Share your thoughts and suggestions'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => Navigator.of(context).pushNamed('/feedback'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Account Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Logout tile
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: const Text('Sign out of your account'),
                    onTap: _showLogoutConfirmation,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLogoutConfirmation() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _handleLogout();
    }
  }

  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();

    // Navigate to main route so AuthWrapper can handle the login redirect
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Never';

    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  Future<void> _showAutoCheckInSetupDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.green),
              SizedBox(width: 8),
              Text('Auto Check-In Setup'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Auto Check-In is now enabled! For the best experience:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 16),
              Text(
                '📍 Location Permission:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('• Already granted ✅'),
              SizedBox(height: 12),
              Text(
                '🔋 Battery Optimization:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('• Disable battery optimization for OfficeLog'),
              Text('• This ensures reliable background operation'),
              SizedBox(height: 12),
              Text(
                '📱 Background Location (Optional):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('• Go to Settings > Apps > OfficeLog > Permissions'),
              Text('• Set Location to "Allow all the time"'),
              Text('• This improves reliability when app is closed'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                BatteryOptimizationService.showManufacturerSpecificHelp(
                  context,
                );
              },
              child: const Text('Battery Settings'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSettingsManagement() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.settings_backup_restore),
              SizedBox(width: 8),
              Text('Settings Management'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.backup),
                title: const Text('Export Settings'),
                subtitle: const Text('Save settings to clipboard'),
                onTap: () {
                  Navigator.of(context).pop();
                  _exportSettings();
                },
              ),
              ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('Import Settings'),
                subtitle: const Text('Restore from clipboard'),
                onTap: () {
                  Navigator.of(context).pop();
                  _importSettings();
                },
              ),
              ListTile(
                leading: const Icon(Icons.verified),
                title: const Text('Validate Settings'),
                subtitle: const Text('Check settings integrity'),
                onTap: () {
                  Navigator.of(context).pop();
                  _validateSettings();
                },
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Settings Summary'),
                subtitle: const Text('View all current settings'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showSettingsSummary();
                },
              ),
              ListTile(
                leading: const Icon(Icons.restore_page, color: Colors.red),
                title: const Text('Reset All Settings'),
                subtitle: const Text('Reset to defaults'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showResetConfirmation();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportSettings() async {
    try {
      final settings = await SettingsPersistenceService.exportSettings();
      final settingsJson = settings.toString();

      // Copy to clipboard (simplified - in production you'd use clipboard package)
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Settings Exported'),
            content: SingleChildScrollView(child: SelectableText(settingsJson)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export settings: $e'),
            backgroundColor: AppThemes.getErrorColor(context),
          ),
        );
      }
    }
  }

  Future<void> _importSettings() async {
    // In production, you'd show a text input dialog or file picker
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Import settings feature - would show input dialog'),
        ),
      );
    }
  }

  Future<void> _validateSettings() async {
    try {
      final isValid = await SettingsPersistenceService.validateSettings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isValid
                  ? '✅ All settings are valid'
                  : '⚠️ Some settings were corrected',
            ),
            backgroundColor: isValid
                ? AppThemes.getSuccessColor(context)
                : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Settings validation failed: $e'),
            backgroundColor: AppThemes.getErrorColor(context),
          ),
        );
      }
    }
  }

  Future<void> _showSettingsSummary() async {
    try {
      final summary = await SettingsPersistenceService.getSettingsSummary();

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Settings Summary'),
            content: SingleChildScrollView(
              child: SelectableText(
                summary,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get settings summary: $e'),
            backgroundColor: AppThemes.getErrorColor(context),
          ),
        );
      }
    }
  }

  Future<void> _showResetConfirmation() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Settings'),
        content: const Text(
          'This will reset all settings to their default values. '
          'Auto check-in will be disabled and you\'ll need to reconfigure everything.\n\n'
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset All'),
          ),
        ],
      ),
    );

    if (shouldReset == true) {
      try {
        // Stop all services first
        await PersistentBackgroundService.stopAutoCheckIn();
        await NotificationService.cancelAllNotifications();

        // Reset all settings
        await SettingsPersistenceService.resetAllSettings();

        // Reload the settings screen
        await _loadSettings();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✅ All settings have been reset to defaults'),
              backgroundColor: AppThemes.getSuccessColor(context),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to reset settings: $e'),
              backgroundColor: AppThemes.getErrorColor(context),
            ),
          );
        }
      }
    }
  }

  Future<void> _openAppPermissionSettings() async {
    if (!Platform.isAndroid) return;

    try {
      // Open the app's specific permission settings page
      const AndroidIntent intent = AndroidIntent(
        action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
        data: 'package:com.matrimpathak.attendence_flutter',
      );
      await intent.launch();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open settings: $e'),
            backgroundColor: AppThemes.getErrorColor(context),
          ),
        );
      }
    }
  }

  Future<void> _testGeofence() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Testing location...'),
          ],
        ),
      ),
    );

    try {
      final geolocationService = GeolocationService();
      final result = await geolocationService.testGeofence();

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Location Test Result'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (result['success']) ...[
                  Text(
                    'Distance to office: ${(result['distance'] as double).toStringAsFixed(0)}m',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result['withinRange']
                        ? '✅ Within office range'
                        : '❌ Outside office range',
                    style: TextStyle(
                      color: result['withinRange'] ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (result['canAutoCheckIn'])
                    const Text('\n🎯 Auto check-in available'),
                ] else
                  Text('Error: ${result['error']}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test failed: $e'),
            backgroundColor: AppThemes.getErrorColor(context),
          ),
        );
      }
    }
  }
}
