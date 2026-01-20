import 'package:scanx_app/core/services/scan_service.dart';
import 'package:scanx_app/core/services/settings_service.dart';

/// ML Insights (beta) - deterministic heuristics scaffold.
/// This is intentionally safe for "client-grade" reporting:
/// - No exploitation
/// - No intrusive inference
/// - Uses simple features from scan results
class MlInsightsService {
  /// Returns bullet points suitable for PDF.
  List<String> buildInsights({
    required ScanResult? result,
    required SettingsService settings,
  }) {
    if (result == null) return const <String>[];

    final enabled = settings.betaBehaviourThreatDetection ||
        settings.betaLocalMlProfiling ||
        settings.betaIotFingerprinting;

    if (!enabled) return const <String>[];

    final hosts = _hosts(result);

    // Features
    final deviceCount = hosts.length;
    final openPortCount = _totalOpenPorts(hosts);
    final riskyPortHits = _riskyPortHits(hosts);
    final uniquePorts = _uniquePorts(hosts);

    // "Learning" scaffold: baseline from this scan (can be extended later to persisted baselines).
    // For now we produce deterministic "anomaly score" from observable risk signals.
    var anomalyScore = 0;
    if (deviceCount >= 15) anomalyScore += 15;
    if (openPortCount >= 30) anomalyScore += 20;
    if (riskyPortHits >= 3) anomalyScore += 25;
    if (uniquePorts.length >= 12) anomalyScore += 10;

    if (anomalyScore > 100) anomalyScore = 100;

    final out = <String>[];

    if (settings.betaBehaviourThreatDetection) {
      out.add('Behaviour signals (beta): anomaly score /100 based on device/port patterns.');
      if (riskyPortHits > 0) {
        out.add('Behaviour signals: detected  risky-service exposures (e.g., SMB/RDP/Telnet/FTP).');
      } else {
        out.add('Behaviour signals: no high-risk service exposures detected from the current scan data.');
      }
    }

    if (settings.betaLocalMlProfiling) {
      out.add('Local profiling (beta):  devices observed;  open ports total.');
      out.add('Local profiling:  unique ports seen across the network.');
    }

    if (settings.betaIotFingerprinting) {
      // We avoid hard claims. We provide a safe indicator based on device name/manufacturer patterns if present.
      final iotHints = _iotHintCount(hosts);
      if (iotHints > 0) {
        out.add('IoT fingerprinting (beta):  device(s) match common IoT naming patterns (non-verified).');
      } else {
        out.add('IoT fingerprinting (beta): no IoT naming patterns detected (non-verified).');
      }
    }

    return out;
  }

  List<dynamic> _hosts(ScanResult r) {
    try {
      final h = (r as dynamic).hosts;
      if (h is List) return h.cast<dynamic>();
    } catch (_) {}
    return const <dynamic>[];
  }

  List<int> _ports(dynamic host) {
    final out = <int>[];
    dynamic ports;
    try { ports = (host as dynamic).openPorts; } catch (_) {}
    if (ports == null) { try { ports = (host as dynamic).ports; } catch (_) {} }

    if (ports is List) {
      for (final p in ports.cast<dynamic>()) {
        if (p is int) { out.add(p); continue; }
        try {
          final v = (p as dynamic).port;
          if (v is int) out.add(v);
        } catch (_) {}
      }
    }
    return out;
  }

  int _totalOpenPorts(List<dynamic> hosts) {
    var total = 0;
    for (final h in hosts) {
      total += _ports(h).length;
    }
    return total;
  }

  Set<int> _uniquePorts(List<dynamic> hosts) {
    final s = <int>{};
    for (final h in hosts) {
      s.addAll(_ports(h));
    }
    return s;
  }

  int _riskyPortHits(List<dynamic> hosts) {
    var hits = 0;
    for (final h in hosts) {
      for (final p in _ports(h)) {
        if (p == 21 || p == 23 || p == 445 || p == 3389) hits++;
      }
    }
    return hits;
  }

  int _iotHintCount(List<dynamic> hosts) {
    var hits = 0;
    for (final h in hosts) {
      String? name;
      try { name = (h as dynamic).name?.toString(); } catch (_) {}
      if (name == null) {
        try { name = (h as dynamic).hostname?.toString(); } catch (_) {}
      }
      if (name == null) continue;

      final n = name.toLowerCase();
      if (n.contains('cam') || n.contains('camera') || n.contains('door') || n.contains('ring') ||
          n.contains('echo') || n.contains('alexa') || n.contains('tv') || n.contains('plug') ||
          n.contains('bulb') || n.contains('sensor') || n.contains('therm') || n.contains('iot')) {
        hits++;
      }
    }
    return hits;
  }
}