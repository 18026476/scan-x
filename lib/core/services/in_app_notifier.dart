import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scanx_app/core/services/alert_rules_engine.dart';
import 'package:scanx_app/core/services/settings_service.dart';

class InAppNotifier {
  
  String _scanxSanitizeTitle(String t) {
    var s = t.trim();
    // Fix key-like leakage (e.g., "Possible ARP spoofing.title")
    if (s.endsWith('.title')) {
      s = s.substring(0, s.length - '.title'.length).trim();
    }
    if (s.endsWith('.message')) {
      s = s.substring(0, s.length - '.message'.length).trim();
    }
    return s.isEmpty ? 'Alert' : s;
  }
Future<void> notify(BuildContext context, List<AlertEvent> events, {required bool isAutoScan}) async {
    if (events.isEmpty) return;

    final s = SettingsService();
    if (isAutoScan && !s.notifyAutoScanResults) return;

    final silent = s.alertSilentMode;

    if (!silent) {
      if (s.alertSoundEnabled) {
        SystemSound.play(SystemSoundType.alert);
      }
      if (s.alertVibrationEnabled) {
        HapticFeedback.lightImpact();
      }
    }

    final top = _pickMostSevere(events);
    final extra = events.length - 1;
    final msg = extra > 0 ? '$top.title (${extra} more)' : top.title;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  AlertEvent _pickMostSevere(List<AlertEvent> events) {
    int rank(AlertSeverity s) {
      switch (s) {
        case AlertSeverity.critical: return 5;
        case AlertSeverity.high: return 4;
        case AlertSeverity.medium: return 3;
        case AlertSeverity.low: return 2;
        case AlertSeverity.info: return 1;
      }
    }
    events.sort((a, b) => rank(b.severity).compareTo(rank(a.severity)));
    return events.first;
  }
}
