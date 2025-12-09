import 'package:flutter/material.dart';
import 'package:scanx_app/features/dashboard/dashboard_screen.dart';
import 'package:scanx_app/features/scan/scan_screen.dart';
import 'package:scanx_app/features/devices/devices_screen.dart';
import 'package:scanx_app/features/settings/settings_screen.dart';

/// Legacy shell (not the main entry) – kept compiling clean for future use.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  static final List<Widget> _screens = <Widget>[
    const DashboardScreen(),
    const ScanScreen(),
    DevicesScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bolt),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.devices),
            label: 'Devices',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
