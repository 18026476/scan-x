import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:scanx_app/core/services/settings_service.dart';
import 'package:scanx_app/core/services/scan_service.dart';
import 'package:scanx_app/core/services/alert_rules_engine.dart';

OpenPort p(int port, {String proto = 'tcp'}) =>
    OpenPort(port: port, protocol: proto, serviceName: 'test');

DetectedHost host(String ip, {String hostName = 'dev', int openPorts = 0, RiskLevel risk = RiskLevel.low}) {
  return DetectedHost(
    address: ip,
    hostname: hostName,
    openPorts: List.generate(openPorts, (i) => p(1000 + i)),
    risk: risk,
  );
}

ScanResult scan(String target, List<DetectedHost> hosts) {
  final now = DateTime.now();
  return ScanResult(target: target, startedAt: now, finishedAt: now, hosts: hosts);
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.init();
  });

  test('New device event generated when toggle ON', () async {
    final s = SettingsService();
    await s.setAlertNewDevice(true);

    final prev = {
      'devices': {
        '192.168.1.10': {'ip': '192.168.1.10', 'mac': 'aa:aa:aa:aa:aa:aa', 'openPorts': 1},
      }
    };

    final current = scan('192.168.1.0/24', [
      host('192.168.1.10', openPorts: 1),
      host('192.168.1.20', openPorts: 1),
    ]);

    final events = AlertRulesEngine().buildEvents(
      current: current,
      previousSnapshot: prev,
      currentIpToMac: {
        '192.168.1.10': 'aa:aa:aa:aa:aa:aa',
        '192.168.1.20': 'bb:bb:bb:bb:bb:bb'
      },
    );

    expect(events.any((e) => e.type == AlertType.newDevice), isTrue);
  });

  test('MAC change event generated when toggle ON and MAC differs', () async {
    final s = SettingsService();
    await s.setAlertMacChange(true);

    final prev = {
      'devices': {
        '192.168.1.10': {'ip': '192.168.1.10', 'mac': 'aa:aa:aa:aa:aa:aa', 'openPorts': 1},
      }
    };

    final current = scan('192.168.1.0/24', [host('192.168.1.10', openPorts: 1)]);

    final events = AlertRulesEngine().buildEvents(
      current: current,
      previousSnapshot: prev,
      currentIpToMac: {'192.168.1.10': 'cc:cc:cc:cc:cc:cc'},
    );

    expect(events.any((e) => e.type == AlertType.macChanged), isTrue);
  });

  test('ARP spoof event generated when same MAC appears on multiple IPs', () async {
    final s = SettingsService();
    await s.setAlertArpSpoof(true);

    final current = scan('192.168.1.0/24', [host('192.168.1.10'), host('192.168.1.11')]);

    final events = AlertRulesEngine().buildEvents(
      current: current,
      previousSnapshot: null,
      currentIpToMac: {
        '192.168.1.10': 'aa:aa:aa:aa:aa:aa',
        '192.168.1.11': 'aa:aa:aa:aa:aa:aa'
      },
    );

    expect(events.any((e) => e.type == AlertType.possibleArpSpoof), isTrue);
  });

  test('Port exposure spike event generated when open ports jump across snapshots', () async {
    final s = SettingsService();
    await s.setAlertPortScanAttempts(true);
    await s.setAlertSensitivity(2);

    final prev = {
      'devices': {
        '192.168.1.10': {'ip': '192.168.1.10', 'mac': 'aa', 'openPorts': 1},
      }
    };

    final current = scan('192.168.1.0/24', [host('192.168.1.10', openPorts: 8)]);

    final events = AlertRulesEngine().buildEvents(
      current: current,
      previousSnapshot: prev,
      currentIpToMac: {'192.168.1.10': 'aa'},
    );

    expect(events.any((e) => e.type == AlertType.portExposureSpike), isTrue);
  });
}