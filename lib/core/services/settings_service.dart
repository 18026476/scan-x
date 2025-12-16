import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


/// Central place for all SCAN-X settings.
/// Handles loading/saving to SharedPreferences and exposes typed getters/setters.
class SettingsService {
  static const _prefix = 'scanx_';

  // Scan profile specific keys (for Smart / Full scan behaviour)
  static const _kDefaultTargetCidr = '${_prefix}defaultTargetCidr';
  static const _kScanModeIndex = '${_prefix}scanModeIndex';

  // Keys
  static const _kTwoFactor = '${_prefix}twoFactorEnabled';
  static const _kAppTheme = '${_prefix}appTheme';
  static const _kAppLanguage = '${_prefix}appLanguage';

  static const _kAutoDetectLocalNetwork = '${_prefix}autoDetectLocalNetwork';
  static const _kManualIpRange = '${_prefix}manualIpRange';
  static const _kQuickScan = '${_prefix}quickScan';
  static const _kDeepScan = '${_prefix}deepScan';
  static const _kStealthScan = '${_prefix}stealthScan';
  static const _kContinuousMonitoring = '${_prefix}continuousMonitoring';
  static const _kFilterOnlyVulnerable = '${_prefix}filterOnlyVulnerable';
  static const _kFilterOnlyNewDevices = '${_prefix}filterOnlyNewDevices';
  static const _kExcludeTrustedDevices = '${_prefix}excludeTrustedDevices';
  static const _kFilterRouterIoTOnly = '${_prefix}filterRouterIoTOnly';
  static const _kScanFrequency = '${_prefix}scanFrequency';
  static const _kHostsPerScan = '${_prefix}hostsPerScan';

  static const _kAlertNewDevice = '${_prefix}alertNewDevice';
  static const _kAlertMacChange = '${_prefix}alertMacChange';
  static const _kAlertArpSpoof = '${_prefix}alertArpSpoof';
  static const _kAlertPortScanAttempts = '${_prefix}alertPortScanAttempts';

  static const _kRouterWeakPassword = '${_prefix}routerWeakPassword';
  static const _kRouterOpenPorts = '${_prefix}routerOpenPorts';
  static const _kRouterOutdatedFirmware = '${_prefix}routerOutdatedFirmware';
  static const _kRouterUpnpCheck = '${_prefix}routerUpnpCheck';
  static const _kRouterWpsCheck = '${_prefix}routerWpsCheck';
  static const _kRouterDnsHijack = '${_prefix}routerDnsHijack';

  static const _kIotOutdatedFirmware = '${_prefix}iotOutdatedFirmware';
  static const _kIotDefaultPasswords = '${_prefix}iotDefaultPasswords';
  static const _kIotVulnDbMatch = '${_prefix}iotVulnDbMatch';
  static const _kIotAutoRecommendations = '${_prefix}iotAutoRecommendations';

  static const _kPacketSnifferLite = '${_prefix}packetSnifferLite';
  static const _kWifiDeauthDetection = '${_prefix}wifiDeauthDetection';
  static const _kRogueApDetection = '${_prefix}rogueApDetection';
  static const _kHiddenSsidDetection = '${_prefix}hiddenSsidDetection';

  static const _kNotifyNewDevice = '${_prefix}notifyNewDevice';
  static const _kNotifyUnknownDevice = '${_prefix}notifyUnknownDevice';
  static const _kNotifyRouterVuln = '${_prefix}notifyRouterVuln';
  static const _kNotifyIotWarning = '${_prefix}notifyIotWarning';
  static const _kNotifyHighRisk = '${_prefix}notifyHighRisk';
  static const _kNotifyScanCompleted = '${_prefix}notifyScanCompleted';
  static const _kNotifyAutoScanResults = '${_prefix}notifyAutoScanResults';

  static const _kAlertSoundEnabled = '${_prefix}alertSoundEnabled';
  static const _kAlertVibrationEnabled = '${_prefix}alertVibrationEnabled';
  static const _kAlertSilentMode = '${_prefix}alertSilentMode';
  static const _kAlertSensitivity = '${_prefix}alertSensitivity';

  static const _kLogRetentionDays = '${_prefix}logRetentionDays';
  static const _kAnonymousUsageAnalytics = '${_prefix}anonymousUsageAnalytics';
  static const _kPerformanceMode = '${_prefix}performanceMode';
  static const _kAutoStartOnBoot = '${_prefix}autoStartOnBoot';
  static const _kAutoScanOnLaunch = '${_prefix}autoScanOnLaunch';
  static const _kKeepScreenAwake = '${_prefix}keepScreenAwake';

  // V1 release: clears previous scan results when a new scan starts
  static const _kAutoClearScan = '${_prefix}autoClearScan';

  static const _kAutoUpdateApp = '${_prefix}autoUpdateApp';
  static const _kNotifyBeforeUpdate = '${_prefix}notifyBeforeUpdate';
  static const _kBetaUpdates = '${_prefix}betaUpdates';

  static const _kAiAssistantEnabled = '${_prefix}aiAssistantEnabled';
  static const _kAiExplainVuln = '${_prefix}aiExplainVuln';
  static const _kAiOneClickFix = '${_prefix}aiOneClickFix';
  static const _kAiRiskScoring = '${_prefix}aiRiskScoring';
  static const _kAiRouterHardening = '${_prefix}aiRouterHardening';
  static const _kAiDetectUnnecessaryServices =
      '${_prefix}aiDetectUnnecessaryServices';
  static const _kAiProactiveWarnings = '${_prefix}aiProactiveWarnings';
  static const _kBetaBehaviourThreatDetection =
      '${_prefix}betaBehaviourThreatDetection';
  static const _kBetaLocalMlProfiling = '${_prefix}betaLocalMlProfiling';
  static const _kBetaIotFingerprinting = '${_prefix}betaIotFingerprinting';

  final SharedPreferences _prefs;

  // ----- Singleton wiring -----
  static SettingsService? _instance;

  // ----- Theme live update -----
  final ValueNotifier<ThemeMode> _themeModeNotifier =
  ValueNotifier<ThemeMode>(ThemeMode.system);

  SettingsService._(this._prefs);

  /// Call once at app startup (in main) before using SettingsService().
  static Future<SettingsService> init() async {
    if (_instance != null) return _instance!;
    final prefs = await SharedPreferences.getInstance();
    _instance = SettingsService._(prefs);

    // Initialize theme notifier from saved preference
    _instance!._themeModeNotifier.value = _instance!.themeMode;

    return _instance!;
  }

  /// Compatibility: some code may call SettingsService.instance
  static SettingsService get instance => SettingsService();

  /// Synchronous accessor used everywhere else.
  factory SettingsService() {
    final instance = _instance;
    if (instance == null) {
      throw StateError(
        'SettingsService not initialized. Call await SettingsService.init() in main() before using it.',
      );
    }
    return instance;
  }

  /// Backwards-compatible alias if you ever used create() before.
  static Future<SettingsService> create() => init();

  /// Listen to theme changes for instant UI updates.
  ValueListenable<ThemeMode> get themeModeListenable => _themeModeNotifier;

  // ------- App Theme / Language / Security -------

  bool get twoFactorEnabled => _prefs.getBool(_kTwoFactor) ?? true;
  Future<void> setTwoFactorEnabled(bool value) =>
      _prefs.setBool(_kTwoFactor, value);

  /// 0 = system, 1 = light, 2 = dark, 3 = SCAN-X dark (recommended)
  int get appThemeIndex => _prefs.getInt(_kAppTheme) ?? 3;

  Future<void> setAppThemeIndex(int value) async {
    await _prefs.setInt(_kAppTheme, value);

    // IMPORTANT: update notifier immediately so theme changes instantly
    _themeModeNotifier.value = themeMode;
  }

  /// 0 = system/English for now
  int get appLanguageIndex => _prefs.getInt(_kAppLanguage) ?? 0;
  Future<void> setAppLanguageIndex(int value) =>
      _prefs.setInt(_kAppLanguage, value);

  ThemeMode get themeMode {
    switch (appThemeIndex) {
      case 1:
        return ThemeMode.light;
      case 2:
        return ThemeMode.dark;
      case 3:
      // SCAN-X Dark uses ThemeMode.dark, but app picks a different darkTheme
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  // ------- Network / Scan Behaviour -------

  bool get autoDetectLocalNetwork =>
      _prefs.getBool(_kAutoDetectLocalNetwork) ?? true;
  Future<void> setAutoDetectLocalNetwork(bool value) =>
      _prefs.setBool(_kAutoDetectLocalNetwork, value);

  bool get manualIpRange => _prefs.getBool(_kManualIpRange) ?? false;
  Future<void> setManualIpRange(bool value) =>
      _prefs.setBool(_kManualIpRange, value);

  bool get quickScan => _prefs.getBool(_kQuickScan) ?? true;
  Future<void> setQuickScan(bool value) => _prefs.setBool(_kQuickScan, value);

  bool get deepScan => _prefs.getBool(_kDeepScan) ?? false;
  Future<void> setDeepScan(bool value) => _prefs.setBool(_kDeepScan, value);

  bool get stealthScan => _prefs.getBool(_kStealthScan) ?? false;
  Future<void> setStealthScan(bool value) =>
      _prefs.setBool(_kStealthScan, value);

  bool get continuousMonitoring =>
      _prefs.getBool(_kContinuousMonitoring) ?? false;
  Future<void> setContinuousMonitoring(bool value) =>
      _prefs.setBool(_kContinuousMonitoring, value);

  bool get filterOnlyVulnerable =>
      _prefs.getBool(_kFilterOnlyVulnerable) ?? false;
  Future<void> setFilterOnlyVulnerable(bool value) =>
      _prefs.setBool(_kFilterOnlyVulnerable, value);

  bool get filterOnlyNewDevices =>
      _prefs.getBool(_kFilterOnlyNewDevices) ?? false;
  Future<void> setFilterOnlyNewDevices(bool value) =>
      _prefs.setBool(_kFilterOnlyNewDevices, value);

  bool get excludeTrustedDevices =>
      _prefs.getBool(_kExcludeTrustedDevices) ?? false;
  Future<void> setExcludeTrustedDevices(bool value) =>
      _prefs.setBool(_kExcludeTrustedDevices, value);

  bool get filterRouterIoTOnly =>
      _prefs.getBool(_kFilterRouterIoTOnly) ?? false;
  Future<void> setFilterRouterIoTOnly(bool value) =>
      _prefs.setBool(_kFilterRouterIoTOnly, value);

  /// 0 = on-demand, 1 = every 15m, 2 = hourly, 3 = daily, etc.
  int get scanFrequency => _prefs.getInt(_kScanFrequency) ?? 0;
  Future<void> setScanFrequency(int value) =>
      _prefs.setInt(_kScanFrequency, value);

  int get hostsPerScan => _prefs.getInt(_kHostsPerScan) ?? 256;
  Future<void> setHostsPerScan(int value) =>
      _prefs.setInt(_kHostsPerScan, value);

  // ------- Alerts (Network Behaviour) -------

  bool get alertNewDevice => _prefs.getBool(_kAlertNewDevice) ?? true;
  Future<void> setAlertNewDevice(bool value) =>
      _prefs.setBool(_kAlertNewDevice, value);

  bool get alertMacChange => _prefs.getBool(_kAlertMacChange) ?? true;
  Future<void> setAlertMacChange(bool value) =>
      _prefs.setBool(_kAlertMacChange, value);

  bool get alertArpSpoof => _prefs.getBool(_kAlertArpSpoof) ?? true;
  Future<void> setAlertArpSpoof(bool value) =>
      _prefs.setBool(_kAlertArpSpoof, value);

  bool get alertPortScanAttempts =>
      _prefs.getBool(_kAlertPortScanAttempts) ?? true;
  Future<void> setAlertPortScanAttempts(bool value) =>
      _prefs.setBool(_kAlertPortScanAttempts, value);

  // ------- Router Checks -------

  bool get routerWeakPassword =>
      _prefs.getBool(_kRouterWeakPassword) ?? true;
  Future<void> setRouterWeakPassword(bool value) =>
      _prefs.setBool(_kRouterWeakPassword, value);

  bool get routerOpenPorts => _prefs.getBool(_kRouterOpenPorts) ?? true;
  Future<void> setRouterOpenPorts(bool value) =>
      _prefs.setBool(_kRouterOpenPorts, value);

  bool get routerOutdatedFirmware =>
      _prefs.getBool(_kRouterOutdatedFirmware) ?? true;
  Future<void> setRouterOutdatedFirmware(bool value) =>
      _prefs.setBool(_kRouterOutdatedFirmware, value);

  bool get routerUpnpCheck => _prefs.getBool(_kRouterUpnpCheck) ?? true;
  Future<void> setRouterUpnpCheck(bool value) =>
      _prefs.setBool(_kRouterUpnpCheck, value);

  bool get routerWpsCheck => _prefs.getBool(_kRouterWpsCheck) ?? true;
  Future<void> setRouterWpsCheck(bool value) =>
      _prefs.setBool(_kRouterWpsCheck, value);

  bool get routerDnsHijack => _prefs.getBool(_kRouterDnsHijack) ?? true;
  Future<void> setRouterDnsHijack(bool value) =>
      _prefs.setBool(_kRouterDnsHijack, value);

  // ------- IoT Checks -------

  bool get iotOutdatedFirmware =>
      _prefs.getBool(_kIotOutdatedFirmware) ?? true;
  Future<void> setIotOutdatedFirmware(bool value) =>
      _prefs.setBool(_kIotOutdatedFirmware, value);

  bool get iotDefaultPasswords =>
      _prefs.getBool(_kIotDefaultPasswords) ?? true;
  Future<void> setIotDefaultPasswords(bool value) =>
      _prefs.setBool(_kIotDefaultPasswords, value);

  bool get iotVulnDbMatch => _prefs.getBool(_kIotVulnDbMatch) ?? true;
  Future<void> setIotVulnDbMatch(bool value) =>
      _prefs.setBool(_kIotVulnDbMatch, value);

  bool get iotAutoRecommendations =>
      _prefs.getBool(_kIotAutoRecommendations) ?? true;
  Future<void> setIotAutoRecommendations(bool value) =>
      _prefs.setBool(_kIotAutoRecommendations, value);

  // ------- Advanced Wi-Fi / Packet Detection -------

  bool get packetSnifferLite =>
      _prefs.getBool(_kPacketSnifferLite) ?? false;
  Future<void> setPacketSnifferLite(bool value) =>
      _prefs.setBool(_kPacketSnifferLite, value);

  bool get wifiDeauthDetection =>
      _prefs.getBool(_kWifiDeauthDetection) ?? false;
  Future<void> setWifiDeauthDetection(bool value) =>
      _prefs.setBool(_kWifiDeauthDetection, value);

  bool get rogueApDetection =>
      _prefs.getBool(_kRogueApDetection) ?? false;
  Future<void> setRogueApDetection(bool value) =>
      _prefs.setBool(_kRogueApDetection, value);

  bool get hiddenSsidDetection =>
      _prefs.getBool(_kHiddenSsidDetection) ?? false;
  Future<void> setHiddenSsidDetection(bool value) =>
      _prefs.setBool(_kHiddenSsidDetection, value);

  // ------- Notifications / UX -------

  bool get notifyNewDevice => _prefs.getBool(_kNotifyNewDevice) ?? false;
  Future<void> setNotifyNewDevice(bool value) =>
      _prefs.setBool(_kNotifyNewDevice, value);

  bool get notifyUnknownDevice =>
      _prefs.getBool(_kNotifyUnknownDevice) ?? false;
  Future<void> setNotifyUnknownDevice(bool value) =>
      _prefs.setBool(_kNotifyUnknownDevice, value);

  bool get notifyRouterVuln =>
      _prefs.getBool(_kNotifyRouterVuln) ?? false;
  Future<void> setNotifyRouterVuln(bool value) =>
      _prefs.setBool(_kNotifyRouterVuln, value);

  bool get notifyIotWarning =>
      _prefs.getBool(_kNotifyIotWarning) ?? false;
  Future<void> setNotifyIotWarning(bool value) =>
      _prefs.setBool(_kNotifyIotWarning, value);

  bool get notifyHighRisk => _prefs.getBool(_kNotifyHighRisk) ?? true;
  Future<void> setNotifyHighRisk(bool value) =>
      _prefs.setBool(_kNotifyHighRisk, value);

  bool get notifyScanCompleted =>
      _prefs.getBool(_kNotifyScanCompleted) ?? true;
  Future<void> setNotifyScanCompleted(bool value) =>
      _prefs.setBool(_kNotifyScanCompleted, value);

  bool get notifyAutoScanResults =>
      _prefs.getBool(_kNotifyAutoScanResults) ?? true;
  Future<void> setNotifyAutoScanResults(bool value) =>
      _prefs.setBool(_kNotifyAutoScanResults, value);

  bool get alertSoundEnabled =>
      _prefs.getBool(_kAlertSoundEnabled) ?? true;
  Future<void> setAlertSoundEnabled(bool value) =>
      _prefs.setBool(_kAlertSoundEnabled, value);

  bool get alertVibrationEnabled =>
      _prefs.getBool(_kAlertVibrationEnabled) ?? true;
  Future<void> setAlertVibrationEnabled(bool value) =>
      _prefs.setBool(_kAlertVibrationEnabled, value);

  bool get alertSilentMode =>
      _prefs.getBool(_kAlertSilentMode) ?? false;
  Future<void> setAlertSilentMode(bool value) =>
      _prefs.setBool(_kAlertSilentMode, value);

  /// 0 = low, 1 = balanced, 2 = aggressive
  int get alertSensitivity => _prefs.getInt(_kAlertSensitivity) ?? 1;
  Future<void> setAlertSensitivity(int value) =>
      _prefs.setInt(_kAlertSensitivity, value);

  // ------- Performance / Logs -------

  int get logRetentionDays => _prefs.getInt(_kLogRetentionDays) ?? 30;
  Future<void> setLogRetentionDays(int value) =>
      _prefs.setInt(_kLogRetentionDays, value);

  bool get anonymousUsageAnalytics =>
      _prefs.getBool(_kAnonymousUsageAnalytics) ?? false;
  Future<void> setAnonymousUsageAnalytics(bool value) =>
      _prefs.setBool(_kAnonymousUsageAnalytics, value);

  /// 0 = balanced, 1 = performance, 2 = battery saver
  int get performanceMode => _prefs.getInt(_kPerformanceMode) ?? 1;
  Future<void> setPerformanceMode(int value) =>
      _prefs.setInt(_kPerformanceMode, value);

  bool get autoStartOnBoot => _prefs.getBool(_kAutoStartOnBoot) ?? false;
  Future<void> setAutoStartOnBoot(bool value) =>
      _prefs.setBool(_kAutoStartOnBoot, value);

  bool get autoScanOnLaunch =>
      _prefs.getBool(_kAutoScanOnLaunch) ?? false;
  Future<void> setAutoScanOnLaunch(bool value) =>
      _prefs.setBool(_kAutoScanOnLaunch, value);

  bool get keepScreenAwake => _prefs.getBool(_kKeepScreenAwake) ?? false;
  Future<void> setKeepScreenAwake(bool value) =>
      _prefs.setBool(_kKeepScreenAwake, value);

  // V1 release: Auto-clear previous scan results when starting a new scan
  bool get autoClearScan => _prefs.getBool(_kAutoClearScan) ?? true;
  Future<void> setAutoClearScan(bool value) =>
      _prefs.setBool(_kAutoClearScan, value);

  // ------- Updates & AI -------

  bool get autoUpdateApp => _prefs.getBool(_kAutoUpdateApp) ?? true;
  Future<void> setAutoUpdateApp(bool value) =>
      _prefs.setBool(_kAutoUpdateApp, value);

  bool get notifyBeforeUpdate =>
      _prefs.getBool(_kNotifyBeforeUpdate) ?? true;
  Future<void> setNotifyBeforeUpdate(bool value) =>
      _prefs.setBool(_kNotifyBeforeUpdate, value);

  bool get betaUpdates => _prefs.getBool(_kBetaUpdates) ?? false;
  Future<void> setBetaUpdates(bool value) =>
      _prefs.setBool(_kBetaUpdates, value);

  bool get aiAssistantEnabled =>
      _prefs.getBool(_kAiAssistantEnabled) ?? true;
  Future<void> setAiAssistantEnabled(bool value) =>
      _prefs.setBool(_kAiAssistantEnabled, value);

  bool get aiExplainVuln => _prefs.getBool(_kAiExplainVuln) ?? true;
  Future<void> setAiExplainVuln(bool value) =>
      _prefs.setBool(_kAiExplainVuln, value);

  bool get aiOneClickFix => _prefs.getBool(_kAiOneClickFix) ?? true;
  Future<void> setAiOneClickFix(bool value) =>
      _prefs.setBool(_kAiOneClickFix, value);

  bool get aiRiskScoring => _prefs.getBool(_kAiRiskScoring) ?? true;
  Future<void> setAiRiskScoring(bool value) =>
      _prefs.setBool(_kAiRiskScoring, value);

  bool get aiRouterHardening =>
      _prefs.getBool(_kAiRouterHardening) ?? false;
  Future<void> setAiRouterHardening(bool value) =>
      _prefs.setBool(_kAiRouterHardening, value);

  bool get aiDetectUnnecessaryServices =>
      _prefs.getBool(_kAiDetectUnnecessaryServices) ?? false;
  Future<void> setAiDetectUnnecessaryServices(bool value) =>
      _prefs.setBool(_kAiDetectUnnecessaryServices, value);

  bool get aiProactiveWarnings =>
      _prefs.getBool(_kAiProactiveWarnings) ?? false;
  Future<void> setAiProactiveWarnings(bool value) =>
      _prefs.setBool(_kAiProactiveWarnings, value);

  bool get betaBehaviourThreatDetection =>
      _prefs.getBool(_kBetaBehaviourThreatDetection) ?? false;
  Future<void> setBetaBehaviourThreatDetection(bool value) =>
      _prefs.setBool(_kBetaBehaviourThreatDetection, value);

  bool get betaLocalMlProfiling =>
      _prefs.getBool(_kBetaLocalMlProfiling) ?? false;
  Future<void> setBetaLocalMlProfiling(bool value) =>
      _prefs.setBool(_kBetaLocalMlProfiling, value);

  bool get betaIotFingerprinting =>
      _prefs.getBool(_kBetaIotFingerprinting) ?? false;
  Future<void> setBetaIotFingerprinting(bool value) =>
      _prefs.setBool(_kBetaIotFingerprinting, value);

  // ---------------------------------------------------------------------------
  // Scan profile abstraction used by ScanService / Dashboard / Scan screen
  // ---------------------------------------------------------------------------

  ScanMode get scanMode {
    final idx = _prefs.getInt(_kScanModeIndex) ?? 1; // default = balanced
    if (idx < 0 || idx >= ScanMode.values.length) {
      return ScanMode.balanced;
    }
    return ScanMode.values[idx];
  }

  Future<void> setScanMode(ScanMode mode) async {
    await _prefs.setInt(_kScanModeIndex, mode.index);
  }

  String get defaultTargetCidr =>
      _prefs.getString(_kDefaultTargetCidr) ?? '192.168.1.0/24';

  Future<void> setDefaultTargetCidr(String value) async {
    await _prefs.setString(_kDefaultTargetCidr, value);
  }

  ScanSettings get settings => ScanSettings(
    defaultTargetCidr: defaultTargetCidr,
    scanMode: scanMode,
    hostDiscoveryEnabled: autoDetectLocalNetwork,
    fullScanAllHosts: continuousMonitoring,
    maxDeepHosts: hostsPerScan,
    portsPerPhase: 2000,
    highRiskHighPorts: 3,
    highRiskTotalPorts: 15,
    mediumRiskHighPorts: 1,
    mediumRiskTotalPorts: 5,
    customHighRiskPorts: const [21, 22, 23, 80, 445, 3389, 1900],
    keepOnlyLastScan: false,
    autoQuickScanOnStartup: autoScanOnLaunch,
  );

  Future<void> updateScanSettings(ScanSettings value) async {
    await setDefaultTargetCidr(value.defaultTargetCidr);
    await setScanMode(value.scanMode);
    await setHostsPerScan(value.maxDeepHosts);
    await setAutoScanOnLaunch(value.autoQuickScanOnStartup);
  }
}

enum ScanMode {
  performance,
  balanced,
  paranoid,
}

class ScanSettings {
  final String defaultTargetCidr;
  final ScanMode scanMode;

  final bool hostDiscoveryEnabled;
  final bool fullScanAllHosts;
  final int maxDeepHosts;
  final int portsPerPhase;

  final int highRiskHighPorts;
  final int highRiskTotalPorts;
  final int mediumRiskHighPorts;
  final int mediumRiskTotalPorts;
  final List<int> customHighRiskPorts;

  final bool keepOnlyLastScan;
  final bool autoQuickScanOnStartup;

  const ScanSettings({
    required this.defaultTargetCidr,
    required this.scanMode,
    required this.hostDiscoveryEnabled,
    required this.fullScanAllHosts,
    required this.maxDeepHosts,
    required this.portsPerPhase,
    required this.highRiskHighPorts,
    required this.highRiskTotalPorts,
    required this.mediumRiskHighPorts,
    required this.mediumRiskTotalPorts,
    required this.customHighRiskPorts,
    required this.keepOnlyLastScan,
    required this.autoQuickScanOnStartup,
  });

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
      hostDiscoveryEnabled: hostDiscoveryEnabled ?? this.hostDiscoveryEnabled,
      fullScanAllHosts: fullScanAllHosts ?? this.fullScanAllHosts,
      maxDeepHosts: maxDeepHosts ?? this.maxDeepHosts,
      portsPerPhase: portsPerPhase ?? this.portsPerPhase,
      highRiskHighPorts: highRiskHighPorts ?? this.highRiskHighPorts,
      highRiskTotalPorts: highRiskTotalPorts ?? this.highRiskTotalPorts,
      mediumRiskHighPorts: mediumRiskHighPorts ?? this.mediumRiskHighPorts,
      mediumRiskTotalPorts: mediumRiskTotalPorts ?? this.mediumRiskTotalPorts,
      customHighRiskPorts: customHighRiskPorts ?? this.customHighRiskPorts,
      keepOnlyLastScan: keepOnlyLastScan ?? this.keepOnlyLastScan,
      autoQuickScanOnStartup:
      autoQuickScanOnStartup ?? this.autoQuickScanOnStartup,
    );
  }
}
