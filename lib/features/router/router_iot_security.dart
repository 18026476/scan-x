// lib/features/router/router_iot_security.dart
//
// Router & IoT security analysis built on top of existing scan data.
// This service MUST remain honest:
// - Only "detect" what we can infer from scan results.
// - For items that require router login / firmware database / credential validation,
//   we generate advisory issues (still functional because toggles gate output).

import 'package:scanx_app/core/services/scan_service.dart';
import 'package:scanx_app/core/services/settings_service.dart';

/// Types of router / IoT issues we may flag.
enum RouterIotIssueType {
  routerNotFound,
  riskyRouterPorts,
  possibleUpnp,
  possibleWps,
  possibleDnsHijack,

  // Advisory (still functional toggles)
  routerWeakPasswordAdvisory,
  routerOutdatedFirmwareAdvisory,

  // IoT
  iotHighRisk,
  iotMediumRisk,

  // Advisory (still functional toggles)
  iotOutdatedFirmwareAdvisory,
  iotDefaultPasswordsAdvisory,
  iotVulnDbAdvisory,
  iotAutoRecommendations,
}

class RouterIotIssue {
  final RouterIotIssueType type;
  final String title;
  final String description;
  final bool isHighSeverity;

  const RouterIotIssue({
    required this.type,
    required this.title,
    required this.description,
    this.isHighSeverity = false,
  });
}

class RouterIotSecuritySummary {
  final DetectedHost? routerHost;
  final int totalIotDevices;
  final int highRiskIotDevices;
  final int mediumRiskIotDevices;
  final List<RouterIotIssue> issues;

  bool get hasRouter => routerHost != null;
  bool get hasIssues => issues.isNotEmpty;

  const RouterIotSecuritySummary({
    required this.routerHost,
    required this.totalIotDevices,
    required this.highRiskIotDevices,
    required this.mediumRiskIotDevices,
    required this.issues,
  });
}

/// High-level analyser that looks at existing scan results
/// and generates router / IoT security insights.
class RouterIotSecurityService {
  final SettingsService _settings;

  RouterIotSecurityService() : _settings = SettingsService();

  /// Build a summary from whatever host list the scan engine produced.
  RouterIotSecuritySummary buildSummary(List<DetectedHost> detectedHosts) {
    final router = _pickRouter(detectedHosts);
    final iotDevices = _pickIotDevices(detectedHosts);

    final issues = <RouterIotIssue>[];

    // ----------------- Router analysis -----------------
    if (router == null) {
      issues.add(const RouterIotIssue(
        type: RouterIotIssueType.routerNotFound,
        title: 'Review recommended',
        description:
            'SCAN-X could not identify your router. Ensure you scanned the correct subnet (e.g. 192.168.0.0/24).',
      ));
    } else {
      // 1) Dangerous management ports
      if (_settings.routerOpenPorts) {
        final risky = _detectRiskyRouterPorts(router);
        if (risky.isNotEmpty) {
          issues.add(RouterIotIssue(
            type: RouterIotIssueType.riskyRouterPorts,
            title: 'Action needed',
            description:
                'Your router appears to expose high-risk ports: ${risky.join(", ")}. Restrict access, or close them in the router UI.',
            isHighSeverity: true,
          ));
        }
      }

      // 2) UPnP (port 1900) - based on scan open ports
      if (_settings.routerUpnpCheck) {
        if (_hostHasPort(router, 1900)) {
          issues.add(const RouterIotIssue(
            type: RouterIotIssueType.possibleUpnp,
            title: 'Action needed',
            description:
                'Port 1900 (SSDP/UPnP) may be open. Disable UPnP in your router unless you need automatic port forwarding.',
            isHighSeverity: true,
          ));
        }
      }

      // 3) DNS hijack - advisory (honest)
      if (_settings.routerDnsHijack) {
        issues.add(const RouterIotIssue(
          type: RouterIotIssueType.possibleDnsHijack,
          title: 'Review recommended',
          description:
              'SCAN-X cannot directly confirm DNS hijacking from a LAN scan alone. Log into your router and verify DNS servers are set to trusted providers (e.g. your ISP, Cloudflare 1.1.1.1, Google 8.8.8.8).',
        ));
      }

      // 4) WPS - advisory
      if (_settings.routerWpsCheck) {
        issues.add(const RouterIotIssue(
          type: RouterIotIssueType.possibleWps,
          title: 'Review recommended',
          description:
              'WPS is often insecure. If your router has WPS enabled, disable it in Wireless Settings.',
        ));
      }

      // 5) Weak/default router password - advisory gated by toggle (functional)
      if (_settings.routerWeakPassword) {
        issues.add(const RouterIotIssue(
          type: RouterIotIssueType.routerWeakPasswordAdvisory,
          title: 'Action recommended',
          description:
              'SCAN-X cannot validate your router admin password automatically. Check your router admin login and ensure: (1) default credentials are changed, (2) admin password is strong and unique, (3) remote admin is disabled unless required.',
          isHighSeverity: true,
        ));
      }

      // 6) Outdated firmware - advisory gated by toggle (functional)
      if (_settings.routerOutdatedFirmware) {
        issues.add(const RouterIotIssue(
          type: RouterIotIssueType.routerOutdatedFirmwareAdvisory,
          title: 'Action recommended',
          description:
              'SCAN-X cannot reliably determine router firmware age without router model/firmware metadata. Log into your router and check for firmware updates. Apply updates and reboot the router afterwards.',
        ));
      }
    }

    // ----------------- IoT devices analysis -----------------
    int high = 0;
    int med = 0;

    for (final host in iotDevices) {
      final risk = _estimateIotRisk(host);
      if (risk == _SimpleRisk.high) high++;
      if (risk == _SimpleRisk.medium) med++;
    }

    if (high > 0) {
      issues.add(RouterIotIssue(
        type: RouterIotIssueType.iotHighRisk,
        title: 'Action needed',
        description:
            '$high IoT devices expose sensitive services (e.g. Telnet/FTP/SMB). Change default passwords and restrict remote access.',
        isHighSeverity: true,
      ));
    }

    if (med > 0) {
      issues.add(RouterIotIssue(
        type: RouterIotIssueType.iotMediumRisk,
        title: 'Review recommended',
        description:
            '$med IoT devices show questionable exposure. Check for firmware updates and review their network access.',
      ));
    }

    // Advisory IoT checks (gated by settings — makes toggles functional)
    if (iotDevices.isNotEmpty) {
      if (_settings.iotOutdatedFirmware) {
        issues.add(const RouterIotIssue(
          type: RouterIotIssueType.iotOutdatedFirmwareAdvisory,
          title: 'Review recommended',
          description:
              'IoT firmware age cannot be confirmed from a basic port scan. For each IoT device, open the vendor app/admin page and check for firmware updates. Prioritize cameras, DVRs, and doorbells.',
        ));
      }

      if (_settings.iotDefaultPasswords) {
        issues.add(const RouterIotIssue(
          type: RouterIotIssueType.iotDefaultPasswordsAdvisory,
          title: 'Action recommended',
          description:
              'SCAN-X does not attempt credential testing. For IoT devices, ensure default credentials are changed, disable guest/admin accounts where possible, and enable auto-updates if supported.',
          isHighSeverity: true,
        ));
      }

      if (_settings.iotVulnDbMatch) {
        issues.add(const RouterIotIssue(
          type: RouterIotIssueType.iotVulnDbAdvisory,
          title: 'Review recommended',
          description:
              'CVE matching requires device fingerprinting + a vulnerability feed. For now, treat exposed services (Telnet/FTP/UPnP) as high priority and keep device firmware updated.',
        ));
      }

      if (_settings.iotAutoRecommendations) {
        final recs = <String>[];

        recs.add('Put IoT devices on a separate Wi-Fi network (Guest/IoT SSID) if your router supports it.');
        recs.add('Disable remote access/port forwarding for IoT devices unless required.');
        recs.add('Prefer WPA2/WPA3, disable WPS, and rotate Wi-Fi password periodically.');

        if (high > 0) {
          recs.add('High-risk devices detected: disable Telnet/FTP/SMB where possible and restrict access via firewall rules.');
        }
        if (router != null && _settings.routerUpnpCheck && _hostHasPort(router, 1900)) {
          recs.add('UPnP may be enabled: disable UPnP to prevent automatic port-forwarding exposure.');
        }

        issues.add(RouterIotIssue(
          type: RouterIotIssueType.iotAutoRecommendations,
          title: 'Recommendations',
          description: recs.map((e) => '• $e').join('\n'),
        ));
      }
    }

    return RouterIotSecuritySummary(
      routerHost: router,
      totalIotDevices: iotDevices.length,
      highRiskIotDevices: high,
      mediumRiskIotDevices: med,
      issues: issues,
    );
  }

  // -------------------------- HELPERS --------------------------

  /// Router heuristic:
  /// - IP ending in .1 or .254
  /// - otherwise, first host in the list
  DetectedHost? _pickRouter(List<DetectedHost> hosts) {
    if (hosts.isEmpty) return null;

    for (final h in hosts) {
      final ip = h.ip;
      if (ip.endsWith('.1') || ip.endsWith('.254')) return h;
    }
    return hosts.first;
  }

  /// IoT heuristic: ONLY use fields that exist (hostname/ip).
  /// This avoids crashing when different models are used.
  List<DetectedHost> _pickIotDevices(List<DetectedHost> hosts) {
    final keywords = <String>[
      'camera','cctv','tv','chromecast','cast','speaker','echo','plug','light','bulb','thermostat','hub','doorbell','ring','nest',
    ];

    return hosts.where((h) {
      final hn = (h.hostname ?? '').toLowerCase();
      final ip = h.ip.toLowerCase();
      final combined = '$hn $ip';
      return keywords.any((k) => combined.contains(k));
    }).toList();
  }

  List<int> _detectRiskyRouterPorts(DetectedHost host) {
    final ports = _safePorts(host);
    const risky = {21, 22, 23, 80, 443, 8080, 7547, 3389, 445, 1900};
    return ports.where((p) => risky.contains(p)).toList();
  }

  /// Normalise whatever `openPorts` shape you have into a simple List<int>.
  /// Current model: List<OpenPort> (DetectedHost.openPorts)
  List<int> _safePorts(DetectedHost host) {
    final raw = host.openPorts;
    final list = <int>[];
    for (final p in raw) {
      list.add(p.port);
    }
    return list;
  }

  bool _hostHasPort(DetectedHost host, int port) => _safePorts(host).contains(port);

  _SimpleRisk _estimateIotRisk(DetectedHost host) {
    final ports = _safePorts(host);
    if (ports.any((p) => p == 23 || p == 21 || p == 445)) return _SimpleRisk.high;
    if (ports.length >= 3) return _SimpleRisk.medium;
    return _SimpleRisk.low;
  }
}

enum _SimpleRisk { low, medium, high }
