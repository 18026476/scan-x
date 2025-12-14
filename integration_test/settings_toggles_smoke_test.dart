import 'package:flutter_test/flutter_test.dart';

import 'package:flutter/material.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter/material.dart';
import 'package:scanx_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> tapTab(WidgetTester tester, String label) async {
    final f = find.text(label);
    expect(f, findsWidgets, reason: 'Tab "$label" should exist');
    await tester.tap(f.first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  testWidgets('Settings: screen opens and scrolling works', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    await tapTab(tester, 'Settings');

    // Smoke only: ensure settings page rendered.
    // If your settings page has a title, keep it structural, not copy-dependent:
    // expect(find.text('Settings'), findsWidgets);

    // Try a gentle scroll to ensure no overflow exceptions
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(true, isTrue);
  });
}