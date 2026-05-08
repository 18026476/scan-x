import 'package:scanx_app/core/services/settings_service.dart';
import 'windows_startup_service.dart';
import 'log_retention_service.dart';
import 'anonymous_analytics_service.dart';
import 'app_update_service.dart';

class ReleaseSettingsCoordinator {
  static Future<void> applyOnStartup() async {
    final settings = SettingsService();

    try {
      await WindowsStartupService.setEnabled(settings.autoStartOnBoot);
    } catch (_) {}

    try {
      await LogRetentionService.enforce(
        retentionDays: settings.logRetentionDays,
      );
    } catch (_) {}

    try {
      AnonymousAnalyticsService.configure(
        enabled: settings.anonymousUsageAnalytics,
      );
    } catch (_) {}

    try {
      AppUpdateService.configure(
        autoUpdate: settings.autoUpdateApp,
        askBeforeUpdating: settings.notifyBeforeUpdate,
        betaUpdates: settings.betaUpdates,
      );

      await AppUpdateService.checkForUpdatesOnLaunch();
    } catch (_) {}

    try {
      await AnonymousAnalyticsService.event(
        'app_launch',
        data: {
          'performanceMode': settings.performanceMode,
          'continuousMonitoring': settings.continuousMonitoring,
          'scanFrequency': settings.scanFrequency,
        },
      );
    } catch (_) {}
  }
}
