import 'package:flutter/material.dart';

import 'core/services/settings_service.dart';
import 'features/navigation/main_navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // REQUIRED: prevents "SettingsService not initialized" red screen
  await SettingsService.init();

  runApp(const ScanXApp());
}

class ScanXApp extends StatelessWidget {
  const ScanXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SCAN-X',
      debugShowCheckedModeBanner: false,

      // Force the “second screenshot” light look
      themeMode: ThemeMode.light,
      theme: _buildLightTheme(),

      // Your app shell (tabs)
      home: const MainNavigation(),
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
    cardTheme: base.cardTheme.copyWith(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.black.withOpacity(0.10)),
      ),
    ),
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
    textTheme: base.textTheme.apply(
      bodyColor: const Color(0xFF121417),
      displayColor: const Color(0xFF121417),
    ),
    bottomNavigationBarTheme: base.bottomNavigationBarTheme.copyWith(
      backgroundColor: const Color(0xFFF7F8FA),
      selectedItemColor: primary,
      unselectedItemColor: Colors.black54,
    ),
    dividerTheme: base.dividerTheme.copyWith(
      color: Colors.black.withOpacity(0.08),
      thickness: 1,
    ),
  );
}
