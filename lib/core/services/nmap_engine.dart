// lib/core/services/nmap_engine.dart
//
// Minimal Nmap runner + parser for Windows/Linux/macOS.
// Uses grepable output (-oG -) to keep parsing simple.
//
// Requirements:
// - Nmap installed and accessible in PATH (run `nmap --version` in PowerShell)

import 'dart:io';

class NmapScanException implements Exception {
  final String message;
  NmapScanException(this.message);
  @override
  String toString() => message;
}

class NmapPort {
  final int port;
  final String protocol; // tcp/udp
  final String state;    // open/closed/filtered
  final String service;  // http/ssh/...
  const NmapPort({
    required this.port,
    required this.protocol,
    required this.state,
    required this.service,
  });
}

class NmapHostResult {
  final String ip;
  final bool isUp;
  final List<NmapPort> openPorts;
  const NmapHostResult({
    required this.ip,
    required this.isUp,
    required this.openPorts,
  });
}

class NmapEngine {
  /// Runs a fast discovery + top ports scan suitable for home/small office.
  ///
  /// -sn = ping scan (discovery)
  /// then a quick port scan for discovered hosts is usually ideal, but to keep
  /// v1 stable we do a single-pass scan with -sS/-sT depending on permissions.
  ///
  /// On Windows, Nmap typically uses -sT (connect scan) without admin rights.
  static Future<List<NmapHostResult>> scan({
    required String target,
    int topPorts = 100,
    Duration timeout = const Duration(minutes: 3),
  }) async {
    // We use grepable output to stdout for parsing: -oG -
    // --top-ports keeps runtime reasonable.
    final args = <String>[
      '-n',
      '--top-ports',
      '$topPorts',
      '--open',
      '-oG',
      '-', // output to stdout
      target,
    ];

    ProcessResult result;
    try {
      result = await Process.run(
        'nmap',
        args,
        runInShell: true,
      ).timeout(timeout);
    } on ProcessException {
      throw NmapScanException(
        'Nmap is not installed or not in PATH. Install Nmap and restart your terminal. '
        'Verify by running: nmap --version',
      );
    }

    final exitCode = result.exitCode;
    final stdoutStr = (result.stdout ?? '').toString();
    final stderrStr = (result.stderr ?? '').toString();

    // Nmap sometimes writes warnings to stderr but still succeeds.
    if (exitCode != 0 && stdoutStr.trim().isEmpty) {
      throw NmapScanException(
        'Nmap scan failed (exit $exitCode). Details: ${stderrStr.isNotEmpty ? stderrStr : stdoutStr}',
      );
    }

    return _parseGrepable(stdoutStr);
  }

  static List<NmapHostResult> _parseGrepable(String output) {
    // Grepable lines we care about:
    // Host: 192.168.1.1 ()   Status: Up
    // Host: 192.168.1.1 ()   Ports: 80/open/tcp//http///, 443/open/tcp//https///
    final lines = output.split(RegExp(r'\r?\n'));
    final map = <String, NmapHostResult>{};

    for (final line in lines) {
      if (!line.startsWith('Host: ')) continue;

      final ip = _extractIp(line);
      if (ip == null) continue;

      final isUp = line.contains('Status: Up');

      final ports = <NmapPort>[];
      final portsIndex = line.indexOf('Ports:');
      if (portsIndex != -1) {
        final portsPart = line.substring(portsIndex + 'Ports:'.length).trim();
        // Split on commas into port descriptors
        final chunks = portsPart.split(',').map((e) => e.trim()).toList();
        for (final c in chunks) {
          // Example chunk: 80/open/tcp//http///
          final fields = c.split('/');
          if (fields.length < 5) continue;
          final port = int.tryParse(fields[0]);
          final state = fields[1];
          final proto = fields[2];
          final service = fields[4].isEmpty ? 'unknown' : fields[4];
          if (port == null) continue;

          ports.add(NmapPort(
            port: port,
            protocol: proto,
            state: state,
            service: service,
          ));
        }
      }

      // Keep only open ports (we passed --open, but safe anyway)
      final openPorts = ports.where((p) => p.state == 'open').toList();

      final existing = map[ip];
      if (existing == null) {
        map[ip] = NmapHostResult(ip: ip, isUp: isUp, openPorts: openPorts);
      } else {
        // merge ports
        final merged = <NmapPort>[
          ...existing.openPorts,
          ...openPorts,
        ];
        map[ip] = NmapHostResult(ip: ip, isUp: existing.isUp || isUp, openPorts: merged);
      }
    }

    // Only return UP hosts
    return map.values.where((h) => h.isUp).toList();
  }

  static String? _extractIp(String line) {
    // "Host: <ip> " => take token after Host:
    final parts = line.split(RegExp(r'\s+'));
    final hostIndex = parts.indexOf('Host:');
    if (hostIndex == -1 || hostIndex + 1 >= parts.length) return null;
    final ip = parts[hostIndex + 1].trim();
    // Basic sanity
    if (!RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(ip)) return null;
    return ip;
  }
}
