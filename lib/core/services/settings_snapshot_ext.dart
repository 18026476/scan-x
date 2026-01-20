import 'package:scanx_app/core/services/settings_service.dart';

extension ScanxSettingsSnapshot on SettingsService {
  /// Safe snapshot for PDF reporting: AI + Labs + ML toggle states.
  Map<String, dynamic> aiLabsMlSnapshot() => {
        'aiAssistantEnabled': aiAssistantEnabled,
        'aiExplainVuln': aiExplainVuln,
        'aiOneClickFix': aiOneClickFix,
        'aiRiskScoring': aiRiskScoring,
        'aiRouterHardening': aiRouterHardening,
        'aiDetectUnnecessaryServices': aiDetectUnnecessaryServices,
        'aiProactiveWarnings': aiProactiveWarnings,
        'packetSnifferLite': packetSnifferLite,
        'wifiDeauthDetection': wifiDeauthDetection,
        'rogueApDetection': rogueApDetection,
        'hiddenSsidDetection': hiddenSsidDetection,
        'betaBehaviourThreatDetection': betaBehaviourThreatDetection,
        'betaLocalMlProfiling': betaLocalMlProfiling,
        'betaIotFingerprinting': betaIotFingerprinting,
      };
}