// lib/features/navigation/main_navigation.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scanx_app/core/services/post_scan_pipeline.dart';
import 'package:scanx_app/core/services/scan_service.dart';
import 'package:scanx_app/core/services/settings_service.dart';
import 'package:scanx_app/core/services/two_factor_service.dart';
import 'package:scanx_app/core/services/two_factor_store.dart';
import 'package:scanx_app/core/services/update_service.dart';
import 'package:scanx_app/core/services/windows_startup_service.dart';
import 'package:scanx_app/features/dashboard/dashboard_screen.dart';
import 'package:scanx_app/features/devices/devices_screen.dart';
import 'package:scanx_app/features/scan/scan_screen.dart';
import 'package:scanx_app/features/settings/settings_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  Timer? _autoScanTimer;
  int _currentIndex = 0;

  final List<Widget> _pages = const <Widget>[
    DashboardScreen(),
    ScanScreen(),
    DevicesScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _enforceTwoFactorIfEnabled();
      await _applyWindowsStartupSetting();
      await _runAutoScanOnLaunchIfEnabled();
      await _checkForUpdatesIfEnabled();
    });

    _startContinuousMonitoringIfEnabled();
  }

  void _startContinuousMonitoringIfEnabled() {
    final s = SettingsService();
    if (!s.continuousMonitoring) return;

    final minutes = _scanFrequencyMinutes(s.scanFrequency);
    if (minutes <= 0) return;

    _autoScanTimer?.cancel();
    _autoScanTimer = Timer.periodic(Duration(minutes: minutes), (_) async {
      try {
        final r = await ScanService().runQuickSmartScanFromDefaults();
        if (!mounted) return;
        await PostScanPipeline.handleScanComplete(
          context,
          result: r,
          isAutoScan: true,
        );
      } catch (_) {}
    });
  }

  int _scanFrequencyMinutes(int idx) {
    // 0=on-demand, 1=every 15m, 2=hourly, 3=daily
    switch (idx) {
      case 1:
        return 15;
      case 2:
        return 60;
      case 3:
        return 1440;
      default:
        return 0;
    }
  }

  Future<void> _runAutoScanOnLaunchIfEnabled() async {
    final s = SettingsService();
    if (!s.autoScanOnLaunch) return;

    try {
      final r = await ScanService().runQuickSmartScanFromDefaults();
      if (!mounted) return;
      await PostScanPipeline.handleScanComplete(
        context,
        result: r,
        isAutoScan: true,
      );
    } catch (_) {}
  }

  Future<void> _applyWindowsStartupSetting() async {
    final s = SettingsService();
    try {
      if (s.autoStartOnBoot) {
        await WindowsStartupService.enable();
      } else {
        await WindowsStartupService.disable();
      }
    } catch (_) {}
  }

  Future<void> _checkForUpdatesIfEnabled() async {
    final s = SettingsService();
    if (!s.autoUpdateApp) return;

    try {
      await UpdateService.checkAndHandleUpdate(
        context,
        promptUser: s.notifyBeforeUpdate,
        useBetaChannel: s.betaUpdates,
      );
    } catch (_) {}
  }

  Future<void> _enforceTwoFactorIfEnabled() async {
    final enabled = await TwoFactorStore.isEnabled();
    if (!enabled) return;

    final secret = await TwoFactorService.ensureSecretExists();

    final until = await TwoFactorStore.getVerifiedUntil();
    if (until != null && until.isAfter(DateTime.now())) return;

    if (!mounted) return;

    if (secret.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Two-factor setup'),
          content: SelectableText(
            'Add this secret to an authenticator app (TOTP):\n\n$secret\n\n'
            'Then enter a 6-digit code to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }

    final ok = await TwoFactorService.promptForCode(context);
    if (ok) {
      await TwoFactorStore.setVerifiedUntil(
        DateTime.now().add(const Duration(hours: 12)),
      );
    }
  }

  @override
  void dispose() {
    _autoScanTimer?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner_outlined),
            activeIcon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.devices_outlined),
            activeIcon: Icon(Icons.devices),
            label: 'Devices',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
