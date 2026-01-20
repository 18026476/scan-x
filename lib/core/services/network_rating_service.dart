import 'package:scanx_app/core/services/scan_service.dart';

/// Canonical network rating for SCAN-X (single source of truth).
/// Health: 0..100 (higher is better)
/// Risk:   0..100 (higher is worse) = 100 - health
class NetworkRatingService {
  int computeHealth(ScanResult? result) {
    if (result == null) return 0;

    var health = 100;

    final hosts = _listDyn(_readJsonOrMap(result, 'hosts'));
    for (final h in hosts) {
      final risk = _intDyn(_readJsonOrMap(h, 'risk')) ?? _heuristicRiskFromPorts(h);

      if (risk >= 80)      health -= 20;
      else if (risk >= 50) health -= 10;
      else if (risk >= 20) health -= 3;

      for (final p in _portsFromHost(h)) {
        if (p == 21 || p == 23) health -= 8;      // FTP/Telnet
        if (p == 445 || p == 3389) health -= 10;  // SMB/RDP
        if (p == 80 || p == 443) health -= 2;     // Web
        if (p == 1900 || p == 5353) health -= 1;  // SSDP/mDNS
      }
    }

    if (health < 0) health = 0;
    if (health > 100) health = 100;
    return health;
  }

  int computeRisk(ScanResult? result) => 100 - computeHealth(result);

  String riskLabel(int risk) {
    if (risk >= 80) return 'High';
    if (risk >= 50) return 'Medium';
    return 'Low';
  }

  // ---------------- private helpers ----------------

  dynamic _readJsonOrMap(dynamic obj, String key) {
    if (obj == null) return null;

    // Prefer toJson() if present.
    try {
      final m = (obj as dynamic).toJson();
      if (m is Map) return m[key];
    } catch (_) {}

    // Fallback to Map access.
    try {
      if (obj is Map) return obj[key];
    } catch (_) {}

    return null;
  }

  List<dynamic> _listDyn(dynamic v) {
    if (v is List) return v.cast<dynamic>();
    return const <dynamic>[];
  }

  int? _intDyn(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }

  List<int> _portsFromHost(dynamic host) {
    final out = <int>[];

    dynamic ports = _readJsonOrMap(host, 'openPorts');
    if (ports == null) ports = _readJsonOrMap(host, 'ports');

    // Some models keep ports as a field rather than JSON key
    if (ports == null) {
      try { ports = (host as dynamic).openPorts; } catch (_) {}
      if (ports == null) {
        try { ports = (host as dynamic).ports; } catch (_) {}
      }
    }

    if (ports is List) {
      for (final item in ports.cast<dynamic>()) {
        if (item is int) {
          out.add(item);
          continue;
        }
        // Port object: {port: 80}
        final p = _intDyn(_readJsonOrMap(item, 'port'));
        if (p != null) out.add(p);
        else {
          try {
            final v = (item as dynamic).port;
            if (v is int) out.add(v);
          } catch (_) {}
        }
      }
    }

    return out;
  }

  int _heuristicRiskFromPorts(dynamic host) {
    var score = 0;
    for (final p in _portsFromHost(host)) {
      if (p == 21 || p == 23) score += 30;
      if (p == 445 || p == 3389) score += 40;
      if (p == 80 || p == 443) score += 10;
      if (p == 1900 || p == 5353) score += 5;
    }
    if (score > 100) score = 100;
    return score;
  }
}