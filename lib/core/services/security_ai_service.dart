import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'scan_service.dart';

// NEW: wire in your created AI modules
import '../ai/ai_priority_fix_engine.dart';
import '../ai/router_fix_guides.dart';

enum AiSeverity { low, medium, high }

class AiInsight {
  String get summary => message;

  final String title;
  final String message;
  final AiSeverity severity;
  final String? action;
  final String? tag;

  const AiInsight({
    required this.title,
    required this.message,
    required this.severity,
    this.action,
    this.tag,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'message': message,
    'severity': severity.name,
    'action': action,
    'tag': tag,
  };

  @override
  String toString() => '$title: $message';
}

class SecurityAiService {
  // FIX: allow older calls like SecurityAiService(something) without breaking build
  SecurityAiService([Object? _ignored]);

  List<AiInsight> networkInsights({
    required ScanResult? result,
    required dynamic routerSummary,
  }) {
    if (result == null) return const <AiInsight>[];

    final flags = _readAiFlagsSync();
    if (!flags.aiAssistantEnabled) return const <AiInsight>[];

    final hosts = result.hosts;
    final insights = <AiInsight>[];

    // ==============================
    // (1) AI PRIORITY FIX ENGINE
    // ==============================
    final prio = AiPriorityFixEngine.recommend(result);
    if (prio != null) {
      insights.add(
        AiInsight(
          title: 'Fix this first: ${prio.title}',
          message:
          '${prio.why}\n\nEstimated impact:\n• Network health +${prio.estimatedHealthGain}%\n• Risk reduction ~${prio.estimatedRiskReduction}%',
          action: prio.actionSteps,
          severity: AiSeverity.high,
          tag: 'priority',
        ),
      );
    }

    // Existing: summary
    insights.add(_buildTopSummary(hosts));

    // Existing: explain findings
    if (flags.explainVulns) {
      insights.addAll(_explainFindings(hosts));
    }

    // Existing: unnecessary services
    if (flags.detectUnnecessaryServices) {
      insights.addAll(_unnecessaryServices(hosts));
    }

    // Existing: router hardening playbook
    if (flags.routerPlaybooks) {
      insights.addAll(_routerHardening(routerSummary, hosts));

      // ==========================================
      // (2) PLAIN-ENGLISH ROUTER FIX INSTRUCTIONS
      // ==========================================
      final guides = RouterFixGuides.forCommonHomeRisks(
        wps: true,
        upnp: true,
        dnsCheck: true,
        adminHarden: true,
      );

      for (final g in guides) {
        insights.add(
          AiInsight(
            title: g.title,
            message: g.summary,
            action:
            'Steps:\n- ${g.steps.join('\n- ')}${g.note != null ? '\n\nNote: ${g.note}' : ''}',
            severity: AiSeverity.medium,
            tag: 'router_guide',
          ),
        );
      }
    }

    // Existing: proactive warnings
    if (flags.proactiveWarnings) {
      insights.addAll(_proactiveWarnings(hosts));
    }

    // Existing: guided fixes
    if (flags.oneClickFixes) {
      insights.addAll(_guidedFixes(hosts));
    }

    return _dedupe(insights).take(12).toList();
  }

  List<AiInsight> deviceInsights({
    required DetectedHost host,
    ScanResult? result,
  }) {
    final flags = _readAiFlagsSync();
    if (!flags.aiAssistantEnabled) return const <AiInsight>[];

    final name = (host.hostname != null && host.hostname!.trim().isNotEmpty)
        ? host.hostname!.trim()
        : host.ip;

    final insights = <AiInsight>[];

    if (host.openPorts.isEmpty) {
      insights.add(
        AiInsight(
          title: 'No open ports detected',
          message: '$name does not appear to expose common TCP services.',
          severity: AiSeverity.low,
          action: flags.oneClickFixes
              ? 'Keep firmware/OS updated and re-scan weekly.'
              : null,
          tag: 'device',
        ),
      );
      return insights;
    }

    final sev = host.risk == RiskLevel.high
        ? AiSeverity.high
        : (host.risk == RiskLevel.medium ? AiSeverity.medium : AiSeverity.low);

    final topPorts =
    host.openPorts.take(6).map((p) => '${p.port}/${p.protocol}').join(', ');
    insights.add(
      AiInsight(
        title: 'Open services detected',
        message:
        '$name exposes ${host.openPorts.length} port(s): $topPorts${host.openPorts.length > 6 ? '…' : ''}',
        severity: sev,
        action: flags.oneClickFixes
            ? 'Disable unused services and restrict admin panels to LAN only.'
            : null,
        tag: 'device',
      ),
    );

    if (flags.explainVulns) {
      final ports = host.openPorts.map((p) => p.port).toSet();
      if (ports.contains(23)) {
        insights.add(
          const AiInsight(
            title: 'Telnet is unsafe',
            message: 'Telnet (23) is plaintext. Disable it and use SSH instead.',
            severity: AiSeverity.high,
            tag: 'telnet',
          ),
        );
      }
      if (ports.contains(445)) {
        insights.add(
          const AiInsight(
            title: 'SMB exposure detected',
            message: 'SMB (445) can be abused if shares are misconfigured.',
            severity: AiSeverity.high,
            tag: 'smb',
          ),
        );
      }
      if (ports.contains(3389)) {
        insights.add(
          const AiInsight(
            title: 'RDP should be restricted',
            message:
            'RDP (3389) is frequently brute-forced. Restrict to LAN/VPN or disable.',
            severity: AiSeverity.high,
            tag: 'rdp',
          ),
        );
      }
      if (ports.contains(1900)) {
        insights.add(
          const AiInsight(
            title: 'UPnP/SSDP exposure',
            message:
            'UPnP (1900) may allow unwanted automatic port mappings. Disable unless required.',
            severity: AiSeverity.medium,
            tag: 'upnp',
          ),
        );
      }
    }

    return insights;
  }

  int scoreHost(DetectedHost host) {
    int score = 10;

    switch (host.risk) {
      case RiskLevel.high:
        score += 45;
        break;
      case RiskLevel.medium:
        score += 25;
        break;
      case RiskLevel.low:
        score += 10;
        break;
    }

    for (final p in host.openPorts) {
      final port = p.port;
      if (port == 23) score += 25;
      if (port == 21) score += 18;
      if (port == 445) score += 22;
      if (port == 3389) score += 22;
      if (port == 1900) score += 14;
      if (port == 80) score += 6;
      if (port == 443) score += 3;
      if (port == 22) score += 8;
    }

    if (host.openPorts.length >= 8) score += 10;
    if (host.openPorts.length >= 15) score += 15;

    return max(0, min(100, score));
  }

  AiFlags _readAiFlagsSync() {
    return AiFlags.fromBestEffortCache();
  }

  AiInsight _buildTopSummary(List<DetectedHost> hosts) {
    final high = hosts.where((h) => h.risk == RiskLevel.high).length;
    final med = hosts.where((h) => h.risk == RiskLevel.medium).length;
    final low = hosts.where((h) => h.risk == RiskLevel.low).length;

    final sev =
    high > 0 ? AiSeverity.high : (med > 0 ? AiSeverity.medium : AiSeverity.low);

    return AiInsight(
      title: 'AI summary',
      message:
      'Devices: ${hosts.length}. High: $high, Medium: $med, Low: $low. Next: review highest-risk device first.',
      severity: sev,
      action: 'Open Devices → tap a High risk device → review open ports.',
      tag: 'summary',
    );
  }

  List<AiInsight> _routerHardening(dynamic routerSummary, List<DetectedHost> hosts) {
    final routerIp = _readRouterIp(routerSummary) ?? _guessRouterIp(hosts) ?? 'your router';

    return [
      AiInsight(
        title: 'Router hardening playbook',
        message:
        'Router: $routerIp. Disable WPS, disable UPnP unless required, update firmware, restrict remote admin.',
        severity: AiSeverity.medium,
        action: 'Open Router & IoT → follow the checklist and verify DNS servers.',
        tag: 'router',
      ),
    ];
  }

  List<AiInsight> _explainFindings(List<DetectedHost> hosts) {
    final insights = <AiInsight>[];

    for (final h in hosts) {
      final risky = h.openPorts.where((p) => _isCommonRiskPort(p.port)).toList();
      if (risky.isEmpty) continue;

      final worst = risky.map((p) => p.port).toSet().toList()..sort();
      final portsStr = worst.take(6).join(', ');

      final sev = h.risk == RiskLevel.high
          ? AiSeverity.high
          : (h.risk == RiskLevel.medium ? AiSeverity.medium : AiSeverity.low);

      insights.add(
        AiInsight(
          title: 'Explain findings: ${h.hostname ?? h.ip}',
          message: 'Sensitive services detected on: $portsStr. ${_explainPorts(worst)}',
          severity: sev,
          action: 'If not required, disable services or restrict to LAN only.',
          tag: 'device',
        ),
      );
    }

    if (insights.isEmpty) {
      insights.add(
        const AiInsight(
          title: 'Explain findings',
          message:
          'No obvious high-risk services detected. Keep firmware updated and disable UPnP/WPS if enabled.',
          severity: AiSeverity.low,
          tag: 'general',
        ),
      );
    }

    return insights;
  }

  List<AiInsight> _unnecessaryServices(List<DetectedHost> hosts) {
    final hits = <AiInsight>[];

    for (final h in hosts) {
      final ports = h.openPorts.map((p) => p.port).toSet();
      final flagged = <int>[];
      if (ports.contains(23)) flagged.add(23);
      if (ports.contains(21)) flagged.add(21);
      if (ports.contains(445)) flagged.add(445);
      if (ports.contains(1900)) flagged.add(1900);

      if (flagged.isEmpty) continue;

      hits.add(
        AiInsight(
          title: 'Unnecessary services: ${h.hostname ?? h.ip}',
          message:
          'Often-unnecessary risky services detected: ${flagged.join(', ')}. This increases attack surface.',
          severity: AiSeverity.high,
          action: 'Disable Telnet/FTP/UPnP/SMB where possible.',
          tag: 'service',
        ),
      );
    }

    if (hits.isEmpty) {
      hits.add(
        const AiInsight(
          title: 'Unnecessary services',
          message: 'No common unnecessary risky services detected. Keep UPnP off unless required.',
          severity: AiSeverity.low,
          tag: 'service',
        ),
      );
    }

    return hits;
  }

  List<AiInsight> _proactiveWarnings(List<DetectedHost> hosts) {
    final insights = <AiInsight>[];

    for (final h in hosts) {
      final ports = h.openPorts.map((p) => p.port).toSet();
      final hasHttp = ports.contains(80);
      final hasUpnp = ports.contains(1900);
      final hasSmb = ports.contains(445);
      final hasRdp = ports.contains(3389);

      if (hasHttp && hasUpnp) {
        insights.add(
          AiInsight(
            title: 'Proactive warning: UPnP + HTTP',
            message:
            '${h.hostname ?? h.ip} exposes HTTP (80) and UPnP (1900). UPnP is commonly abused.',
            severity: AiSeverity.medium,
            action: 'Disable UPnP unless required. Keep admin pages LAN-only.',
            tag: 'warning',
          ),
        );
      }

      if (hasSmb && hasRdp) {
        insights.add(
          AiInsight(
            title: 'Proactive warning: SMB + RDP',
            message:
            '${h.hostname ?? h.ip} exposes SMB (445) and RDP (3389). This combo is frequently targeted.',
            severity: AiSeverity.high,
            action: 'Restrict access and disable services if not required.',
            tag: 'warning',
          ),
        );
      }
    }

    if (insights.isEmpty) {
      insights.add(
        const AiInsight(
          title: 'Proactive warnings',
          message: 'No risky service combinations detected. Continue patching devices and router firmware.',
          severity: AiSeverity.low,
          tag: 'warning',
        ),
      );
    }

    return insights;
  }

  List<AiInsight> _guidedFixes(List<DetectedHost> hosts) {
    final insights = <AiInsight>[];

    final highHosts = hosts.where((h) => h.risk == RiskLevel.high).toList();
    if (highHosts.isEmpty) {
      insights.add(
        const AiInsight(
          title: 'One-click fixes (guided)',
          message: 'No critical exposures detected. Enable proactive warnings and re-scan weekly.',
          severity: AiSeverity.low,
          tag: 'fix',
        ),
      );
      return insights;
    }

    final h = highHosts.first;
    final ports = h.openPorts.map((p) => p.port).toSet();

    final steps = <String>[];
    if (ports.contains(23)) steps.add('Disable Telnet and use SSH if remote access is needed.');
    if (ports.contains(21)) steps.add('Disable FTP; use SFTP/HTTPS instead.');
    if (ports.contains(445)) steps.add('Disable SMB guest access; restrict shares to local users.');
    if (ports.contains(1900)) steps.add('Disable UPnP in router unless required.');
    if (ports.contains(3389)) steps.add('Disable RDP or restrict it to LAN/VPN.');
    if (steps.isEmpty) steps.add('Close unused services and restrict admin panels to LAN only.');

    insights.add(
      AiInsight(
        title: 'One-click fixes (guided): ${h.hostname ?? h.ip}',
        message: 'Suggested fixes:\n- ${steps.join('\n- ')}',
        severity: AiSeverity.high,
        action: 'Apply fixes → run Smart Scan again → confirm risk drops.',
        tag: 'fix',
      ),
    );

    return insights;
  }

  List<AiInsight> _dedupe(List<AiInsight> input) {
    final seen = <String>{};
    final out = <AiInsight>[];
    for (final i in input) {
      final key = '${i.title}::${i.message}::${i.severity.name}';
      if (seen.add(key)) out.add(i);
    }
    return out;
  }

  bool _isCommonRiskPort(int port) {
    return port == 21 ||
        port == 23 ||
        port == 22 ||
        port == 80 ||
        port == 443 ||
        port == 445 ||
        port == 3389 ||
        port == 1900;
  }

  String _explainPorts(List<int> ports) {
    final parts = <String>[];
    for (final p in ports.take(8)) {
      switch (p) {
        case 23:
          parts.add('Telnet sends credentials in plain text.');
          break;
        case 21:
          parts.add('FTP is often insecure and commonly brute-forced.');
          break;
        case 445:
          parts.add('SMB can enable lateral movement and ransomware spread.');
          break;
        case 3389:
          parts.add('RDP is frequently brute-forced and should be restricted.');
          break;
        case 1900:
          parts.add('UPnP may allow unwanted automatic port mappings.');
          break;
        case 80:
          parts.add('HTTP admin panels should be LAN-only and protected.');
          break;
        case 22:
          parts.add('SSH should be restricted and use strong credentials/keys.');
          break;
        case 443:
          parts.add('HTTPS is safer, but admin panels still need strong passwords.');
          break;
        default:
          parts.add('Port $p may expose a network service.');
      }
    }
    return parts.isEmpty ? '' : parts.join(' ');
  }

  String? _readRouterIp(dynamic routerSummary) {
    if (routerSummary == null) return null;
    try {
      final v = (routerSummary as dynamic).ip;
      if (v is String && v.trim().isNotEmpty) return v.trim();
    } catch (_) {}
    try {
      final v = (routerSummary as dynamic).address;
      if (v is String && v.trim().isNotEmpty) return v.trim();
    } catch (_) {}
    try {
      final v = (routerSummary as dynamic).router;
      if (v is String && v.trim().isNotEmpty) return v.trim();
    } catch (_) {}
    try {
      final v = (routerSummary as dynamic).routerAddress;
      if (v is String && v.trim().isNotEmpty) return v.trim();
    } catch (_) {}
    return null;
  }

  String? _guessRouterIp(List<DetectedHost> hosts) {
    final ips = hosts.map((h) => h.ip).toSet();
    for (final c in ['192.168.1.1', '192.168.0.1', '10.0.0.1']) {
      if (ips.contains(c)) return c;
    }
    return null;
  }
}

class AiFlags {
  final bool aiAssistantEnabled;
  final bool explainVulns;
  final bool oneClickFixes;
  final bool riskScoring;
  final bool routerPlaybooks;
  final bool detectUnnecessaryServices;
  final bool proactiveWarnings;

  const AiFlags({
    required this.aiAssistantEnabled,
    required this.explainVulns,
    required this.oneClickFixes,
    required this.riskScoring,
    required this.routerPlaybooks,
    required this.detectUnnecessaryServices,
    required this.proactiveWarnings,
  });

  static AiFlags fromBestEffortCache() {
    return const AiFlags(
      aiAssistantEnabled: true,
      explainVulns: true,
      oneClickFixes: true,
      riskScoring: true,
      routerPlaybooks: true,
      detectUnnecessaryServices: true,
      proactiveWarnings: true,
    );
  }

  static Future<AiFlags> fromPrefs() async {
    final p = await SharedPreferences.getInstance();

    bool readBool(List<String> keys) {
      for (final k in keys) {
        final v = p.getBool(k);
        if (v != null) return v;
      }
      return false;
    }

    return AiFlags(
      aiAssistantEnabled:
      readBool(['aiAssistantEnabled', 'ai.enabled', 'ai_assistant_enabled']),
      explainVulns:
      readBool(['aiExplainVuln', 'ai.explainVuln', 'ai_explain_vulns']),
      oneClickFixes:
      readBool(['aiOneClickFix', 'ai.oneClickFix', 'ai_one_click_fixes']),
      riskScoring:
      readBool(['aiRiskScoring', 'ai.riskScoring', 'ai_risk_scoring']),
      routerPlaybooks: readBool(
          ['aiRouterHardening', 'ai.routerHardening', 'ai_router_playbooks']),
      detectUnnecessaryServices: readBool([
        'aiDetectUnnecessaryServices',
        'ai.detectUnnecessaryServices',
        'ai_detect_unnecessary_services'
      ]),
      proactiveWarnings:
      readBool(['aiProactiveWarnings', 'ai.proactiveWarnings', 'ai_proactive_warnings']),
    );
  }
}

