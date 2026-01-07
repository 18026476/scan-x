import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:scanx_app/core/services/scan_service.dart';

class ScanSnapshotStore {
  static const _kLastSnapshot = 'scanx_last_snapshot_v1';

  Future<Map<String, dynamic>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLastSnapshot);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return decoded.cast<String, dynamic>();
    } catch (_) {}
    return null;
  }

  Future<void> save({
    required ScanResult result,
    required Map<String, String> ipToMac,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final devices = <String, dynamic>{};
    for (final h in result.hosts) {
      devices[h.address] = {
        'ip': h.address,
        'hostname': h.hostname,
        'mac': ipToMac[h.address] ?? '',
        'openPorts': h.openPorts.length,
        'risk': h.risk.name,
      };
    }

    final snapshot = <String, dynamic>{
      'capturedAtUtc': DateTime.now().toUtc().toIso8601String(),
      'target': result.target,
      'devices': devices,
    };

    await prefs.setString(_kLastSnapshot, jsonEncode(snapshot));
  }

  Future<Map<String, String>> getIpToMacBestEffort() async {
    try {
      if (Platform.isWindows) {
        final pr = await Process.run('arp', ['-a'], stdoutEncoding: utf8, stderrEncoding: utf8);
        return _parseWindowsArp(pr.stdout?.toString() ?? '');
      }

      final pr1 = await Process.run('arp', ['-a'], stdoutEncoding: utf8, stderrEncoding: utf8);
      final m1 = _parseUnixArp(pr1.stdout?.toString() ?? '');
      if (m1.isNotEmpty) return m1;

      final pr2 = await Process.run('ip', ['neigh'], stdoutEncoding: utf8, stderrEncoding: utf8);
      return _parseIpNeigh(pr2.stdout?.toString() ?? '');
    } catch (_) {
      return {};
    }
  }

  Map<String, String> _parseWindowsArp(String out) {
    final map = <String, String>{};
    final lines = out.split(RegExp(r'\r?\n'));
    for (final ln in lines) {
      final parts = ln.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2 && RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(parts[0])) {
        final ip = parts[0];
        final mac = parts[1].toLowerCase();
        if (mac.contains('-') || mac.contains(':')) map[ip] = mac;
      }
    }
    return map;
  }

  Map<String, String> _parseUnixArp(String out) {
    final map = <String, String>{};
    final lines = out.split(RegExp(r'\r?\n'));
    for (final ln in lines) {
      final mIp = RegExp(r'\((\d+\.\d+\.\d+\.\d+)\)').firstMatch(ln);
      final mMac = RegExp(r'\bat\s+([0-9a-fA-F:]{11,17})\b').firstMatch(ln);
      if (mIp != null && mMac != null) {
        map[mIp.group(1)!] = mMac.group(1)!.toLowerCase();
      }
    }
    return map;
  }

  Map<String, String> _parseIpNeigh(String out) {
    final map = <String, String>{};
    final lines = out.split(RegExp(r'\r?\n'));
    for (final ln in lines) {
      final m = RegExp(r'^(\d+\.\d+\.\d+\.\d+)\s+.*\slladdr\s+([0-9a-fA-F:]{11,17})\b').firstMatch(ln.trim());
      if (m != null) {
        map[m.group(1)!] = m.group(2)!.toLowerCase();
      }
    }
    return map;
  }
}