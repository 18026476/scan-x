import 'package:flutter/material.dart';

import 'core/services/app_theme.dart';
import 'features/navigation/main_navigation.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ScanXApp());
}

class ScanXApp extends StatelessWidget {
  const ScanXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SCAN-X',
      debugShowCheckedModeBanner: false,
      // Always dark for now – you can change to ThemeMode.system later if you want.
      themeMode: ThemeMode.dark,
      theme: AppTheme.lightTheme,   // used if you ever switch to light
      darkTheme: AppTheme.darkTheme,
      home: const MainNavigation(),
    );
  }
}
