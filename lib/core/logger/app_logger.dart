import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Log levels for the application
enum LogLevel { debug, info, warning, error, critical }

/// Centralized logging utility for OfficeLog app
///
/// Provides structured logging with timestamps, levels, and tags.
/// Automatically disabled in release builds for performance.
///
/// Usage:
/// ```dart
/// AppLogger.info("User signed in", tag: "AuthService");
/// AppLogger.error("Firebase write failed", tag: "AttendanceService");
/// ```
class AppLogger {
  // Private constructor to prevent instantiation
  AppLogger._();

  /// ANSI color codes for console output (debug mode only)
  static const Map<LogLevel, String> _colors = {
    LogLevel.debug: '\x1B[34m', // Blue
    LogLevel.info: '\x1B[32m', // Green
    LogLevel.warning: '\x1B[33m', // Yellow
    LogLevel.error: '\x1B[31m', // Red
    LogLevel.critical: '\x1B[35m', // Magenta
  };

  /// Reset ANSI color code
  static const String _resetColor = '\x1B[0m';

  /// Log level names for display
  static const Map<LogLevel, String> _levelNames = {
    LogLevel.debug: 'DEBUG',
    LogLevel.info: 'INFO',
    LogLevel.warning: 'WARN',
    LogLevel.error: 'ERROR',
    LogLevel.critical: 'CRITICAL',
  };

  /// Internal logging method
  static void _log(LogLevel level, String message, {String? tag}) {
    // Skip logging in release mode for performance
    if (kReleaseMode) return;

    // Format timestamp
    final now = DateTime.now();
    final timestamp =
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}.'
        '${now.millisecond.toString().padLeft(3, '0')}';

    // Format level name
    final levelName = _levelNames[level]!;

    // Format tag
    final tagStr = tag != null ? '[$tag]' : '';

    // Build log message
    final logMessage = '[$timestamp] [$levelName] $tagStr $message';

    // Add color in debug mode
    final coloredMessage = kDebugMode
        ? '${_colors[level]}$logMessage$_resetColor'
        : logMessage;

    // Output to console
    if (kDebugMode) {
      // Use developer.log for better integration with Flutter DevTools
      developer.log(
        message,
        time: now,
        level: _getLogLevelValue(level),
        name: tag ?? 'OfficeLog',
      );

      // Also print to console for immediate visibility
      print(coloredMessage);
    }

    // Forward critical errors to remote logging (placeholder)
    if (level == LogLevel.error || level == LogLevel.critical) {
      _forwardToRemoteLogging(level, message, tag);
    }
  }

  /// Get numeric log level for developer.log
  static int _getLogLevelValue(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
      case LogLevel.critical:
        return 1200;
    }
  }

  /// Placeholder for remote logging integration
  static void _forwardToRemoteLogging(
    LogLevel level,
    String message,
    String? tag,
  ) {
    // TODO: Integrate with Firebase Crashlytics or Sentry
    // Example:
    // if (level == LogLevel.critical) {
    //   FirebaseCrashlytics.instance.recordError(message, null);
    // }
  }

  // Public logging methods

  /// Log debug information (development details)
  ///
  /// Use for detailed information that is only of interest when diagnosing problems.
  ///
  /// Example:
  /// ```dart
  /// AppLogger.debug("Fetched 5 records from Firestore", tag: "DataService");
  /// ```
  static void debug(String message, {String? tag}) {
    _log(LogLevel.debug, message, tag: tag);
  }

  /// Log informational messages (expected events)
  ///
  /// Use for general information about app flow and expected operations.
  ///
  /// Example:
  /// ```dart
  /// AppLogger.info("User signed in successfully", tag: "AuthService");
  /// ```
  static void info(String message, {String? tag}) {
    _log(LogLevel.info, message, tag: tag);
  }

  /// Log warning messages (suspicious but not error state)
  ///
  /// Use for potentially harmful situations that don't prevent app operation.
  ///
  /// Example:
  /// ```dart
  /// AppLogger.warning("Token will expire soon", tag: "AuthService");
  /// ```
  static void warning(String message, {String? tag}) {
    _log(LogLevel.warning, message, tag: tag);
  }

  /// Log error messages (failed operations)
  ///
  /// Use for error events that might still allow the app to continue running.
  ///
  /// Example:
  /// ```dart
  /// AppLogger.error("Failed to update attendance: $e", tag: "AttendanceService");
  /// ```
  static void error(String message, {String? tag}) {
    _log(LogLevel.error, message, tag: tag);
  }

  /// Log critical messages (app-breaking issues)
  ///
  /// Use for very severe error events that will presumably lead the app to abort.
  ///
  /// Example:
  /// ```dart
  /// AppLogger.critical("Uncaught exception: $error", tag: "GlobalErrorHandler");
  /// ```
  static void critical(String message, {String? tag}) {
    _log(LogLevel.critical, message, tag: tag);
  }

  /// Utility method to log exceptions with stack trace
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   // some operation
  /// } catch (e, stackTrace) {
  ///   AppLogger.exception(e, stackTrace, tag: "ServiceName");
  /// }
  /// ```
  static void exception(
    dynamic exception,
    StackTrace? stackTrace, {
    String? tag,
    LogLevel level = LogLevel.error,
  }) {
    final message =
        'Exception: $exception${stackTrace != null ? '\nStack trace: $stackTrace' : ''}';
    _log(level, message, tag: tag);
  }

  /// Log method entry (debug level)
  ///
  /// Useful for tracing method calls during debugging.
  ///
  /// Example:
  /// ```dart
  /// AppLogger.methodEntry("signIn", tag: "AuthService");
  /// ```
  static void methodEntry(String methodName, {String? tag}) {
    debug("→ Entering $methodName", tag: tag);
  }

  /// Log method exit (debug level)
  ///
  /// Useful for tracing method calls during debugging.
  ///
  /// Example:
  /// ```dart
  /// AppLogger.methodExit("signIn", tag: "AuthService");
  /// ```
  static void methodExit(String methodName, {String? tag}) {
    debug("← Exiting $methodName", tag: tag);
  }
}
