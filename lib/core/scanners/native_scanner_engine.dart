import 'dart:async';
import 'dart:io';

import '../services/scan_service.dart';
import 'scanner_engine.dart';
import 'port_catalog.dart';
import 'package:scanx_app/core/utils/text_sanitizer.dart';

class NativeScannerEngine implements ScannerEngine {
  @override
  Future<List<DetectedHost>> scan(ScanRequest request) async {
    final target = request.target.trim();

    // If CIDR: enumerate IPs; if single IP: just scan it.
    final ips = target.contains('/') ? _expandCidr(target) : <String>[target];

    // 1) Host discovery: quick probe (connect to a small set of ports)
    final live = <String>{};
    final probePorts = const [80, 443, 445, 22, 3389];

    await _parallelForEach(ips, concurrency: 128, action: (ip) async {
      final ok = await _isHostUp(ip, probePorts, request.hostProbeTimeout);
      if (ok) live.add(ip);
    });

    // 2) Port scan on live hosts
    final ports = request.profile == ScanProfile.smart ? PortCatalog.smartPorts : PortCatalog.fullPorts;

    final hosts = <DetectedHost>[];
    for (final ip in live) {
      final openPorts = <OpenPort>[];

      await _parallelForEach(ports, concurrency: 64, action: (p) async {
        final isOpen = await _isPortOpen(ip, p, request.portConnectTimeout);
        if (isOpen) {
          openPorts.add(OpenPort(port: p, protocol: 'tcp', serviceName: TextSanitizer.normalizeUi( TextSanitizer.normalizeUi(PortCatalog.nameFor(p)))));
        }
      });

      openPorts.sort((a, b) => a.port.compareTo(b.port));

      hosts.add(
        DetectedHost(
          address: ip,
          hostname: null,
          openPorts: openPorts,
          risk: _riskFromPorts(openPorts),
        ),
      );
    }

    hosts.sort((a, b) => a.address.compareTo(b.address));
    return hosts;
  }

  Future<bool> _isHostUp(String ip, List<int> ports, Duration timeout) async {
    for (final p in ports) {
      if (await _isPortOpen(ip, p, timeout)) return true;
    }
    return false;
  }

  Future<bool> _isPortOpen(String ip, int port, Duration timeout) async {
    Socket? s;
    try {
      s = await Socket.connect(ip, port, timeout: timeout);
      return true;
    } catch (_) {
      return false;
    } finally {
      try { s?.destroy(); } catch (_) {}
    }
  }

  RiskLevel _riskFromPorts(List<OpenPort> ports) {
    // Basic heuristic; align with your existing ScanService scoring later.
    final sensitive = {23, 445, 3389};
    final hasSensitive = ports.any((p) => sensitive.contains(p.port));
    if (hasSensitive) return RiskLevel.high;
    if (ports.isEmpty) return RiskLevel.low;
    return RiskLevel.medium;
  }

  Future<void> _parallelForEach<T>(
    Iterable<T> items, {
    required int concurrency,
    required Future<void> Function(T item) action,
  }) async {
    final it = items.iterator;
    final workers = <Future<void>>[];

    Future<void> worker() async {
      while (true) {
        T current;
        // lock-free pull pattern (single isolate): guard with tryMoveNext.
        final hasNext = it.moveNext();
        if (!hasNext) return;
        current = it.current;
        await action(current);
      }
    }

    final n = concurrency < 1 ? 1 : concurrency;
    for (int i = 0; i < n; i++) {
      workers.add(worker());
    }
    await Future.wait(workers);
  }

  List<String> _expandCidr(String cidr) {
    // MVP: supports /24 only safely. Extend later.
    final parts = cidr.split('/');
    final base = parts[0];
    final prefix = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 24;

    if (prefix != 24) {
      // fallback: treat as single IP if non-/24 for MVP
      return <String>[base];
    }

    final oct = base.split('.').map(int.parse).toList();
    // network base is oct[0].oct[1].oct[2].0
    final net = '\.\.\.';
    return List<String>.generate(254, (i) => '\\');
  }
}

