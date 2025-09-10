import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/notification_service.dart';
import '../services/geolocation_service.dart';
import '../services/simple_background_geofence_service.dart';
import '../services/feedback_service.dart';
import '../themes/app_themes.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  TimeOfDay? _reminderTime;
  bool _reminderEnabled = false;
  bool _geofenceEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final reminderTime = await NotificationService.getReminderTime();
      final reminderEnabled = await NotificationService.isReminderEnabled();
      final geofenceEnabled =
          await SimpleBackgroundGeofenceService.isMonitoring();

      setState(() {
        _reminderTime = TimeOfDay(
          hour: reminderTime['hour']!,
          minute: reminderTime['minute']!,
        );
        _reminderEnabled = reminderEnabled;
        _geofenceEnabled = geofenceEnabled;
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

  Future<void> _toggleGeofence(bool enabled) async {
    try {
      if (enabled) {
        // Request permissions first
        final hasPermission =
            await GeolocationService.requestLocationPermissions();
        if (!hasPermission) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Location permission is required for background geofencing',
                ),
                backgroundColor: AppThemes.getErrorColor(context),
              ),
            );
          }
          return;
        }

        final success = await SimpleBackgroundGeofenceService.startMonitoring();
        if (!success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Failed to start background geofencing. Please check permissions.',
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
        await SimpleBackgroundGeofenceService.stopMonitoring();
      }

      setState(() {
        _geofenceEnabled = enabled;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled
                  ? 'Background auto check-in enabled'
                  : 'Background auto check-in disabled',
            ),
            backgroundColor: AppThemes.getSuccessColor(context),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update geofence: $e'),
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
                      _geofenceEnabled
                          ? 'Disabled when auto check-in is enabled'
                          : 'Get reminded to log attendance',
                    ),
                    value: _reminderEnabled && !_geofenceEnabled,
                    onChanged: _geofenceEnabled ? null : _toggleReminder,
                  ),

                  // Reminder time
                  if (_reminderEnabled && !_geofenceEnabled)
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

                  // Geofence toggle
                  SwitchListTile(
                    title: const Text('Background Auto Check-in'),
                    subtitle: const Text(
                      'Automatically log attendance when entering office area (works in background)',
                    ),
                    value: _geofenceEnabled,
                    onChanged: _toggleGeofence,
                  ),

                  // Test geofence
                  if (_geofenceEnabled)
                    ListTile(
                      title: const Text('Test Location'),
                      subtitle: const Text(
                        'Check if you\'re within office range',
                      ),
                      trailing: const Icon(Icons.location_searching),
                      onTap: _testGeofence,
                    ),
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
                        trailing: const Icon(
                          Icons.feedback,
                          color: Colors.orange,
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
                      color: Theme.of(context).primaryColor,
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
