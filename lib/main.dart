import 'package:flutter/material.dart';

import 'core/services/settings_service.dart';
import 'features/navigation/main_navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService.init();
  runApp(const ScanXApp());
}

class ScanXApp extends StatelessWidget {
  const ScanXApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService();

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: settings.themeModeListenable,
      builder: (context, mode, _) {
        final isScanXDark = settings.appThemeIndex == 3;

        return MaterialApp(
          title: 'SCAN-X',
          debugShowCheckedModeBanner: false,

          themeMode: mode,
          theme: _buildLightTheme(),
          darkTheme: isScanXDark ? _buildScanXDarkTheme() : _buildDarkTheme(),

          home: const MainNavigation(),
        );
      },
    );
  }
}

ThemeData _buildLightTheme() {
  const primary = Color(0xFF1ECB7B);

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
      foregroundColor: Colors.black,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: const TextStyle(
        color: Colors.black,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        side: BorderSide(color: Color(0x1A000000)), // ~10% black
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

ThemeData _buildDarkTheme() {
  const primary = Color(0xFF1ECB7B);

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

ThemeData _buildScanXDarkTheme() {
  return _buildDarkTheme().copyWith(
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
