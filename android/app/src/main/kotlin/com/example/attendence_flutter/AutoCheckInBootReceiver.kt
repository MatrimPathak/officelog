package com.example.attendence_flutter

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

/**
 * Boot receiver to restart auto check-in service after device reboot
 */
class AutoCheckInBootReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "AutoCheckInBootReceiver"
        private const val CHANNEL = "auto_checkin_boot"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "Boot receiver triggered: ${intent.action}")
        
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            "android.intent.action.QUICKBOOT_POWERON",
            "com.htc.intent.action.QUICKBOOT_POWERON" -> {
                Log.d(TAG, "Device boot completed - checking auto check-in status")
                
                try {
                    // Check if auto check-in was enabled before reboot
                    val sharedPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    val autoCheckInEnabled = sharedPrefs.getBoolean("flutter.auto_checkin_enabled", false)
                    
                    if (autoCheckInEnabled) {
                        Log.d(TAG, "Auto check-in was enabled - restarting service")
                        
                        // Start the Flutter engine to restart the WorkManager task
                        restartAutoCheckInService(context)
                    } else {
                        Log.d(TAG, "Auto check-in was not enabled - no action needed")
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error in boot receiver: ${e.message}", e)
                }
            }
        }
    }
    
    private fun restartAutoCheckInService(context: Context) {
        try {
            // Create a Flutter engine to execute Dart code
            val flutterEngine = FlutterEngine(context)
            
            // Start the Dart isolate
            flutterEngine.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault()
            )
            
            // Set up method channel to communicate with Flutter
            val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            
            // Call Flutter method to restart auto check-in service
            methodChannel.invokeMethod("restartAutoCheckIn", null, object : MethodChannel.Result {
                override fun success(result: Any?) {
                    Log.d(TAG, "Auto check-in service restarted successfully")
                    flutterEngine.destroy()
                }
                
                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                    Log.e(TAG, "Failed to restart auto check-in service: $errorMessage")
                    flutterEngine.destroy()
                }
                
                override fun notImplemented() {
                    Log.w(TAG, "Method not implemented in Flutter")
                    flutterEngine.destroy()
                }
            })
            
        } catch (e: Exception) {
            Log.e(TAG, "Error restarting auto check-in service: ${e.message}", e)
        }
    }
}
