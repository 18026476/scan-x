import 'package:flutter/material.dart';
import 'package:scanx_app/core/services/scan_service.dart';
import 'package:scanx_app/core/services/scan_snapshot_store.dart';
import 'package:scanx_app/core/services/alert_rules_engine.dart';
import 'package:scanx_app/core/services/in_app_notifier.dart';

class PostScanPipeline {
  static Future<void> handleScanComplete(
    BuildContext context, {
    required ScanResult result,
    required bool isAutoScan,
  }) async {
    final store = ScanSnapshotStore();
    final previous = await store.load();
    final ipToMac = await store.getIpToMacBestEffort();

    final events = AlertRulesEngine().buildEvents(
      current: result,
      previousSnapshot: previous,
      currentIpToMac: ipToMac,
    );

    await store.save(result: result, ipToMac: ipToMac);
    if (!context.mounted) return;

    await InAppNotifier().notify(context, events, isAutoScan: isAutoScan);
  }
}