// lib/features/router/router_iot_security.dart
//
// Router & IoT security analysis built on top of existing Nmap scan data.
// Does NOT modify ScanService or the scan engine.

import 'package:scanx_app/core/services/scan_service.dart';
import 'package:scanx_app/core/services/settings_service.dart';

/// Types of router / IoT issues we may flag.
enum RouterIotIssueType {
  routerNotFound,
  riskyRouterPorts,
  possibleUpnp,
  possibleWps,
  possibleDnsHijack,
  iotHighRisk,
  iotMediumRisk,
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
  ///
  /// This is intentionally tolerant of different host shapes.
  RouterIotSecuritySummary buildSummary(List hosts) {
    // Only keep DetectedHost instances if that type exists in your ScanService.
    final detectedHosts = hosts.whereType<DetectedHost>().toList();

    final router = _pickRouter(detectedHosts);
    final iotDevices = _pickIotDevices(detectedHosts);

    final issues = <RouterIotIssue>[];

    // ----------------- Router analysis -----------------
    if (router == null) {
      issues.add(const RouterIotIssue(
        type: RouterIotIssueType.routerNotFound,
        title: 'Router not detected',
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
            title: 'Router exposes risky management ports',
            description:
                'Your router appears to expose high-risk ports: ${risky.join(", ")}. Restrict access, or close them on the router UI.',
            isHighSeverity: true,
          ));
        }
      }

      // 2) UPnP (port 1900)
      if (_settings.routerUpnpCheck) {
        if (_hostHasPort(router, 1900)) {
          issues.add(const RouterIotIssue(
            type: RouterIotIssueType.possibleUpnp,
            title: 'UPnP may be enabled',
            description:
                'Port 1900/UDP typically indicates UPnP. Disable UPnP in your router unless you really need automatic port opening.',
            isHighSeverity: true,
          ));
        }
      }

      // 3) DNS hijack – informational only
      if (_settings.routerDnsHijack) {
        issues.add(const RouterIotIssue(
          type: RouterIotIssueType.possibleDnsHijack,
          title: 'Check router DNS configuration',
          description:
              'SCAN-X cannot directly detect DNS hijacking. Log into your router and verify DNS servers are set to trusted providers.',
        ));
      }

      // 4) WPS – informational only
      if (_settings.routerWpsCheck) {
        issues.add(const RouterIotIssue(
          type: RouterIotIssueType.possibleWps,
          title: 'Check WPS status in router',
          description:
              'Wi-Fi Protected Setup (WPS) is often insecure. Disable WPS in your router’s wireless settings if possible.',
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
        title: 'High-risk IoT devices detected',
        description:
            '$high IoT devices expose sensitive services (e.g. Telnet/FTP/SMB). Change default passwords and restrict remote access.',
        isHighSeverity: true,
      ));
    }

    if (med > 0) {
      issues.add(RouterIotIssue(
        type: RouterIotIssueType.iotMediumRisk,
        title: 'Medium-risk IoT devices present',
        description:
            '$med IoT devices show questionable exposure. Check for firmware updates and review their network access.',
      ));
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

  /// Very dumb router guess:
  ///  - IP ending in .1 or .254
  ///  - otherwise, first host in the list
  DetectedHost? _pickRouter(List<DetectedHost> hosts) {
    if (hosts.isEmpty) return null;

    for (final h in hosts) {
      final ip = (h as dynamic).ip ?? '';
      if (ip.endsWith('.1') || ip.endsWith('.254')) return h;
    }

    return hosts.first;
  }

  /// Guess IoT devices using simple name keywords.
  List<DetectedHost> _pickIotDevices(List<DetectedHost> hosts) {
    final keywords = [
      'camera',
      'cctv',
      'tv',
      'chromecast',
      'cast',
      'speaker',
      'echo',
      'plug',
      'light',
      'bulb',
      'thermostat',
      'hub',
    ];

    return hosts.where((h) {
      final label = ((h as dynamic).displayName ?? '').toLowerCase();
      final vendor = ((h as dynamic).vendor ?? '').toLowerCase();
      final combined = '$label $vendor';
      return keywords.any(combined.contains);
    }).toList();
  }

  /// Return a list of risky router ports (based on either simple int ports
  /// or richer port objects from your Nmap parser).
  List<int> _detectRiskyRouterPorts(DetectedHost host) {
    final ports = _safePorts(host);
    const risky = {21, 22, 23, 80, 443, 8080, 7547, 3389};
    return ports.where((p) => risky.contains(p)).toList();
  }

  /// Normalise whatever `openPorts` shape you have into a simple List<int>.
  ///
  /// Supports:
  ///  - List<int>
  ///  - List<dynamic> where each item has a `.port` int field
  List<int> _safePorts(DetectedHost host) {
    final raw = (host as dynamic).openPorts;
    if (raw == null) return [];
    if (raw is List<int>) return raw;

    final list = <int>[];
    if (raw is List) {
      for (final p in raw) {
        try {
          final x = (p as dynamic).port as int?;
          if (x != null) list.add(x);
        } catch (_) {
          // ignore malformed entries
        }
      }
    }
    return list;
  }

  bool _hostHasPort(DetectedHost host, int port) {
    return _safePorts(host).contains(port);
  }

  _SimpleRisk _estimateIotRisk(DetectedHost host) {
    final ports = _safePorts(host);
    if (ports.any((p) => p == 23 || p == 21 || p == 445)) {
      return _SimpleRisk.high;
    }
    if (ports.length >= 3) return _SimpleRisk.medium;
    return _SimpleRisk.low;
  }
}

enum _SimpleRisk { low, medium, high }
