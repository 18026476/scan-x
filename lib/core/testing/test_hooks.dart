import 'package:flutter/foundation.dart';
import 'package:scanx_app/core/services/scan_service.dart';

/// Test-only hooks. Safe for release.
/// Only active in debug (integration tests run in debug).
class TestHooks {
  static void seedLastResult(ScanResult result) {
    if (!kDebugMode) return;
    ScanService().lastResult = result;
  }

  static void clearLastResult() {
    if (!kDebugMode) return;
    ScanService().lastResult = null;
  }
}