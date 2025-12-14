import 'package:flutter/material.dart';
import 'package:scanx_app/core/services/settings_service.dart';
import 'package:scanx_app/core/services/services.dart';
import 'package:scanx_app/core/theme/app_theme.dart';
import 'package:scanx_app/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise global settings singleton
  settingsService = await SettingsService.create();

  runApp(const ScanXApp());
}

class ScanXApp extends StatelessWidget {
  const ScanXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SCAN-X Cyber Labs',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settingsService.themeMode,
      home: const HomeShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}