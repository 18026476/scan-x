import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'settings_service.dart';

/// Basic risk level used across the app.
enum RiskLevel {
  low,
  medium,
  high,
}

/// Represents a single open port on a host.
class OpenPort {
  final int port;
  final String protocol;
  final String serviceName;

  OpenPort({
    required this.port,
    required this.protocol,
    required this.serviceName,
  });

  /// Backwards-compat
  String get service => serviceName;
}

/// Represents a detected host in the scan result.
class DetectedHost {
  final String address; // IP
  final String? hostname;
  final List<OpenPort> openPorts;
  final RiskLevel risk;

  DetectedHost({
    required this.address,
    required this.hostname,
    required this.openPorts,
    required this.risk,
  });

  String get ip => address;
}

/// Overall scan result.
class ScanResult {
  final String target;
  final DateTime startedAt;
  final DateTime finishedAt;
  final List<DetectedHost> hosts;

  ScanResult({
    required this.target,
    required this.startedAt,
    required this.finishedAt,
    required this.hosts,
  });
}

class ScanService {
  ScanService._internal();
  static final ScanService _instance = ScanService._internal();
  factory ScanService() => _instance;

  ScanResult? lastResult;

  // ---------------------------------------------------------------------------
  // PUBLIC API
  // ---------------------------------------------------------------------------

  Future<ScanResult> runSmartScan(String target) async {
    final settings = SettingsService().settings;
    final started = DateTime.now();

    final stdoutStr = await _runNmap(
      _buildSmartScanArgs(target, settings),
    );

    final hosts = _parseNmapOutput(stdoutStr);

    final result = ScanResult(
      target: target,
      startedAt: started,
      finishedAt: DateTime.now(),
      hosts: hosts,
    );

    lastResult = result;
    return result;
  }

  Future<ScanResult> runFullScan(String target) async {
    final settings = SettingsService().settings;
    final started = DateTime.now();

    final stdoutStr = await _runNmap(
      _buildFullScanArgs(target, settings),
    );

    final hosts = _parseNmapOutput(stdoutStr);

    final result = ScanResult(
      target: target,
      startedAt: started,
      finishedAt: DateTime.now(),
      hosts: hosts,
    );

    lastResult = result;
    return result;
  }

  RiskLevel getRiskLevel(DetectedHost host) =>
      _calculateRiskLevel(host.openPorts);

  // ---------------------------------------------------------------------------
  // NMAP ARGS
  // ---------------------------------------------------------------------------

  List<String> _buildSmartScanArgs(
      String target, ScanSettings settings) {
    final args = ['-sV', '-T4'];

    switch (settings.scanMode) {
      case ScanMode.performance:
        args.addAll(['--top-ports', '200']);
        break;
      case ScanMode.balanced:
        args.addAll(['--top-ports', '1000']);
        break;
      case ScanMode.paranoid:
        args.addAll(['--top-ports', '5000', '-T3']);
        break;
    }

    args.add(target);
    return args;
  }

  List<String> _buildFullScanArgs(
      String target, ScanSettings settings) {
    final args = ['-sV', '-p', '1-65535'];

    switch (settings.scanMode) {
      case ScanMode.performance:
        args.add('-T4');
        break;
      case ScanMode.balanced:
        args.add('-T3');
        break;
      case ScanMode.paranoid:
        args.add('-T2');
        break;
    }

    args.add(target);
    return args;
  }

  // ---------------------------------------------------------------------------
  // PROCESS EXECUTION
  // ---------------------------------------------------------------------------

  Future<String> _runNmap(List<String> args) async {
    final result = await Process.run(
      'nmap',
      args,
      runInShell: true,
      stdoutEncoding: systemEncoding,
      stderrEncoding: systemEncoding,
    );

    if (result.exitCode != 0) {
      throw Exception(
        'nmap failed (${result.exitCode}): ${result.stderr}',
      );
    }

    return result.stdout.toString();
  }

  // ---------------------------------------------------------------------------
  // PARSING + SANITIZATION
  // ---------------------------------------------------------------------------

  final _hostRegex = RegExp(r'^Nmap scan report for (.+)$');
  final _portRegex =
  RegExp(r'^(\d+)/(tcp|udp)\s+open\s+([\w\-\.\+]+)');

  List<DetectedHost> _parseNmapOutput(String stdoutStr) {
    final lines = stdoutStr.split('\n');

    final hosts = <DetectedHost>[];
    String? address;
    String? hostname;
    final ports = <OpenPort>[];

    void flush() {
      if (address == null) return;

      hosts.add(
        DetectedHost(
          address: address!,
          hostname: _sanitizeString(hostname),
          openPorts: List.from(ports),
          risk: _calculateRiskLevel(ports),
        ),
      );

      address = null;
      hostname = null;
      ports.clear();
    }

    for (final raw in lines) {
      final line = raw.trimRight();

      final hostMatch = _hostRegex.firstMatch(line);
      if (hostMatch != null) {
        flush();

        final value = hostMatch.group(1)!;
        final m = RegExp(r'(.+)\s+\(([^)]+)\)').firstMatch(value);

        if (m != null) {
          hostname = m.group(1);
          address = m.group(2);
        } else {
          address = value;
        }
        continue;
      }

      final portMatch = _portRegex.firstMatch(line);
      if (portMatch != null && address != null) {
        ports.add(
          OpenPort(
            port: int.parse(portMatch.group(1)!),
            protocol: portMatch.group(2)!,
            serviceName: portMatch.group(3)!,
          ),
        );
      }
    }

    flush();
    return hosts;
  }

  String? _sanitizeString(String? input) {
    if (input == null) return null;

    // Remove NUL + control chars
    var s = input.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();

    // Fix mojibake if present
    if (s.contains('Ã') || s.contains('Â') || s.contains('â')) {
      try {
        s = utf8.decode(latin1.encode(s), allowMalformed: true);
      } catch (_) {}
    }

    return s.isEmpty ? null : s;
  }

  // ---------------------------------------------------------------------------
  // RISK HEURISTICS
  // ---------------------------------------------------------------------------

  RiskLevel _calculateRiskLevel(List<OpenPort> ports) {
    if (ports.isEmpty) return RiskLevel.low;

    bool high = false;
    bool medium = false;

    for (final p in ports) {
      final s = p.serviceName.toLowerCase();

      if ([21, 23, 3389, 445, 1900].contains(p.port) ||
          s.contains('telnet') ||
          s.contains('rdp') ||
          s.contains('smb')) {
        high = true;
        break;
      }

      if ([22, 80, 443, 8080].contains(p.port) ||
          s.contains('http') ||
          s.contains('ssh')) {
        medium = true;
      }
    }

    if (high) return RiskLevel.high;
    if (medium) return RiskLevel.medium;
    return RiskLevel.low;
  }
}
