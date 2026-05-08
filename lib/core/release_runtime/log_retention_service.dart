import 'dart:io';

class LogRetentionService {
  static Future<void> enforce({required int retentionDays}) async {
    if (retentionDays <= 0) return;

    final now = DateTime.now();
    final roots = <Directory>[
      Directory('.scanx_logs'),
      Directory('.scanx_release_reports'),
    ];

    for (final root in roots) {
      try {
        if (!root.existsSync()) continue;

        await for (final entity in root.list(recursive: true, followLinks: false)) {
          if (entity is! File) continue;

          final stat = await entity.stat();
          final age = now.difference(stat.modified).inDays;

          if (age > retentionDays) {
            try {
              await entity.delete();
            } catch (_) {}
          }
        }
      } catch (_) {}
    }
  }
}
