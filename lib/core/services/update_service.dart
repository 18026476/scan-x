// lib/core/services/update_service.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UpdateService {
  // TODO: host this file (Netlify/GitHub/raw/etc)
  static const String manifestUrl = 'https://scanxcyberlabs.com/update.json';

  // Keep in sync with pubspec.yaml version
  static const String currentVersion = '1.0.0+1';

  static Future<void> checkAndHandleUpdate(
    BuildContext context, {
    required bool promptUser,
    required bool useBetaChannel,
  }) async {
    final res = await http.get(Uri.parse(manifestUrl)).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return;

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final channel = useBetaChannel ? 'beta' : 'stable';
    final entry = (data[channel] as Map?)?.cast<String, dynamic>();
    if (entry == null) return;

    final remoteVersion = (entry['version'] ?? '').toString();
    final url = (entry['url'] ?? '').toString();
    if (remoteVersion.isEmpty || url.isEmpty) return;

    if (!_isNewer(remoteVersion, currentVersion)) return;

    if (promptUser) {
      final yes = await _prompt(context, remoteVersion);
      if (!yes) return;
    }

    await _downloadAndRun(url);
  }

  static Future<bool> _prompt(BuildContext context, String remoteVersion) async {
    bool yes = false;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Update available'),
        content: Text('A newer version is available: '),
        actions: [
          TextButton(
            onPressed: () {
              yes = false;
              Navigator.of(context).pop();
            },
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              yes = true;
              Navigator.of(context).pop();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
    return yes;
  }

  static bool _isNewer(String remote, String current) {
    List<int> parse(String v) {
      final parts = v.split('+');
      final core = parts[0];
      final build = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
      final coreParts = core.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      while (coreParts.length < 3) coreParts.add(0);
      return [coreParts[0], coreParts[1], coreParts[2], build];
    }

    final r = parse(remote);
    final c = parse(current);
    for (var i = 0; i < 4; i++) {
      if (r[i] > c[i]) return true;
      if (r[i] < c[i]) return false;
    }
    return false;
  }

  static Future<void> _downloadAndRun(String url) async {
    final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) return;

    final file = File('scanx_update_.exe');
    await file.writeAsBytes(res.bodyBytes);

    await Process.start(file.path, [], runInShell: true);
  }
}
