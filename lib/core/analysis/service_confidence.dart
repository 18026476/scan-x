class ServiceConfidenceResult {
  final String classification;
  final int score;

  const ServiceConfidenceResult(this.classification, this.score);
}

class ServiceConfidenceEngine {
  static ServiceConfidenceResult evaluate({
    required bool portOpen,
    required String serviceName,
    required String version,
    required String scriptOutput,
  }) {
    int score = 0;

    if (portOpen) score += 30;

    final lower = serviceName.toLowerCase();
    if (lower.contains('smb') || lower.contains('microsoft-ds')) {
      score += 20;
    }

    if (version.trim().isNotEmpty &&
        !version.toLowerCase().contains('unknown')) {
      score += 30;
    }

    if (scriptOutput.toLowerCase().contains('smb')) {
      score += 20;
    }

    if (score >= 60) {
      return ServiceConfidenceResult('Detected', score);
    } else if (score >= 30) {
      return ServiceConfidenceResult('Probable', score);
    } else {
      return ServiceConfidenceResult('Uncertain', score);
    }
  }
}
