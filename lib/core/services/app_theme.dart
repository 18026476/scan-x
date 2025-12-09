import 'package:flutter/material.dart';

/// Central SCAN-X theme configuration.
class AppTheme {
  AppTheme._();

  // Brand accent colour
  static const Color _seedColor = Color(0xFF1ECB7B);

  // Dark + light colour schemes with matching brightness
  static final ColorScheme _darkScheme = ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: Brightness.dark,
  );

  static final ColorScheme _lightScheme = ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: Brightness.light,
  );

  /// Main dark theme used by the app.
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        colorScheme: _darkScheme,
        // IMPORTANT: do NOT set brightness separately here.
        scaffoldBackgroundColor: const Color(0xFF050608),
        canvasColor: const Color(0xFF050608),
        cardColor: const Color(0xFF111111),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF050608),
          foregroundColor: _darkScheme.onSurface,
          elevation: 0,
          centerTitle: true,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF111111),
          contentTextStyle: const TextStyle(color: Colors.white),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: const Color(0xFF050608),
          selectedItemColor: _seedColor,
          unselectedItemColor: Colors.grey[500],
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
        ),
      );

  /// Optional light theme (if you ever enable ThemeMode.system etc.).
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: _lightScheme,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[50],
          foregroundColor: _lightScheme.onSurface,
          elevation: 0,
          centerTitle: true,
        ),
      );

  /// Default theme some older code may call.
  static ThemeData get theme => darkTheme;
}
