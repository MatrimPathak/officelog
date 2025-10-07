import 'package:flutter/material.dart';

class AppThemes {
  // Light Theme Colors
  static const Color lightPrimary = Color(0xFF1565C0);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightPrimaryContainer = Color(0xFFE3F2FD);
  static const Color lightOnPrimaryContainer = Color(0xFF0D47A1);
  static const Color lightSecondary = Color(0xFF00897B);
  static const Color lightOnSecondary = Color(0xFFFFFFFF);
  static const Color lightBackground = Color(0xFFF6F7FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightOnSurface = Color(0xFF0B1A2B);
  static const Color lightError = Color(0xFFD32F2F);
  static const Color lightSuccess = Color(0xFF2E7D32);
  static const Color lightAccent = Color(0xFFFFC107);
  static const Color lightMuted = Color(0xFF9E9E9E);

  // Dark Theme Colors
  static const Color darkPrimary = Color(0xFF4F8FEF);
  static const Color darkOnPrimary = Color(0xFFFFFFFF);
  static const Color darkPrimaryContainer = Color(0xFF1A237E);
  static const Color darkOnPrimaryContainer = Color(0xFFBBDEFB);
  static const Color darkSecondary = Color(0xFF4DB6A6);
  static const Color darkOnSecondary = Color(0xFFFFFFFF);
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkOnSurface = Color(0xFFE6EEF9);
  static const Color darkError = Color(0xFFEF5350);
  static const Color darkSuccess = Color(0xFF66BB6A);
  static const Color darkAccent = Color(0xFFFFD54F);
  static const Color darkMuted = Color(0xFF757575);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: lightPrimary,
        onPrimary: lightOnPrimary,
        primaryContainer: lightPrimaryContainer,
        onPrimaryContainer: lightOnPrimaryContainer,
        secondary: lightSecondary,
        onSecondary: lightOnSecondary,
        surface: lightSurface,
        onSurface: lightOnSurface,
        error: lightError,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: lightSurface,
        foregroundColor: lightOnSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: lightPrimary,
        foregroundColor: lightOnPrimary,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: darkPrimary,
        onPrimary: darkOnPrimary,
        primaryContainer: Color(0xFF1A237E),
        onPrimaryContainer: Color(0xFFBBDEFB),
        secondary: darkSecondary,
        onSecondary: darkOnSecondary,
        surface: darkSurface,
        onSurface: darkOnSurface,
        error: darkError,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: darkSurface,
        foregroundColor: darkOnSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: darkPrimary,
        foregroundColor: darkOnPrimary,
      ),
    );
  }

  // Helper methods to get theme-aware colors
  static Color getSuccessColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSuccess
        : lightSuccess;
  }

  static Color getAccentColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkAccent
        : lightAccent;
  }

  static Color getMutedColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkMuted
        : lightMuted;
  }

  static Color getErrorColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkError
        : lightError;
  }
}
