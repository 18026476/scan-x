// test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanx_app/main.dart';

void main() {
  testWidgets('SCAN-X app builds', (WidgetTester tester) async {
    // Pump the root widget
    await tester.pumpWidget(const ScanXApp());

    // Simple smoke test: app builds and has a MaterialApp
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
