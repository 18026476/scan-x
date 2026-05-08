import 'package:scanx_app/core/services/settings_service.dart';
import 'package:scanx_app/core/services/scan_service.dart';

enum AlertType {
  newDevice,
  unknownDevice,
  routerVulnerability,
  iotWarning,
  highRisk,
  highRiskFindings,
  scanCompleted,
  macChange,
  macChanged,
  arpSpoof,
  possibleArpSpoof,
  portExposure,
  portExposureSpike,
}

enum AlertSeverity {
  info,
  medium,
  high,
}

class AlertEvent {
  final AlertType type;
  final AlertSeverity severity;
  final String title;
  final String message;
  final String? evidence;
  final DateTime createdAt;

  AlertEvent({
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    this.evidence,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
}

class ScanxAlertEvent extends AlertEvent {
  final String id;

  ScanxAlertEvent({
    required this.id,
    required AlertType type,
    required AlertSeverity alertSeverity,
    required String title,
    required String message,
    String? evidence,
    required DateTime createdAt,
  }) : super(
          type: type,
          severity: alertSeverity,
          title: title,
          message: message,
          evidence: evidence,
          createdAt: createdAt,
        );

  factory ScanxAlertEvent.simple({
    required String id,
    required String title,
    required String message,
    required String severity,
    required DateTime createdAt,
    AlertType type = AlertType.highRiskFindings,
    String? evidence,
  }) {
    return ScanxAlertEvent(
      id: id,
      type: type,
      alertSeverity: severity == 'high'
          ? AlertSeverity.high
          : severity == 'info'
              ? AlertSeverity.info
              : AlertSeverity.medium,
      title: title,
      message: message,
      evidence: evidence,
      createdAt: createdAt,
    );
  }
}

class AlertRulesEngine {
  AlertRulesEngine({SettingsService? settings})
      : _settings = settings ?? SettingsService();

  final SettingsService _settings;

  List<AlertEvent> buildEvents({
    dynamic currentHosts,
    dynamic current,
    dynamic previousHosts,
    dynamic previousSnapshot,
    dynamic currentIpToMac,
    bool scanCompleted = true,
    bool autoScan = false,
  }) {
    final hosts = _extractHosts(currentHosts ?? current);
    final previous = _extractHosts(previousHosts ?? previousSnapshot);
    final events = <AlertEvent>[];
    final now = DateTime.now();

    final previousByAddress = {
      for (final host in previous) host.address: host,
    };

    if (_settings.alertNewDevice && _settings.notifyNewDevice) {
      for (final host in hosts) {
        if (!previousByAddress.containsKey(host.address)) {
          events.add(
            ScanxAlertEvent.simple(
              id: 'new_device_${host.address}_${now.millisecondsSinceEpoch}',
              type: AlertType.newDevice,
              title: 'New device detected',
              message:
                  'A new device was found on your network: ${host.hostname ?? host.address}.',
              severity: 'medium',
              createdAt: now,
            ),
          );
        }
      }
    }

    if (_settings.notifyUnknownDevice) {
      for (final host in hosts) {
        final hostname = (host.hostname ?? '').trim().toLowerCase();
        final hasName = hostname.isNotEmpty &&
            hostname != 'unknown' &&
            hostname != 'unknown device';

        if (!hasName) {
          events.add(
            ScanxAlertEvent.simple(
              id: 'unknown_device_${host.address}_${now.millisecondsSinceEpoch}',
              type: AlertType.unknownDevice,
              title: 'Unknown device detected',
              message:
                  'SCAN-X found an unknown or unnamed device at ${host.address}.',
              severity: 'medium',
              createdAt: now,
            ),
          );
        }
      }
    }

    if (_settings.alertMacChange) {
      for (final host in hosts) {
        final oldHost = previousByAddress[host.address];
        if (oldHost == null) continue;

        final oldName = oldHost.hostname ?? '';
        final newName = host.hostname ?? '';

        if (oldName.isNotEmpty && newName.isNotEmpty && oldName != newName) {
          events.add(
            ScanxAlertEvent.simple(
              id: 'mac_changed_${host.address}_${now.millisecondsSinceEpoch}',
              type: AlertType.macChanged,
              title: 'Device identity changed',
              message:
                  'Device ${host.address} changed identity from "$oldName" to "$newName".',
              severity: 'medium',
              createdAt: now,
            ),
          );
        }
      }
    }

    if (_settings.alertArpSpoof) {
      final hostnameGroups = <String, List<DetectedHost>>{};

      for (final host in hosts) {
        final hostname = (host.hostname ?? '').trim().toLowerCase();
        if (hostname.isEmpty || hostname == 'unknown') continue;
        hostnameGroups.putIfAbsent(hostname, () => <DetectedHost>[]).add(host);
      }

      for (final entry in hostnameGroups.entries) {
        if (entry.value.length > 1) {
          events.add(
            ScanxAlertEvent.simple(
              id: 'arp_spoof_${entry.key}_${now.millisecondsSinceEpoch}',
              type: AlertType.possibleArpSpoof,
              title: 'Possible ARP spoofing detected',
              message:
                  'Multiple devices appear to share the same hostname: ${entry.key}.',
              severity: 'high',
              createdAt: now,
            ),
          );
        }
      }
    }

    if (_settings.alertPortScanAttempts) {
      final sensitivity = _settings.alertSensitivity;
      final threshold = sensitivity >= 2 ? 3 : 5;

      for (final host in hosts) {
        if (host.openPorts.length >= threshold) {
          events.add(
            ScanxAlertEvent.simple(
              id: 'port_exposure_${host.address}_${now.millisecondsSinceEpoch}',
              type: AlertType.portExposureSpike,
              title: 'Port exposure spike detected',
              message:
                  '${host.address} has ${host.openPorts.length} open ports. Review this device.',
              severity: host.openPorts.length >= 8 ? 'high' : 'medium',
              createdAt: now,
            ),
          );
        }
      }
    }

    if (_settings.notifyHighRisk) {
      for (final host in hosts) {
        if (host.risk == RiskLevel.high) {
          events.add(
            ScanxAlertEvent.simple(
              id: 'high_risk_${host.address}_${now.millisecondsSinceEpoch}',
              type: AlertType.highRiskFindings,
              title: 'High-risk device found',
              message:
                  '${host.hostname ?? host.address} was rated as high risk.',
              severity: 'high',
              createdAt: now,
            ),
          );
        }
      }
    }

    if (scanCompleted && _settings.notifyScanCompleted) {
      events.add(
        ScanxAlertEvent.simple(
          id: 'scan_completed_${now.millisecondsSinceEpoch}',
          type: AlertType.scanCompleted,
          title: autoScan ? 'Auto scan completed' : 'Scan completed',
          message: 'SCAN-X finished scanning ${hosts.length} device(s).',
          severity: 'info',
          createdAt: now,
        ),
      );
    }

    return events;
  }

  List<DetectedHost> _extractHosts(dynamic value) {
    if (value == null) return <DetectedHost>[];

    if (value is ScanResult) {
      return value.hosts;
    }

    if (value is List<DetectedHost>) {
      return value;
    }

    if (value is Iterable<DetectedHost>) {
      return value.toList();
    }

    return <DetectedHost>[];
  }
}

