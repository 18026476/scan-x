import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scanx_app/core/services/settings_service.dart';
import 'package:scanx_app/core/services/alert_rules_engine.dart';

class InAppNotifier {
  InAppNotifier({SettingsService? settings})
      : _settings = settings ?? SettingsService();

  final SettingsService _settings;

  Future<void> notify(
    dynamic first,
    dynamic second, {
    bool autoScan = false,
    bool isAutoScan = false,
  }) async {
    if (_settings.alertSilentMode) return;
    if ((autoScan || isAutoScan) && !_settings.notifyAutoScanResults) return;

    if (_settings.alertVibrationEnabled) {
      try {
        await HapticFeedback.mediumImpact();
      } catch (_) {}
    }

    if (_settings.alertSoundEnabled) {
      try {
        await SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
    }

    if (first is BuildContext) {
      final events = second is List ? second : <dynamic>[second];

      for (final event in events) {
        if (event is AlertEvent) {
          try {
            ScaffoldMessenger.of(first).showSnackBar(
              SnackBar(content: Text(event.message)),
            );
          } catch (_) {}
        }
      }
    }
  }

  Future<void> notifyAll(
    List<AlertEvent> events, {
    bool autoScan = false,
  }) async {
    for (final event in events) {
      await notify(null, event, autoScan: autoScan);
    }
  }
}
