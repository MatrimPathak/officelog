import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../core/logger/app_logger.dart';

/// Enhanced location permission service with better error handling
/// Provides fallback mechanisms for permission handling issues
class LocationPermissionService {
  /// Check if location permissions are sufficient for auto check-in
  static Future<bool> hasLocationPermissions() async {
    try {
      // First check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Removed malformed log call
        return false;
      }

      // Check permission using Geolocator (more reliable)
      LocationPermission permission = await Geolocator.checkPermission();

      final hasPermission =
          permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;

      // Removed malformed log call
      return hasPermission;
    } catch (e) {
      // Removed malformed log call
      return false;
    }
  }

  /// Request location permissions with graceful fallback
  static Future<bool> requestLocationPermissions() async {
    try {
      // Check if location service is enabled first
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Removed malformed log call
        return false;
      }

      // Request permission using Geolocator first (most reliable)
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Removed malformed log call
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Removed malformed log call
        return false;
      }

      // Try to get background permission if we only have whileInUse
      if (permission == LocationPermission.whileInUse) {
        final backgroundGranted = await _tryRequestBackgroundPermission();
        if (backgroundGranted) {
          // Removed malformed log call
          return true;
        } else {
          // Removed malformed log call
          // Still return true - whileInUse is sufficient for basic functionality
          return true;
        }
      }

      // Removed malformed log call
      return true;
    } catch (e) {
      // Removed malformed log call
      return false;
    }
  }

  /// Try to request background permission with error handling
  static Future<bool> _tryRequestBackgroundPermission() async {
    try {
      // Instead of using permission_handler, we'll guide the user to settings
      AppLogger.info('Background permission requires manual setup in Android settings', tag: 'LocationPermissionService');
      return false; // Return false to indicate background permission not available
    } catch (e) {
      // Removed malformed log call
      return false;
    }
  }

  /// Check if we have the ideal permissions (including background)
  static Future<bool> hasIdealPermissions() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      LocationPermission permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always;
    } catch (e) {
      // Removed malformed log call
      return false;
    }
  }

  /// Get permission status description for UI
  static Future<String> getPermissionStatusDescription() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return 'Location service disabled';
      }

      LocationPermission permission = await Geolocator.checkPermission();

      switch (permission) {
        case LocationPermission.always:
          return 'Background location access granted';
        case LocationPermission.whileInUse:
          return 'Location access granted (foreground only)';
        case LocationPermission.denied:
          return 'Location permission denied';
        case LocationPermission.deniedForever:
          return 'Location permission permanently denied';
        case LocationPermission.unableToDetermine:
          return 'Unable to determine location permission';
      }
    } catch (e) {
      return 'Error checking permissions: $e';
    }
  }

  /// Show permission explanation dialog
  static Future<bool> showPermissionExplanationDialog(
    BuildContext context,
  ) async {
    final bool? userAccepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue),
              SizedBox(width: 8),
              Text('Location Permission'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OfficeLog needs location access to automatically detect when you arrive at your office.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'How it works:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Detects when you\'re within your office area'),
              Text('• Automatically logs your attendance'),
              Text('• Works in the background for convenience'),
              SizedBox(height: 16),
              Text(
                'Your privacy:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Location is only used for office proximity detection'),
              Text('• No location data is stored or shared'),
              Text('• You can disable this feature anytime'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not Now'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Allow Location'),
            ),
          ],
        );
      },
    );

    return userAccepted ?? false;
  }
}
