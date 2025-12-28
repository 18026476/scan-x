// lib/features/navigation/main_navigation.dart

import 'package:flutter/material.dart';
import 'package:scanx_app/features/dashboard/dashboard_screen.dart';
import 'package:scanx_app/features/scan/scan_screen.dart';
import 'package:scanx_app/features/devices/devices_screen.dart';
import 'package:scanx_app/features/settings/settings_screen.dart';
import 'package:scanx_app/core/services/scan_service.dart';
import 'package:scanx_app/core/services/settings_service.dart';
import 'dart:async';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  Timer? _autoScanTimer;

  int _currentIndex = 0;

  // 4 tabs: Dashboard, Scan, Devices, Settings
  final List<Widget> _pages = const <Widget>[
    DashboardScreen(),
    ScanScreen(),
    DevicesScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();

    // Best-effort continuous monitoring (settings-gated).
    // Runs periodic Quick Smart scans using the saved default target.
    final s = SettingsService();
    if (s.continuousMonitoring) {
      final minutes = _scanFrequencyMinutes(s.scanFrequency);
      if (minutes > 0) {
        _autoScanTimer?.cancel();
        _autoScanTimer = Timer.periodic(Duration(minutes: minutes), (_) async {
          try {
            await ScanService().runQuickSmartScanFromDefaults();
          } catch (_) {
            // Silent in release; continuous monitoring is best-effort.
          }
        });
      }
    }
  }

  int _scanFrequencyMinutes(int idx) {
    // 0=manual, 1=hourly, 2=6-hourly, 3=daily
    switch (idx) {
      case 1:
        return 60;
      case 2:
        return 360;
      case 3:
        return 1440;
      default:
        return 0;
    }
  }

  @override
  void dispose() {
    _autoScanTimer?.cancel();
    super.dispose();
  }


  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
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
