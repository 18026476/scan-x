// lib/features/navigation/main_navigation.dart

import 'package:flutter/material.dart';
import 'package:scanx_app/features/dashboard/dashboard_screen.dart';
import 'package:scanx_app/features/scan/scan_screen.dart';
import 'package:scanx_app/features/devices/devices_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const DashboardScreen(),
      const ScanScreen(),
      DevicesScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.devices_other),
            label: 'Devices',
          ),
        ],
      ),
    );
  }
}
