import 'dart:convert';

import 'dart:async';
import 'dart:convert';

import 'dart:io';

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';

import 'settings_service.dart';
import 'dart:convert';

import 'security_ai_service.dart';

enum RiskLevel { low, medium, high }

class OpenPort {
  final int port;
  final String protocol;
  final String serviceName;

  OpenPort({
    required this.port,
    required this.protocol,
    required this.serviceName,
  });

  String get service => serviceName;
}

class DetectedHost {
  final String address;
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

  Future<ScanResult> runQuickSmartScanFromDefaults() async {
    final prefs = await SharedPreferences.getInstance();

    final target = prefs.getString('defaultTarget') ??
        prefs.getString('targetCidr') ??
        prefs.getString('defaultTargetCidr') ??
        prefs.getString('scanTarget') ??
        '192.168.1.0/24';

    return runQuickSmartScan(target);
  }

  Future<ScanResult> runQuickSmartScan(String target) async {
    final started = DateTime.now();

    final settingsSvc = SettingsService();
    if (settingsSvc.autoClearScan) {
      lastResult = null;
    }

    final settings = SettingsService().settings;
    final args = _buildQuickSmartArgs(target, settings);
    final stdoutStr = await _runNmap(args);

    final hosts = _parseNmapOutput(stdoutStr);
    final resolvedHosts = await _applyAiRiskScoring(hosts);
    final finished = DateTime.now();

    final result = ScanResult(
      target: target,
      startedAt: started,
      finishedAt: finished,
      hosts: resolvedHosts,
    );

    lastResult = result;
    return result;
  }

  Future<ScanResult> runSmartScan(String target) async {
    final started = DateTime.now();

    final settingsSvc = SettingsService();
    if (settingsSvc.autoClearScan) {
      lastResult = null;
    }

    final settings = SettingsService().settings;
    final args = _buildSmartScanArgs(target, settings);
    final stdoutStr = await _runNmap(args);

    final hosts = _parseNmapOutput(stdoutStr);
    final resolvedHosts = await _applyAiRiskScoring(hosts);
    final finished = DateTime.now();

    final result = ScanResult(
      target: target,
      startedAt: started,
      finishedAt: finished,
      hosts: resolvedHosts,
    );

    lastResult = result;
    return result;
  }

  Future<ScanResult> runFullScan(String target) async {
    final started = DateTime.now();

    final settingsSvc = SettingsService();
    if (settingsSvc.autoClearScan) {
      lastResult = null;
    }

    final settings = SettingsService().settings;
    final args = _buildFullScanArgs(target, settings);
    final stdoutStr = await _runNmap(args);

    final hosts = _parseNmapOutput(stdoutStr);
    final resolvedHosts = await _applyAiRiskScoring(hosts);
    final finished = DateTime.now();

    final result = ScanResult(
      target: target,
      startedAt: started,
      finishedAt: finished,
      hosts: resolvedHosts,
    );

    lastResult = result;
    return result;
  }

  RiskLevel getRiskLevel(DetectedHost host) => host.risk;

  // ---------- AI risk scoring ----------

  Future<List<DetectedHost>> _applyAiRiskScoring(List<DetectedHost> hosts) async {
    final prefs = await SharedPreferences.getInstance();

    bool readBool(List<String> keys) {
      for (final k in keys) {
        final v = prefs.getBool(k);
        if (v != null) return v;
      }
      return false;
    }

    final aiEnabled = readBool(['aiAssistantEnabled', 'ai.enabled', 'ai_assistant_enabled']);
    final riskScoringEnabled = readBool(['aiRiskScoring', 'ai.riskScoring', 'ai_risk_scoring']);

    if (!aiEnabled || !riskScoringEnabled) {
      return hosts;
    }

    final ai = SecurityAiService();

    return hosts.map((h) {
      final score = ai.scoreHost(h); // 0..100
      final RiskLevel risk;
      if (score >= 70) {
        risk = RiskLevel.high;
      } else if (score >= 40) {
        risk = RiskLevel.medium;
      } else {
        risk = RiskLevel.low;
      }

      return DetectedHost(
        address: h.address,
        hostname: h.hostname,
        openPorts: h.openPorts,
        risk: risk,
      );
    }).toList(growable: false);
  }

  // ---------- Scan mode handling (best-effort, avoids hard coupling) ----------

  String _scanModeName(dynamic settings) {
    try {
      final mode = settings.scanMode;
      final s = mode.toString().toLowerCase();
      if (s.contains('performance')) return 'performance';
      if (s.contains('paranoid')) return 'paranoid';
      if (s.contains('balanced')) return 'balanced';

      if (mode is String) {
        final m = mode.toLowerCase();
        if (m.contains('performance')) return 'performance';
        if (m.contains('paranoid')) return 'paranoid';
        if (m.contains('balanced')) return 'balanced';
      }

      if (mode is int) {
        if (mode == 0) return 'performance';
        if (mode == 2) return 'paranoid';
        return 'balanced';
      }
    } catch (_) {}
    return 'balanced';
  }

  bool _isParanoid(dynamic settings) => _scanModeName(settings) == 'paranoid';
  bool _isPerformance(dynamic settings) => _scanModeName(settings) == 'performance';

  // ---------- Args ----------

  List<String> _buildQuickSmartArgs(String target, dynamic settings) {
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

    final ssvc = SettingsService();
    if (ssvc.stealthScan && !args.contains('-sS') && !args.contains('-sT')) {
      args.insert(0, '-sS');
    }

    if (_isParanoid(settings)) {
      args.remove('-T4');
      args.insert(1, '-T3');
      final idx = args.indexOf('--host-timeout');
      if (idx != -1 && idx + 1 < args.length) {
        args[idx + 1] = '25s';
      }
    }

    args.add(target);
    return args;
  }

  List<String> _buildSmartScanArgs(String target, dynamic settings) {
    final args = <String>['-sV', '-T4'];

    final ssvc = SettingsService();
    if (ssvc.stealthScan && !args.contains('-sS') && !args.contains('-sT')) {
      args.insert(0, '-sS');
    }

    if (_isPerformance(settings)) {
      args.addAll(['--top-ports', '200']);
    } else if (_isParanoid(settings)) {
      args.addAll(['--top-ports', '5000', '-T3']);
    } else {
      args.addAll(['--top-ports', '1000']);
    }

    args.add(target);
    return args;
  }

  List<String> _buildFullScanArgs(String target, dynamic settings) {
    final args = <String>['-sV', '-p', '1-65535'];

    final ssvc = SettingsService();
    if (ssvc.stealthScan && !args.contains('-sS') && !args.contains('-sT')) {
      args.insert(0, '-sS');
    }

    if (_isPerformance(settings)) {
      args.add('-T4');
    } else if (_isParanoid(settings)) {
      args.add('-T2');
    } else {
      args.add('-T3');
    }

    args.add(target);
    return args;
  }

  // ---------- Nmap ----------

  Future<String> _runNmap(List<String> args) async {
    final result = await Process.run(
      'nmap',
      args,
      runInShell: true,
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );

    if (result.exitCode != 0) {
      final stderrStr = (result.stderr ?? '').toString();
      final lower = stderrStr.toLowerCase();
      final isPrivilegeError = lower.contains('requires root') ||
          lower.contains('privileged') ||
          lower.contains('permission denied') ||
          lower.contains('packet capture') ||
          lower.contains('npcap') ||
          lower.contains('not permitted');

      if (args.contains('-sS') && isPrivilegeError) {
        final fallbackArgs = List<String>.from(args);
        fallbackArgs.remove('-sS');
        if (!fallbackArgs.contains('-sT')) fallbackArgs.insert(0, '-sT');

        final retry = await Process.run(
          'nmap',
          fallbackArgs,
          runInShell: true,
          stdoutEncoding: utf8,
          stderrEncoding: utf8,
        );

        if (retry.exitCode != 0) {
          throw Exception('nmap failed (exit ${retry.exitCode}): ${(retry.stderr ?? '').toString()}');
        }

        return _sanitizeText((retry.stdout ?? '').toString());
      }

      throw Exception('nmap failed (exit ${result.exitCode}): $stderrStr');
    }

    return _sanitizeText((result.stdout ?? '').toString());
  }

  String _sanitizeText(String s) {
    var t = s.replaceAll('\uFFFD', '');
    const junk = <String>[
      'ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã…â€œ',
      'ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢',
      'ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬',
      'ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡',
      'ÃƒÆ’Ã‚Â¢',
    ];
    for (final j in junk) {
      t = t.replaceAll(j, '');
    }
    return t;
  }

  // ---------- Parsing ----------

  final RegExp _hostRegex = RegExp(r'^Nmap scan report for (.+)$');
  final RegExp _portLineRegex = RegExp(r'^(\d+)/(tcp|udp)\s+open\s+([\w\-\?\.\+]+)');

  List<DetectedHost> _parseNmapOutput(String stdoutStr) {
    final lines = stdoutStr.split('\n');

    final hosts = <DetectedHost>[];
    String? currentAddress;
    String? currentHostname;
    final currentPorts = <OpenPort>[];

    void flush() {
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

    for (final raw in lines) {
      final line = raw.trimRight();

      final hostMatch = _hostRegex.firstMatch(line);
      if (hostMatch != null) {
        flush();

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

        currentPorts.add(OpenPort(port: port, protocol: protocol, serviceName: service));
      }
    }

    flush();
    return hosts;
  }

  RiskLevel _calculateRiskLevel(List<OpenPort> ports) {
    if (ports.isEmpty) return RiskLevel.low;

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
