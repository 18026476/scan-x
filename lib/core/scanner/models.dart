class ScanTarget {
  final String cidrOrHost;
  final int connectTimeoutMs;
  final int concurrency;

  const ScanTarget({
    required this.cidrOrHost,
    this.connectTimeoutMs = 600,
    this.concurrency = 256,
  });
}

class ScanFinding {
  final String host;
  final int port;
  final String protocol;
  final String? service;

  const ScanFinding({
    required this.host,
    required this.port,
    required this.protocol,
    this.service,
  });
}

class HostResult {
  final String host;
  final List<ScanFinding> findings;

  const HostResult({required this.host, required this.findings});
}

class NativeScanResult {
  final DateTime startedAt;
  final DateTime finishedAt;
  final ScanTarget target;
  final List<HostResult> hosts;

  const NativeScanResult({
    required this.startedAt,
    required this.finishedAt,
    required this.target,
    required this.hosts,
  });
}
