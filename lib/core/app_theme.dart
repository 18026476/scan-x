import 'package:flutter/material.dart';

/// Central SCAN-X theme configuration.
class AppTheme {
  AppTheme._();

  // Brand accent colour
  static const Color _seedColor = Color(0xFF1ECB7B);

  // Dark and light color schemes whose brightness matches their use
  static final ColorScheme _darkScheme = ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: Brightness.dark,
  );

  static final ColorScheme _lightScheme = ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: Brightness.light,
  );

  /// Main dark theme for the app.
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: _darkScheme,
    // Do NOT set brightness separately – it comes from the colorScheme.
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

  /// Optional light theme (if you ever want system / light mode).
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

  /// Backwards-compat entry some older code may call.
  static ThemeData get theme => darkTheme;
}
