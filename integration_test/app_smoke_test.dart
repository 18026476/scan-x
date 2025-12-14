import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:scanx_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> tapTab(WidgetTester tester, String label) async {
    final f = find.text(label);
    expect(f, findsWidgets, reason: 'Tab "$label" should exist');
    await tester.tap(f.first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  testWidgets('SCAN-X smoke: app launches and tabs switch', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    await tapTab(tester, 'Dashboard');
    await tapTab(tester, 'Scan');
    await tapTab(tester, 'Devices');
    await tapTab(tester, 'Settings');

    expect(true, isTrue);
  });
}