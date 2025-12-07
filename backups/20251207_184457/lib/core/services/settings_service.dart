// lib/core/services/settings_service.dart

/// Overall scan mode preset.
/// Used to decide how aggressive / deep SCAN-X should scan.
enum ScanMode {
  performance, // fast, lighter scans
  balanced,    // default
  paranoid,    // slow but deepest
}

/// Holds all user-configurable scan settings for SCAN-X.
class ScanSettings {
  // ---------- Target / network ----------
  final String defaultTargetCidr;

  // ---------- Scan behaviour ----------
  final ScanMode scanMode;
  final bool hostDiscoveryEnabled; // use nmap -sn before port scans
  final bool fullScanAllHosts;     // if false, deep-scan only top risky hosts
  final int maxDeepHosts;          // max hosts to full-scan (1–50 realistic)
  final int portsPerPhase;         // base ports per phase for dynamic planner

  // ---------- Risk model ----------
  /// High if host has >= highRiskHighPorts "high-risk" ports OR
  /// >= highRiskTotalPorts total open ports.
  final int highRiskHighPorts;
  final int highRiskTotalPorts;

  /// Medium if host has >= mediumRiskHighPorts high-risk ports OR
  /// >= mediumRiskTotalPorts total open ports (and not already HIGH).
  final int mediumRiskHighPorts;
  final int mediumRiskTotalPorts;

  /// Custom high-risk ports (e.g. 21, 23, 445, 3389, 1900, etc.)
  final List<int> customHighRiskPorts;

  // ---------- Data retention / automation ----------
  final bool keepOnlyLastScan;       // if false, you can later keep history
  final bool autoQuickScanOnStartup; // run Quick Scan when app starts

  const ScanSettings({
    // target
    required this.defaultTargetCidr,

    // behaviour
    required this.scanMode,
    required this.hostDiscoveryEnabled,
    required this.fullScanAllHosts,
    required this.maxDeepHosts,
    required this.portsPerPhase,

    // risk
    required this.highRiskHighPorts,
    required this.highRiskTotalPorts,
    required this.mediumRiskHighPorts,
    required this.mediumRiskTotalPorts,
    required this.customHighRiskPorts,

    // retention / automation
    required this.keepOnlyLastScan,
    required this.autoQuickScanOnStartup,
  });

  /// Default values used when the app starts for the first time.
  factory ScanSettings.defaults() {
    return const ScanSettings(
      // Target
      defaultTargetCidr: '192.168.1.0/24',

      // Behaviour – "balanced" preset
      scanMode: ScanMode.balanced,
      hostDiscoveryEnabled: true,
      fullScanAllHosts: false,
      maxDeepHosts: 10,
      portsPerPhase: 3000,

      // Risk thresholds
      highRiskHighPorts: 3,
      highRiskTotalPorts: 15,
      mediumRiskHighPorts: 1,
      mediumRiskTotalPorts: 5,

      // Common high-risk ports
      customHighRiskPorts: [21, 23, 445, 3389, 1900],

      // Retention / automation
      keepOnlyLastScan: true,
      autoQuickScanOnStartup: false,
    );
  }

  /// Copy-with pattern so the UI can update just a few fields.
  ScanSettings copyWith({
    String? defaultTargetCidr,

    ScanMode? scanMode,
    bool? hostDiscoveryEnabled,
    bool? fullScanAllHosts,
    int? maxDeepHosts,
    int? portsPerPhase,

    int? highRiskHighPorts,
    int? highRiskTotalPorts,
    int? mediumRiskHighPorts,
    int? mediumRiskTotalPorts,
    List<int>? customHighRiskPorts,

    bool? keepOnlyLastScan,
    bool? autoQuickScanOnStartup,
  }) {
    return ScanSettings(
      defaultTargetCidr: defaultTargetCidr ?? this.defaultTargetCidr,

      scanMode: scanMode ?? this.scanMode,
      hostDiscoveryEnabled:
      hostDiscoveryEnabled ?? this.hostDiscoveryEnabled,
      fullScanAllHosts: fullScanAllHosts ?? this.fullScanAllHosts,
      maxDeepHosts: maxDeepHosts ?? this.maxDeepHosts,
      portsPerPhase: portsPerPhase ?? this.portsPerPhase,

      highRiskHighPorts: highRiskHighPorts ?? this.highRiskHighPorts,
      highRiskTotalPorts: highRiskTotalPorts ?? this.highRiskTotalPorts,
      mediumRiskHighPorts:
      mediumRiskHighPorts ?? this.mediumRiskHighPorts,
      mediumRiskTotalPorts:
      mediumRiskTotalPorts ?? this.mediumRiskTotalPorts,
      customHighRiskPorts:
      customHighRiskPorts ?? List<int>.from(this.customHighRiskPorts),

      keepOnlyLastScan: keepOnlyLastScan ?? this.keepOnlyLastScan,
      autoQuickScanOnStartup:
      autoQuickScanOnStartup ?? this.autoQuickScanOnStartup,
    );
  }
}

/// Simple in-memory singleton for settings.
/// Later you can back this with SharedPreferences / a file for persistence.
class SettingsService {
  SettingsService._internal();
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;

  ScanSettings _settings = ScanSettings.defaults();

  ScanSettings get settings => _settings;

  void updateSettings(ScanSettings newSettings) {
    _settings = newSettings;
  }
}
