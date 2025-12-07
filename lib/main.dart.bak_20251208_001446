// lib/main.dart

import 'package:flutter/material.dart';
import 'features/navigation/main_navigation.dart';

void main() {
  runApp(const ScanXApp());
}

class ScanXApp extends StatelessWidget {
  const ScanXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SCAN-X',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Colors.greenAccent,
          secondary: Colors.greenAccent,
        ),
        scaffoldBackgroundColor: const Color(0xFF05080A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF05080A),
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const MainNavigation(),
    );
  }
}
