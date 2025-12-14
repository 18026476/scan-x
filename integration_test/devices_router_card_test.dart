import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:scanx_app/main.dart' as app;
import 'package:scanx_app/core/testing/test_hooks.dart';
import 'package:scanx_app/core/services/scan_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpSeconds(WidgetTester tester, int seconds) async {
    for (int i = 0; i < seconds; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
  }

  Future<void> tapTab(WidgetTester tester, String label) async {
    final f = find.text(label);
    expect(f, findsWidgets, reason: 'Tab "$label" should exist');
    await tester.tap(f.first);
    await tester.pump(const Duration(seconds: 2)); // bounded pump (no settle)
  }

  testWidgets('Devices: router card renders when scan data exists', (tester) async {
    final fake = ScanResult(
      target: '192.168.1.0/24',
      startedAt: DateTime.now().subtract(const Duration(seconds: 2)),
      finishedAt: DateTime.now(),
      hosts: [
        DetectedHost(
          address: '192.168.1.1',
          hostname: 'router',
          openPorts: [
            OpenPort(port: 1900, protocol: 'udp', serviceName: 'UPnP'),
            OpenPort(port: 80, protocol: 'tcp', serviceName: 'HTTP'),
          ],
          risk: RiskLevel.high,
        ),
        DetectedHost(
          address: '192.168.1.10',
          hostname: 'laptop',
          openPorts: [
            OpenPort(port: 443, protocol: 'tcp', serviceName: 'HTTPS'),
          ],
          risk: RiskLevel.medium,
        ),
      ],
    );

    TestHooks.seedLastResult(fake);

    // Launch app
    app.main();

    // Give the app time to mount without waiting for "settle"
    await pumpSeconds(tester, 5);

    // Go to Devices tab and assert router card exists (Key-based, stable)
    await tapTab(tester, 'Devices');
    await pumpSeconds(tester, 1);

    expect(find.byKey(const Key('router_iot_card')), findsOneWidget);

    TestHooks.clearLastResult();
  });
}
