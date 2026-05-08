import 'dart:io';

class AnonymousAnalyticsService {
  static bool _enabled = false;

  static void configure({required bool enabled}) {
    _enabled = enabled;
  }

  static Future<void> event(String name, {Map<String, Object?> data = const {}}) async {
    if (!_enabled) return;

    try {
      final dir = Directory('.scanx_logs');
      if (!dir.existsSync()) dir.createSync(recursive: true);

      final file = File('.scanx_logs/anonymous_usage_analytics.log');
      final safeData = Map<String, Object?>.from(data)
        ..removeWhere((key, value) {
          final k = key.toLowerCase();
          return k.contains('ip') ||
              k.contains('mac') ||
              k.contains('email') ||
              k.contains('name') ||
              k.contains('address') ||
              k.contains('token');
        });

      final line = '${DateTime.now().toIso8601String()} | $name | $safeData\n';
      await file.writeAsString(line, mode: FileMode.append, flush: true);
    } catch (_) {}
  }
}
