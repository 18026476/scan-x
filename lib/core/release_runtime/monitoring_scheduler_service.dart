import 'dart:async';

class MonitoringSchedulerService {
  static Timer? _timer;

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }

  static void configure({
    required bool continuousMonitoring,
    required int scanFrequency,
    required Future<void> Function() onAutoScan,
  }) {
    stop();

    if (!continuousMonitoring) return;

    final duration = _durationFromFrequency(scanFrequency);
    if (duration == null) return;

    _timer = Timer.periodic(duration, (_) async {
      try {
        await onAutoScan();
      } catch (_) {}
    });
  }

  static Duration? _durationFromFrequency(int value) {
    switch (value) {
      case 0:
        return null; // manual only
      case 1:
        return const Duration(hours: 1);
      case 2:
        return const Duration(hours: 6);
      case 3:
        return const Duration(hours: 12);
      case 4:
        return const Duration(days: 1);
      default:
        return null;
    }
  }
}
