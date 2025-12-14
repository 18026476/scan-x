import 'dart:async';
import 'dart:io';
import 'models.dart';

class TcpConnectScanner {
  Future<List<ScanFinding>> scanHostTcp(
    String host, {
    required List<int> ports,
    required int timeoutMs,
    required int concurrency,
  }) async {
    final findings = <ScanFinding>[];
    final sem = _Semaphore(concurrency);

    final tasks = <Future<void>>[];
    for (final port in ports) {
      tasks.add(() async {
        await sem.acquire();
        try {
          final ok = await _tryConnect(host, port, timeoutMs);
          if (ok) {
            findings.add(ScanFinding(host: host, port: port, protocol: 'tcp', service: _guessService(port)));
          }
        } finally {
          sem.release();
        }
      }());
    }

    await Future.wait(tasks);
    return findings;
  }

  Future<bool> _tryConnect(String host, int port, int timeoutMs) async {
    Socket? sock;
    try {
      sock = await Socket.connect(host, port, timeout: Duration(milliseconds: timeoutMs));
      return true;
    } catch (_) {
      return false;
    } finally {
      try { sock?.destroy(); } catch (_) {}
    }
  }

  String? _guessService(int port) {
    switch (port) {
      case 80: return 'http';
      case 443: return 'https';
      case 22: return 'ssh';
      case 445: return 'smb';
      case 3389: return 'rdp';
      case 1900: return 'ssdp';
      case 53: return 'dns';
      default: return null;
    }
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
