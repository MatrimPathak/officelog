import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Service to handle battery optimization bypass for reliable background operation
class BatteryOptimizationService {
  static const MethodChannel _channel = MethodChannel('battery_optimization');

  /// Check if the app is whitelisted from battery optimization
  static Future<bool> isIgnoringBatteryOptimizations() async {
    if (!Platform.isAndroid) return true; // iOS doesn't have this concept

    try {
      final bool? result = await _channel.invokeMethod(
        'isIgnoringBatteryOptimizations',
      );
      return result ?? false;
    } catch (e) {
      debugPrint('Error checking battery optimization status: $e');
      // Return true to avoid blocking the user if we can't check
      return true;
    }
  }

  /// Request to ignore battery optimizations
  static Future<bool> requestIgnoreBatteryOptimizations() async {
    if (!Platform.isAndroid) return true;

    try {
      // Use Android Intent to open battery optimization settings
      final AndroidIntent intent = AndroidIntent(
        action: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
        data:
            'package:com.example.attendence_flutter', // Replace with your actual package name
      );

      await intent.launch();
      return true;
    } catch (e) {
      debugPrint('Error requesting battery optimization bypass: $e');

      // Fallback: Open general battery optimization settings
      try {
        final AndroidIntent fallbackIntent = AndroidIntent(
          action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
        );
        await fallbackIntent.launch();
        return true;
      } catch (fallbackError) {
        debugPrint('Error with fallback intent: $fallbackError');
        return false;
      }
    }
  }

  /// Show battery optimization dialog to user
  static Future<bool> showBatteryOptimizationDialog(
    BuildContext context,
  ) async {
    if (!Platform.isAndroid) return true;

    // Check if already whitelisted (with error handling)
    try {
      if (await isIgnoringBatteryOptimizations()) {
        return true;
      }
    } catch (e) {
      debugPrint('Could not check battery optimization status: $e');
      // Continue to show dialog anyway
    }

    final bool? userAccepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.battery_alert, color: Colors.orange),
              SizedBox(width: 8),
              Text('Battery Optimization'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To keep Auto Check-In working reliably in the background, OfficeLog needs to bypass battery optimization.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'What this means:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Auto check-in will work even when your phone is idle'),
              Text('• Location monitoring continues in the background'),
              Text('• Attendance logging remains reliable'),
              SizedBox(height: 16),
              Text(
                'Your privacy:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Location is only used for office proximity detection'),
              Text('• No location data is stored or shared'),
              Text('• You can disable this feature anytime in Settings'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Allow'),
            ),
          ],
        );
      },
    );

    if (userAccepted == true) {
      return await requestIgnoreBatteryOptimizations();
    }

    return false;
  }

  /// Get device manufacturer for manufacturer-specific battery optimization settings
  static Future<String> getDeviceManufacturer() async {
    try {
      if (!Platform.isAndroid) return 'unknown';

      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.manufacturer.toLowerCase();
    } catch (e) {
      debugPrint('Error getting device manufacturer: $e');
      // Return 'android' as a safe fallback instead of 'unknown'
      return 'android';
    }
  }

  /// Open manufacturer-specific battery optimization settings
  static Future<void> openManufacturerBatterySettings() async {
    if (!Platform.isAndroid) return;

    final manufacturer = await getDeviceManufacturer();

    try {
      AndroidIntent? intent;

      switch (manufacturer) {
        case 'xiaomi':
          intent = const AndroidIntent(
            action: 'miui.intent.action.OP_AUTO_START',
            data: 'package:com.example.attendence_flutter',
          );
          break;
        case 'huawei':
          intent = const AndroidIntent(
            action: 'huawei.intent.action.HSM_PROTECTED_APPS',
          );
          break;
        case 'oppo':
          intent = const AndroidIntent(
            action: 'com.oppo.safecenter',
            componentName: 'com.oppo.safecenter/.autostart.AutoStartActivity',
          );
          break;
        case 'vivo':
          intent = const AndroidIntent(
            action: 'com.vivo.permissionmanager',
            componentName:
                'com.vivo.permissionmanager/.activity.BgStartUpManagerActivity',
          );
          break;
        case 'samsung':
          intent = const AndroidIntent(
            action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
            data: 'package:com.example.attendence_flutter',
          );
          break;
        default:
          // Default to general battery optimization settings
          intent = const AndroidIntent(
            action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
          );
      }

      await intent.launch();
    } catch (e) {
      debugPrint('Error opening manufacturer battery settings: $e');

      // Fallback to general settings
      try {
        const AndroidIntent fallbackIntent = AndroidIntent(
          action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
        );
        await fallbackIntent.launch();
      } catch (fallbackError) {
        debugPrint('Error with fallback manufacturer settings: $fallbackError');
      }
    }
  }

  /// Show help dialog with manufacturer-specific instructions
  static Future<void> showManufacturerSpecificHelp(BuildContext context) async {
    final manufacturer = await getDeviceManufacturer();

    String instructions = _getManufacturerInstructions(manufacturer);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${_capitalizeFirst(manufacturer)} Battery Settings'),
          content: SingleChildScrollView(child: Text(instructions)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openManufacturerBatterySettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  static String _getManufacturerInstructions(String manufacturer) {
    switch (manufacturer) {
      case 'xiaomi':
        return '''For MIUI (Xiaomi/Redmi):
1. Open "Settings" → "Apps" → "Manage apps"
2. Find "OfficeLog" in the list
3. Tap on "Battery saver" → Choose "No restrictions"
4. Go back and tap "Autostart" → Enable for OfficeLog
5. Also check "Other permissions" → Enable "Display pop-up windows while running in background"''';

      case 'huawei':
        return '''For EMUI (Huawei):
1. Open "Settings" → "Battery" → "App launch"
2. Find "OfficeLog" and toggle it ON
3. Choose "Manage manually"
4. Enable "Auto-launch", "Secondary launch", and "Run in background"
5. Go to "Settings" → "Apps" → "OfficeLog" → "Battery" → "App launch" → Enable''';

      case 'oppo':
        return '''For ColorOS (OPPO):
1. Open "Settings" → "Battery" → "Battery Optimization"
2. Find "OfficeLog" and select "Don't optimize"
3. Go to "Settings" → "Privacy & Security" → "Startup Manager"
4. Enable "OfficeLog" to allow auto-start
5. Also check "Settings" → "Battery" → "Power Saving Mode" → Disable for better performance''';

      case 'vivo':
        return '''For FunTouch OS (Vivo):
1. Open "Settings" → "Battery" → "Battery Optimization"
2. Find "OfficeLog" and select "Don't optimize"
3. Go to "Settings" → "More Settings" → "Applications" → "Autostart"
4. Enable "OfficeLog"
5. Check "Settings" → "Battery" → "Background App Refresh" → Enable for OfficeLog''';

      case 'samsung':
        return '''For One UI (Samsung):
1. Open "Settings" → "Apps" → "OfficeLog"
2. Tap "Battery" → "Optimize battery usage"
3. Change from "Optimize" to "Don't optimize"
4. Go back to app settings → "Permissions" → "Location" → Choose "Allow all the time"
5. Check "Settings" → "Device care" → "Battery" → "App power management" → Add OfficeLog to "Apps that won't be put to sleep"''';

      default:
        return '''For your device:
1. Open Android Settings → "Battery" → "Battery Optimization"
2. Find "OfficeLog" in the list and select "Don't optimize"
3. Go to "Apps" → "OfficeLog" → "Battery" → "Background Activity" → Enable
4. Check "Location" permissions are set to "Allow all the time"
5. Look for any "Auto-start" or "Background app refresh" settings and enable them for OfficeLog''';
    }
  }

  static String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
