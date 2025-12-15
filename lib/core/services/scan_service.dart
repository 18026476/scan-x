import 'dart:async';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

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

  /// Backwards-compat: some UI still calls `port.service`.
  String get service => serviceName;
}

/// Represents a detected host in the scan result.
class DetectedHost {
  final String address; // IP or hostname
  final String? hostname;
  final List<OpenPort> openPorts;
  final RiskLevel risk;

  DetectedHost({
    required this.address,
    required this.hostname,
    required this.openPorts,
    required this.risk,
  });

  /// Backwards-compat: older code uses `host.ip`.
  String get ip => address;
}

/// Overall scan result from a single Smart/Full scan.
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

/// Main service that talks to nmap and parses output.
class ScanService {
  ScanService._internal();
  static final ScanService _instance = ScanService._internal();
  factory ScanService() => _instance;

  /// Last completed scan (Smart or Full).
  ScanResult? lastResult;

  // ---------------------------------------------------------------------------
  // PUBLIC API
  // ---------------------------------------------------------------------------

  /// Dashboard helper: runs a quick Smart Scan using the saved Settings target.
  /// This avoids compile-time dependency on ScanSettings having a specific
  /// field name (we read SharedPreferences directly for robustness).
  Future<ScanResult> runQuickSmartScanFromDefaults() async {
    final prefs = await SharedPreferences.getInstance();

    // Try a few likely keys. If none exist, fallback to a safe default.
    final target =
        prefs.getString('defaultTarget') ??
            prefs.getString('targetCidr') ??
            prefs.getString('defaultTargetCidr') ??
            prefs.getString('scanTarget') ??
            '192.168.1.0/24';

    return runQuickSmartScan(target);
  }

  /// "Quick Smart Scan" – faster than your standard smart scan:
  /// - fewer top ports
  /// - host timeout
  /// - reduced retries
  Future<ScanResult> runQuickSmartScan(String target) async {
    final settings = SettingsService().settings;
    final started = DateTime.now();

    final args = _buildQuickSmartArgs(target, settings);
    final stdoutStr = await _runNmap(args);

    final hosts = _parseNmapOutput(stdoutStr);
    final finished = DateTime.now();

    final result = ScanResult(
      target: target,
      startedAt: started,
      finishedAt: finished,
      hosts: hosts,
    );

    lastResult = result;
    return result;
  }

  /// Fast "Smart Scan" – focuses on common ports and speed.
  Future<ScanResult> runSmartScan(String target) async {
    final settings = SettingsService().settings;
    final started = DateTime.now();

    final args = _buildSmartScanArgs(target, settings);
    final stdoutStr = await _runNmap(args);

    final hosts = _parseNmapOutput(stdoutStr);
    final finished = DateTime.now();

    final result = ScanResult(
      target: target,
      startedAt: started,
      finishedAt: finished,
      hosts: hosts,
    );

    lastResult = result;
    return result;
  }

  /// Deep "Full Scan" – scans all 1–65535 ports.
  Future<ScanResult> runFullScan(String target) async {
    final settings = SettingsService().settings;
    final started = DateTime.now();

    final args = _buildFullScanArgs(target, settings);
    final stdoutStr = await _runNmap(args);

    final hosts = _parseNmapOutput(stdoutStr);
    final finished = DateTime.now();

    final result = ScanResult(
      target: target,
      startedAt: started,
      finishedAt: finished,
      hosts: hosts,
    );

    lastResult = result;
    return result;
  }

  /// Helper: some UI calls `ScanService().getRiskLevel(host)`.
  RiskLevel getRiskLevel(DetectedHost host) {
    return _calculateRiskLevel(host.openPorts);
  }

  // ---------------------------------------------------------------------------
  // ARG BUILDERS
  // ---------------------------------------------------------------------------

  List<String> _buildQuickSmartArgs(String target, ScanSettings settings) {
    // This is deliberately conservative for home networks:
    // fast timing + smaller port set + host timeout.
    final args = <String>[
      '-sV',
      '-T4',
      '--top-ports',
      '200',
      '--host-timeout',
      '15s',
      '--max-retries',
      '1',
    ];

    // If user selected paranoid, slow it slightly (but still "quick").
    if (settings.scanMode == ScanMode.paranoid) {
      // Reduce aggression for flaky routers.
      args.remove('-T4');
      args.insert(1, '-T3');
      // Give a bit more time per host.
      final idx = args.indexOf('--host-timeout');
      if (idx != -1 && idx + 1 < args.length) {
        args[idx + 1] = '25s';
      }
    }

    args.add(target);
    return args;
  }

  List<String> _buildSmartScanArgs(String target, ScanSettings settings) {
    final args = <String>[
      '-sV',
      '-T4',
    ];

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

  List<String> _buildFullScanArgs(String target, ScanSettings settings) {
    final args = <String>[
      '-sV',
      '-p',
      '1-65535',
    ];

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
  // LOW-LEVEL NMAP INVOCATION
  // ---------------------------------------------------------------------------

  Future<String> _runNmap(List<String> args) async {
    // Windows-safe decoding: systemEncoding avoids UTF-8 pipe crashes
    final result = await Process.run(
      'nmap',
      args,
      runInShell: true,
      stdoutEncoding: systemEncoding,
      stderrEncoding: systemEncoding,
    );

    if (result.exitCode != 0) {
      final stderrStr = (result.stderr ?? '').toString();
      throw Exception('nmap failed (exit ${result.exitCode}): $stderrStr');
    }

    final out = (result.stdout ?? '').toString();
    return _sanitizeText(out);
  }

  /// Removes common mojibake artifacts + normalizes weird control chars
  /// without destroying legitimate hostnames.
  String _sanitizeText(String s) {
    // Remove replacement chars and trim weird nulls.
    var t = s.replaceAll('\uFFFD', '');

    // Very common mojibake fragments seen in your UI/logs.
    // We do NOT try to "decode back" (unsafe). We just strip noise.
    const junk = [
      'ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“',
      'ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“',
      'ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢',
      'ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“',
      'ÃƒÂ¢Ã¢â€šÂ¬',
      'ÃƒÂ¢Ã¢â€š',
      'ÃƒÂ¢',
    ];
    for (final j in junk) {
      t = t.replaceAll(j, '');
    }

    return t;
  }

  // ---------------------------------------------------------------------------
  // PARSING
  // ---------------------------------------------------------------------------

  final RegExp _hostRegex = RegExp(r'^Nmap scan report for (.+)$');
  final RegExp _portLineRegex =
  RegExp(r'^(\d+)/(tcp|udp)\s+open\s+([\w\-\?\.\+]+)');

  List<DetectedHost> _parseNmapOutput(String stdoutStr) {
    final lines = stdoutStr.split('\n');

    final hosts = <DetectedHost>[];
    String? currentAddress;
    String? currentHostname;
    final currentPorts = <OpenPort>[];

    void flushCurrentHost() {
      if (currentAddress == null) return;
      final portsCopy = List<OpenPort>.from(currentPorts);
      currentPorts.clear();

      final risk = _calculateRiskLevel(portsCopy);

      hosts.add(
        DetectedHost(
          address: currentAddress!,
          hostname: currentHostname,
          openPorts: portsCopy,
          risk: risk,
        ),
      );

      currentAddress = null;
      currentHostname = null;
    }

    for (var rawLine in lines) {
      final line = rawLine.trimRight();

      final hostMatch = _hostRegex.firstMatch(line);
      if (hostMatch != null) {
        flushCurrentHost();

        final hostString = hostMatch.group(1) ?? '';

        String address = hostString;
        String? hostname;

        final ipInParens = RegExp(r'(.+)\s+\(([^)]+)\)');
        final ipMatch = ipInParens.firstMatch(hostString);
        if (ipMatch != null) {
          hostname = ipMatch.group(1)?.trim();
          address = ipMatch.group(2)?.trim() ?? address;
        }

        currentAddress = address;
        currentHostname = hostname;
        continue;
      }

      final portMatch = _portLineRegex.firstMatch(line);
      if (portMatch != null && currentAddress != null) {
        final port = int.tryParse(portMatch.group(1) ?? '') ?? 0;
        final protocol = portMatch.group(2) ?? 'tcp';
        final service = portMatch.group(3) ?? '?';

        currentPorts.add(
          OpenPort(
            port: port,
            protocol: protocol,
            serviceName: service,
          ),
        );
        continue;
      }
    }

    flushCurrentHost();
    return hosts;
  }

  // ---------------------------------------------------------------------------
  // RISK LEVEL HEURISTICS
  // ---------------------------------------------------------------------------

  RiskLevel _calculateRiskLevel(List<OpenPort> ports) {
    if (ports.isEmpty) {
      return RiskLevel.low;
    }

    bool hasHigh = false;
    bool hasMedium = false;

    for (final p in ports) {
      final s = p.serviceName.toLowerCase();

      if (p.port == 21 ||
          p.port == 23 ||
          p.port == 3389 ||
          p.port == 445 ||
          p.port == 1900 ||
          s.contains('telnet') ||
          s.contains('rdp') ||
          s.contains('smb')) {
        hasHigh = true;
        break;
      }

      if (p.port == 22 ||
          p.port == 80 ||
          p.port == 443 ||
          p.port == 8080 ||
          s.contains('http') ||
          s.contains('ssh')) {
        hasMedium = true;
      }
    }

    if (hasHigh) return RiskLevel.high;
    if (hasMedium) return RiskLevel.medium;
    return RiskLevel.low;
  }
}
