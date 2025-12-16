import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF1ECB7B);

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF7F8FA),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: const Color(0xFFF7F8FA),
        foregroundColor: const Color(0xFF121417),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: Color(0xFF121417),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          side: BorderSide(color: Color(0x1A000000)), // 10% black
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x14000000),
        thickness: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFFF7F8FA),
        selectedItemColor: primary,
        unselectedItemColor: Colors.black54,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: const Color(0xFF121417),
        displayColor: const Color(0xFF121417),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF0B0D10),
      cardTheme: const CardThemeData(
        color: Color(0xFF111318),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          side: BorderSide(color: Color(0xFF22252F)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0B0D10),
        selectedItemColor: primary,
        unselectedItemColor: Colors.white60,
      ),
    );
  }

  static ThemeData scanXDark() {
    return dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF07090C),
      cardTheme: const CardThemeData(
        color: Color(0xFF0F1216),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          side: BorderSide(color: Color(0xFF1E2330)),
        ),
      ),
    );
  }
}
