import '../services/scan_service.dart';

enum ScanProfile { smart, full }

class ScanRequest {
  final String target; // can be CIDR like 192.168.1.0/24 or a single IP
  final ScanProfile profile;
  final Duration hostProbeTimeout;
  final Duration portConnectTimeout;

  const ScanRequest({
    required this.target,
    required this.profile,
    this.hostProbeTimeout = const Duration(milliseconds: 350),
    this.portConnectTimeout = const Duration(milliseconds: 250),
  });
}

abstract class ScannerEngine {
  Future<List<DetectedHost>> scan(ScanRequest request);
}