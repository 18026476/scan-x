import 'dart:async';
import 'models.dart';
import 'ip_range.dart';
import 'tcp_connect_scanner.dart';

class NativeScanEngine {
  static const List<int> smartPorts = [
    22, 23, 53, 80, 81, 443, 445, 139, 3389, 8000, 8080, 8443, 1900,
  ];

  final TcpConnectScanner _tcp = TcpConnectScanner();

  Future<NativeScanResult> smartScan(ScanTarget target) async {
    final startedAt = DateTime.now();
    final ips = IpRange.expand(target.cidrOrHost);

    final hostConcurrency = target.concurrency.clamp(32, 256);
    final hostResults = <HostResult>[];
    final sem = _Semaphore(hostConcurrency);

    final tasks = <Future<void>>[];
    for (final ip in ips) {
      tasks.add(() async {
        await sem.acquire();
        try {
          final findings = await _tcp.scanHostTcp(
            ip,
            ports: smartPorts,
            timeoutMs: target.connectTimeoutMs,
            concurrency: 64,
          );
          if (findings.isNotEmpty) {
            hostResults.add(HostResult(host: ip, findings: findings));
          }
        } finally {
          sem.release();
        }
      }());
    }

    await Future.wait(tasks);

    final finishedAt = DateTime.now();
    return NativeScanResult(
      startedAt: startedAt,
      finishedAt: finishedAt,
      target: target,
      hosts: hostResults,
    );
  }
}

class _Semaphore {
  int _permits;
  final _q = <Completer<void>>[];

  _Semaphore(this._permits);

  Future<void> acquire() {
    if (_permits > 0) {
      _permits--;
      return Future.value();
    }
    final c = Completer<void>();
    _q.add(c);
    return c.future;
  }

  void release() {
    if (_q.isNotEmpty) {
      _q.removeAt(0).complete();
      return;
    }
    _permits++;
  }
}
