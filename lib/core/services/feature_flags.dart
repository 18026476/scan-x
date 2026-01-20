class FeatureFlags {
  final bool aiAssistant;
  final bool explainVulnerabilities;
  final bool oneClickFixes;
  final bool aiDrivenRiskScoring;
  final bool routerHardeningPlaybooks;
  final bool detectUnnecessaryServices;
  final bool proactiveWarnings;

  final bool labsPacketSnifferLite;
  final bool labsWifiDeauthDetection;
  final bool labsRogueApDetection;
  final bool labsHiddenSsidDetection;

  final bool mlBehaviourThreatDetection;
  final bool mlLocalMlProfiling;
  final bool mlIotFingerprinting;

  const FeatureFlags({
    required this.aiAssistant,
    required this.explainVulnerabilities,
    required this.oneClickFixes,
    required this.aiDrivenRiskScoring,
    required this.routerHardeningPlaybooks,
    required this.detectUnnecessaryServices,
    required this.proactiveWarnings,
    required this.labsPacketSnifferLite,
    required this.labsWifiDeauthDetection,
    required this.labsRogueApDetection,
    required this.labsHiddenSsidDetection,
    required this.mlBehaviourThreatDetection,
    required this.mlLocalMlProfiling,
    required this.mlIotFingerprinting,
  });

  Map<String, dynamic> toJson() => {
    'aiAssistant': aiAssistant,
    'explainVulnerabilities': explainVulnerabilities,
    'oneClickFixes': oneClickFixes,
    'aiDrivenRiskScoring': aiDrivenRiskScoring,
    'routerHardeningPlaybooks': routerHardeningPlaybooks,
    'detectUnnecessaryServices': detectUnnecessaryServices,
    'proactiveWarnings': proactiveWarnings,
    'labsPacketSnifferLite': labsPacketSnifferLite,
    'labsWifiDeauthDetection': labsWifiDeauthDetection,
    'labsRogueApDetection': labsRogueApDetection,
    'labsHiddenSsidDetection': labsHiddenSsidDetection,
    'mlBehaviourThreatDetection': mlBehaviourThreatDetection,
    'mlLocalMlProfiling': mlLocalMlProfiling,
    'mlIotFingerprinting': mlIotFingerprinting,
  };
}