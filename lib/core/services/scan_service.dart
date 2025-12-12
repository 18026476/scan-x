// lib/core/services/scan_service.dart
//
// Central scan engine for SCAN-X.
// Exposes a singleton [scanService], a reactive list of [DetectedHost],
// and helpers for Smart / Full scans backed by Nmap.

import 'package:flutter/foundation.dart';
import 'package:scanx_app/core/services/nmap_engine.dart';

/// Simple risk classification for devices.
enum RiskLevel { low, medium, high }

/// One device / host discovered on the network.
class DetectedHost {
  final String ip;
  final String? displayName;
  final String? macAddress;
  final String? vendor;
  final String? deviceType;

  /// Keep this as List<int> for v1 stability across screens.
  final List<int> openPorts;

  RiskLevel get overallRisk {
    if (openPorts.isEmpty) return RiskLevel.low;

    final hasDangerous = openPorts.any((p) => p == 22 || p == 23 || p == 3389 || p == 445);
    if (hasDangerous) return RiskLevel.high;
    if (openPorts.length >= 3) return RiskLevel.medium;
    return RiskLevel.low;
  }

  const DetectedHost({
    required this.ip,
    this.displayName,
    this.macAddress,
    this.vendor,
    this.deviceType,
    this.openPorts = const <int>[],
  });
}

class ScanService {
  ScanService._internal();
  static final ScanService _instance = ScanService._internal();
  factory ScanService() => _instance;

  final ValueNotifier<List<DetectedHost>> detectedHostsNotifier =
      ValueNotifier<List<DetectedHost>>(<DetectedHost>[]);

  List<DetectedHost> get detectedHosts => detectedHostsNotifier.value;

  final ValueNotifier<bool> isScanning = ValueNotifier<bool>(false);
  final ValueNotifier<String?> lastError = ValueNotifier<String?>(null);

  void clearResults() {
    detectedHostsNotifier.value = <DetectedHost>[];
  }

  Future<void> runSmartScan(String target) async {
    if (isScanning.value) return;
    isScanning.value = true;
    lastError.value = null;

    // Blank devices before scan (your requirement)
    clearResults();

    try {
      final results = await NmapEngine.scan(target: target, topPorts: 100);

      final hosts = results.map((h) {
        final ports = h.openPorts.map((p) => p.port).toSet().toList()..sort();
        return DetectedHost(
          ip: h.ip,
          displayName: null, // optional (can enrich later)
          openPorts: ports,
        );
      }).toList()
        ..sort((a, b) => a.ip.compareTo(b.ip));

      detectedHostsNotifier.value = hosts;
    } catch (e) {
      lastError.value = e.toString();
      // keep blank (do NOT inject fake devices)
      detectedHostsNotifier.value = <DetectedHost>[];
      rethrow;
    } finally {
      isScanning.value = false;
    }
  }

  Future<void> runFullScan(String target) async {
    if (isScanning.value) return;
    isScanning.value = true;
    lastError.value = null;

    clearResults();

    try {
      // Full scan = more ports (still time bounded)
      final results = await NmapEngine.scan(target: target, topPorts: 1000);

      final hosts = results.map((h) {
        final ports = h.openPorts.map((p) => p.port).toSet().toList()..sort();
        return DetectedHost(
          ip: h.ip,
          displayName: null,
          openPorts: ports,
        );
      }).toList()
        ..sort((a, b) => a.ip.compareTo(b.ip));

      detectedHostsNotifier.value = hosts;
    } catch (e) {
      lastError.value = e.toString();
      detectedHostsNotifier.value = <DetectedHost>[];
      rethrow;
    } finally {
      isScanning.value = false;
    }
  }
}

/// Global singleton
final ScanService scanService = ScanService();
