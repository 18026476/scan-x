import 'package:scanx_app/core/services/scan_service.dart';

class ScanModeService {
  final ScanService _scanService;
  ScanModeService(this._scanService);

  Future<ScanResult> runQuickScanSameAsSmart({ required String targetCidr }) async {
    // IMPORTANT: replace this line with the exact method Smart Scan uses.
    return _scanService.scan(targetCidr: targetCidr);
  }
}