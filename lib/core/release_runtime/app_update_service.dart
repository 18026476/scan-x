import 'dart:io';

class AppUpdateService {
  static bool autoUpdateEnabled = false;
  static bool askBeforeInstall = true;
  static bool betaUpdatesEnabled = false;

  static void configure({
    required bool autoUpdate,
    required bool askBeforeUpdating,
    required bool betaUpdates,
  }) {
    autoUpdateEnabled = autoUpdate;
    askBeforeInstall = askBeforeUpdating;
    betaUpdatesEnabled = betaUpdates;
  }

  static Future<String> releaseChannel() async {
    return betaUpdatesEnabled ? 'beta' : 'stable';
  }

  static Future<void> checkForUpdatesOnLaunch() async {
    if (!autoUpdateEnabled) return;

    try {
      final dir = Directory('.scanx_logs');
      if (!dir.existsSync()) dir.createSync(recursive: true);

      final file = File('.scanx_logs/update_runtime.log');
      final channel = await releaseChannel();

      await file.writeAsString(
        '${DateTime.now().toIso8601String()} | update_check | channel=$channel | askBeforeInstall=$askBeforeInstall\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (_) {}
  }
}
