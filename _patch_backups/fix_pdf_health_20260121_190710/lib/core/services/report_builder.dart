import 'package:scanx_app/core/services/scan_service.dart';
import 'package:scanx_app/core/services/settings_service.dart';
import 'package:scanx_app/features/router/router_iot_security.dart';

class ReportBuilder {
  /// V16: Canonical report JSON used by PdfReportService.
  ///
  /// Key guarantees:
  /// - scanMeta always filled (scanTimeUtc/targetCidr/scanMode)
  /// - devicesInScan always from ScanResult.hosts
  /// - device recommendations present (ports + risk)
  /// - findings include router/iot + host discovered + open ports detected
  /// - topOpenPorts computed from all devices
  /// - severityDistribution computed from findings
  /// - mlInsights based on ALL devices found (client-safe, plain English)
  Map<String, dynamic> buildReportJson({
    required ScanResult result,
    required String scanModeLabel,
    String? targetCidr,
  }) {
    final settings = SettingsService();
    final nowUtc = DateTime.now().toUtc().toIso8601String();

    // --- Devices from Smart Scan result.hosts
    final devicesInScan = _scanxV16DevicesFromResult(result);

    // --- Router/IoT findings (if your RouterIotSecurityService is present)
    final findings = <Map<String, dynamic>>[];
    try {
      final routerIot = RouterIotSecurityService().buildSummary(result.hosts);
      for (final issue in routerIot.issues) {
        final severity = issue.isHighSeverity ? 'High' : 'Medium';
        findings.add({
          'id': issue.type.name,
          'title': issue.title,
          'severity': severity,
          'status': 'Detected',
          'deviceIp': routerIot.routerHost?.address ?? '',
          'evidence': issue.description,
          'recommendation': _scanxV16RecommendationForRouterIot(issue.type),
        });
      }
    } catch (_) {
      // If RouterIotSecurityService is not available / fails, continue with host-based findings.
    }

    // --- Host discovered + open ports detected cards (per device)
    for (final d in devicesInScan) {
      final ip = (d['ip'] ?? '-').toString();
      final name = (d['name'] ?? '-').toString();
      final risk = (d['risk'] ?? 'Low').toString();
      final ports = (d['openPorts'] is List) ? (d['openPorts'] as List).map((x)=>int.tryParse(x.toString()) ?? -1).where((x)=>x>0).toList() : <int>[];

      findings.add({
        'id': 'host_discovered_$ip',
        'title': 'Host discovered',
        'severity': (risk == 'High') ? 'High' : (risk == 'Medium' ? 'Medium' : 'Low'),
        'status': 'Detected',
        'deviceIp': ip,
        'evidence': 'Device: $name | Risk: $risk | Open ports: ${ports.isEmpty ? '-' : ports.join(', ')}',
        'recommendation': 'Confirm this device is expected. Remove unknown devices and review router DHCP/connected clients list.',
      });

      if (ports.isNotEmpty) {
        findings.add({
          'id': 'open_ports_$ip',
          'title': 'Open ports detected',
          'severity': _scanxV16PortsSeverity(ports),
          'status': 'Detected',
          'deviceIp': ip,
          'evidence': 'Open ports: ${ports.join(', ')}',
          'recommendation': _scanxV16PortsRecommendation(ports),
        });
      }
    }

    // --- Score + label (self-contained so we donâ€™t depend on other services)
    final score = _scanxV16ComputeRiskScore(devicesInScan, findings);
    final rating = _scanxV16RiskLabel(score);
    final health = (100 - score).clamp(0, 100);

    // --- Top ports
    final topOpenPorts = _scanxV16TopPortsFromDevices(devicesInScan, topN: 10);

    // --- Severity distribution
    final severityDistribution = _scanxV16SeverityDistribution(findings);

    // --- Settings snapshot (matches your screenshot toggles)
    final settingsSnapshot = <String, bool>{
      'aiAssistantEnabled': settings.aiAssistantEnabled,
      'aiExplainVuln': settings.aiExplainVuln,
      'aiOneClickFix': settings.aiOneClickFix,
      'aiRiskScoring': settings.aiRiskScoring,
      'aiRouterHardening': settings.aiRouterHardening,
      'aiDetectUnnecessaryServices': settings.aiDetectUnnecessaryServices,
      'aiProactiveWarnings': settings.aiProactiveWarnings,

      'packetSnifferLite': settings.packetSnifferLite,
      'wifiDeauthDetection': settings.wifiDeauthDetection,
      'rogueApDetection': settings.rogueApDetection,
      'hiddenSsidDetection': settings.hiddenSsidDetection,

      'betaBehaviourThreatDetection': settings.betaBehaviourThreatDetection,
      'betaLocalMlProfiling': settings.betaLocalMlProfiling,
      'betaIotFingerprinting': settings.betaIotFingerprinting,
    };

    // --- ML insights (client-safe, based on ALL devices found)
    final mlInsights = _scanxV16MlInsights(
      devicesInScan: devicesInScan,
      topOpenPorts: topOpenPorts,
      severityDistribution: severityDistribution,
      riskScore: score,
      settings: settingsSnapshot,
    );

    // --- scanMeta always filled
    final scanMeta = <String, dynamic>{
      'scanTimeLocal': result.finishedAt.toLocal().toIso8601String(),
      'startedAtLocal': result.startedAt.toLocal().toIso8601String(),
      'finishedAtLocal': result.finishedAt.toLocal().toIso8601String(),
      'durationSec': result.finishedAt.difference(result.startedAt).inSeconds,
      'scanTimeUtc': nowUtc,
      'targetCidr': scanxEnsureCidr(((targetCidr == null || targetCidr.trim().isEmpty) ? '-' : targetCidr.trim()).toString()),
      'scanMode': scanModeLabel,
    };

    return <String, dynamic>{
      'scanMeta': scanMeta,

      // Rating parity block (used by PDF)
      'riskScore': <String, dynamic>{
        'score': score,
        'rating': rating,
        'risk': score,
        'label': rating,
        'health': health,
      },

      'devicesInScan': devicesInScan,
      'topOpenPorts': topOpenPorts,
      'findings': findings,
      'severityDistribution': severityDistribution,
      'settingsSnapshot': settingsSnapshot,
      'mlInsights': mlInsights,

      'summary': <String, dynamic>{
        'hosts': result.hosts.length,
        'devicesWithOpenPorts': devicesInScan.where((d) {
          final p = d['openPorts'];
          return p is List && p.isNotEmpty;
        }).length,
      },
    };
  }
}

// ------------------------------
// Helpers (V16, uniquely named)
// ------------------------------

List<Map<String, dynamic>> _scanxV16DevicesFromResult(ScanResult result) {
  final devices = <Map<String, dynamic>>[];

  for (final host in result.hosts) {
    final ip = (host.address).toString();
    final name = (host.hostname ?? '').toString().trim().isEmpty
        ? host.address.toString()
        : host.hostname!.toString().trim();

    // openPorts shape in this repo: List<OpenPort> (port/protocol/serviceName)
    final ports = <int>[];
    try {
      for (final p in host.openPorts) {
        ports.add(p.port);
      }
    } catch (_) {}
    ports.sort();

    final risk = _scanxV16HostRiskLabel(host, ports);
    final recs = _scanxV16RecommendationsForHost(host, ports, risk);

    devices.add(<String, dynamic>{
      'ip': ip,
      'name': name.isEmpty ? '-' : name,
      'openPorts': ports,
      'risk': risk,
      'recommendations': recs,
    });
  }

  return devices;
}

String _scanxV16HostRiskLabel(dynamic host, List<int> ports) {
  // Prefer host.risk if available
  try {
    final r = (host as dynamic).risk;
    if (r != null) {
      final s = r.toString().toLowerCase();
      if (s.contains('high')) return 'High';
      if (s.contains('medium')) return 'Medium';
      if (s.contains('low')) return 'Low';
    }
  } catch (_) {}

  // Fallback from ports
  final risky = ports.any((p) => p == 21 || p == 23 || p == 445 || p == 3389);
  if (risky) return 'High';
  if (ports.isNotEmpty) return 'Medium';
  return 'Low';
}

List<String> _scanxV16RecommendationsForHost(dynamic host, List<int> ports, String riskLabel) {
  final recs = <String>[];

  // Port-based guidance
  if (ports.contains(23)) recs.add('Telnet detected (port 23). Disable Telnet; use SSH if remote access is required.');
  if (ports.contains(21)) recs.add('FTP detected (port 21). Prefer SFTP/FTPS or disable FTP if not required.');
  if (ports.contains(445)) recs.add('SMB detected (port 445). Restrict SMB to LAN only and disable if not required.');
  if (ports.contains(3389)) recs.add('RDP detected (port 3389). Disable if not needed; otherwise restrict + strong passwords.');
  if (ports.contains(80) || ports.contains(443)) recs.add('Web service detected (HTTP/HTTPS). Ensure firmware is updated and admin panels are protected.');

  if (ports.isEmpty) {
    recs.add('No open ports were detected. Maintain updates and strong passwords.');
  } else {
    recs.add('If these ports are not required, close them. If required, restrict exposure with firewall rules and least-privilege access.');
  }

  if (riskLabel == 'High') {
    recs.add('High-risk device: prioritize firmware updates, password changes, and service hardening.');
  } else if (riskLabel == 'Medium') {
    recs.add('Medium-risk device: review open services and ensure strong passwords and patching.');
  }

  // Deduplicate
  final out = <String>[];
  for (final r in recs) {
    if (!out.contains(r)) out.add(r);
  }
  return out;
}

List<Map<String, dynamic>> _scanxV16TopPortsFromDevices(List<Map<String, dynamic>> devices, {int topN = 10}) {
  final hist = <int, int>{};

  for (final d in devices) {
    final ports = d['openPorts'];
    if (ports is List) {
      for (final p in ports) {
        final n = (p is int) ? p : int.tryParse(p.toString());
        if (n == null) continue;
        hist[n] = (hist[n] ?? 0) + 1;
      }
    }
  }

  final top = hist.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  return top.take(topN).map((e) => <String, dynamic>{'port': e.key, 'count': e.value}).toList();
}

Map<String, int> _scanxV16SeverityDistribution(List<Map<String, dynamic>> findings) {
  int hi = 0, med = 0, low = 0;

  for (final f in findings) {
    final sev = (f['severity'] ?? '').toString().toLowerCase();
    if (sev == 'high' || sev == 'critical') hi++;
    else if (sev == 'medium') med++;
    else if (sev.isNotEmpty) low++;
  }

  return <String, int>{
    'High/Critical': hi,
    'Medium': med,
    'Low': low,
  };
}

int _scanxV16ComputeRiskScore(List<Map<String, dynamic>> devices, List<Map<String, dynamic>> findings) {
  // Simple deterministic risk score (0-100)
  int score = 0;

  // Device risk weighting
  for (final d in devices) {
    final r = (d['risk'] ?? 'Low').toString();
    if (r == 'High') score += 15;
    else if (r == 'Medium') score += 8;
    else score += 2;
  }

  // Findings add weight (router issues + per-device cards)
  for (final f in findings) {
    final sev = (f['severity'] ?? '').toString().toLowerCase();
    if (sev == 'high' || sev == 'critical') score += 10;
    else if (sev == 'medium') score += 6;
    else if (sev.isNotEmpty) score += 2;
  }

  if (score > 100) score = 100;
  return score;
}

String _scanxV16RiskLabel(int score) {
  if (score >= 80) return 'Critical';
  if (score >= 50) return 'High';
  if (score >= 20) return 'Medium';
  return 'Low';
}

String _scanxV16PortsSeverity(List<int> ports) {
  if (ports.any((p) => p == 23 || p == 445 || p == 3389)) return 'High';
  if (ports.any((p) => p == 21 || p == 80 || p == 8080 || p == 443)) return 'Medium';
  return 'Low';
}

String _scanxV16PortsRecommendation(List<int> ports) {
  final hasTelnet = ports.contains(23);
  final hasSmb = ports.contains(445);
  final hasRdp = ports.contains(3389);
  final hasFtp = ports.contains(21);

  if (hasTelnet || hasSmb || hasRdp || hasFtp) {
    return 'Restrict access or close exposed ports. Disable services if not required. Ensure firewall rules limit LAN/WAN exposure and patch devices.';
  }
  return 'Review why these ports are open. If not required, close them. If required, enforce strong auth, patching, and least-access firewall rules.';
}

String _scanxV16RecommendationForRouterIot(dynamic t) {
  // Keep this flexible (RouterIotIssueType enum may differ across versions)
  final name = t.toString();
  if (name.contains('iotMediumRisk')) return 'Review IoT device security: update firmware, change passwords, disable unused services, and isolate IoT to guest/VLAN.';
  if (name.contains('riskyRouterPorts')) return 'Review router port forwarding. Close exposed management/WAN ports and disable remote admin unless required.';
  if (name.contains('possibleUpnp')) return 'Disable UPnP unless you explicitly need it. Reboot router after changes.';
  if (name.contains('possibleWps')) return 'Disable WPS. Use WPA2/WPA3 and a strong Wi-Fi password.';
  if (name.contains('possibleDnsHijack')) return 'Verify router DNS settings and admin password. Update firmware if available.';
  if (name.contains('iotHighRisk')) return 'Update IoT firmware, change default passwords, and isolate IoT to guest/VLAN if possible.';
  if (name.contains('routerNotFound')) return 'Ensure you are scanning the correct CIDR range and that the router IP is within target.';
  return 'Review router and IoT security settings. Apply firmware updates and harden remote access.';
}

List<String> _scanxV16MlInsights({
  required List<Map<String, dynamic>> devicesInScan,
  required List<Map<String, dynamic>> topOpenPorts,
  required Map<String, int> severityDistribution,
  required int riskScore,
  required Map<String, bool> settings,
}) {
  final lines = <String>[];

  final devCount = devicesInScan.length;
  int totalPorts = 0;
  final uniq = <int>{};
  int riskyHits = 0;

  for (final d in devicesInScan) {
    final ports = (d['openPorts'] is List) ? (d['openPorts'] as List) : const <dynamic>[];
    totalPorts += ports.length;
    for (final p in ports) {
      final n = (p is int) ? p : int.tryParse(p.toString());
      if (n == null) continue;
      uniq.add(n);
      if (n == 21 || n == 23 || n == 445 || n == 3389) riskyHits++;
    }
  }

  lines.add('Plain English: SCAN-X uses pattern-based indicators (beta). It does not exploit devices. It highlights likely risk drivers to review.');

  lines.add('Network summary: $devCount device(s) discovered; $totalPorts open port(s) observed; $riskyHits high-risk port hit(s); risk score: $riskScore / 100.');

  // Toggle-aware messages (so â€œML settings must be functionalâ€ is reflected)
  final localProfiling = settings['betaLocalMlProfiling'] == true;
  final behaviour = settings['betaBehaviourThreatDetection'] == true;
  final iotFp = settings['betaIotFingerprinting'] == true;

  if (!localProfiling && !behaviour && !iotFp) {
    lines.add('ML modules are currently OFF in Settings. Enable â€œBeta MLâ€ toggles to increase the depth of ML insights.');
    return lines;
  }

  if (behaviour) {
    if (riskyHits > 0) {
      lines.add('Behaviour signals: detected risky-service exposure (e.g., SMB/RDP/Telnet/FTP).');
    } else {
      lines.add('Behaviour signals: no risky-service exposure patterns detected across scanned devices.');
    }
  }

  if (localProfiling) {
    lines.add('Local profiling: unique ports seen across the network: ${uniq.length}.');
    if (topOpenPorts.isNotEmpty) {
      final top = topOpenPorts.take(5).map((e) => (e['port'] ?? '-').toString()).toList();
      lines.add('Local profiling: top open port(s): ${top.join(', ')}.');
    }
  }

  if (iotFp) {
    lines.add('IoT fingerprinting: beta mode (non-verified). Review unknown devices and isolate IoT to guest/VLAN.');
  }

  return lines;
}

/* SCANX_V16C_CIDR_BEGIN */
// V16C: CIDR normalization for report meta.
// - If already has / => keep
// - If looks like IPv4 without /:
//     - if ends with .0 => assume /24 (common LAN CIDR target)
//     - else => /32 (single-host target)
String scanxEnsureCidr(String input) {
  final s = input.trim();
  if (s.isEmpty) return '-';
  if (s.contains('/')) return s;

  final ipv4 = RegExp(r'^\d{1,3}(\.\d{1,3}){3}$');
  if (!ipv4.hasMatch(s)) return s;

  final parts = s.split('.');
  if (parts.length != 4) return s;

  for (final p in parts) {
    final n = int.tryParse(p);
    if (n == null || n < 0 || n > 255) return s;
  }

  final last = int.parse(parts[3]);
  if (last == 0) return '/24';
  return '/32';
}
/* SCANX_V16C_CIDR_END */


