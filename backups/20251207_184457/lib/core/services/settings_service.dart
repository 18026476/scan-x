import 'package:shared_preferences/shared_preferences.dart';

enum ScanMode { paranoid, balanced, performance }

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const _prefix = 'scanx.';

  static const _kPerformanceMode = '${_prefix}performanceMode';
  static const _kScanMode = '${_prefix}scanMode';

  static const _kContinuousMonitoring = '${_prefix}continuousMonitoring';
  static const _kScanFrequency = '${_prefix}scanFrequency';

  static const _kAutoScanOnLaunch = '${_prefix}autoScanOnLaunch';
  static const _kHostsPerScan = '${_prefix}hostsPerScan';
  static const _kKeepScreenAwake = '${_prefix}keepScreenAwake';

  static const _kAutoStartOnBoot = '${_prefix}autoStartOnBoot';

  static const _kAutoUpdateApp = '${_prefix}autoUpdateApp';
  static const _kNotifyBeforeUpdate = '${_prefix}notifyBeforeUpdate';
  static const _kBetaUpdates = '${_prefix}betaUpdates';

  static const _kTwoFactorEnabled = '${_prefix}twoFactorEnabled';
  static const _kTwoFactorSecret = '${_prefix}twoFactorSecret';
  static const _kTwoFactorVerifiedUntilMs =
      '${_prefix}twoFactorVerifiedUntilMs';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ---------------- Performance / Scan Mode ----------------

  int get performanceMode => _prefs.getInt(_kPerformanceMode) ?? 1;

  Future<void> setPerformanceMode(int value) async {
    await _prefs.setInt(_kPerformanceMode, value);

    if (value == 0) {
      await setScanMode(ScanMode.paranoid);
    } else if (value == 2) {
      await setScanMode(ScanMode.performance);
    } else {
      await setScanMode(ScanMode.balanced);
    }
  }

  ScanMode get scanMode {
    final v = _prefs.getInt(_kScanMode) ?? 1;
    return ScanMode.values[v];
  }

  Future<void> setScanMode(ScanMode mode) =>
      _prefs.setInt(_kScanMode, mode.index);

  // ---------------- Continuous Monitoring ----------------

  bool get continuousMonitoring =>
      _prefs.getBool(_kContinuousMonitoring) ?? false;

  Future<void> setContinuousMonitoring(bool value) =>
      _prefs.setBool(_kContinuousMonitoring, value);

  int get scanFrequency => _prefs.getInt(_kScanFrequency) ?? 0;

  Future<void> setScanFrequency(int value) =>
      _prefs.setInt(_kScanFrequency, value);

  // ---------------- Scan Behaviour ----------------

  bool get autoScanOnLaunch => _prefs.getBool(_kAutoScanOnLaunch) ?? false;

  Future<void> setAutoScanOnLaunch(bool value) =>
      _prefs.setBool(_kAutoScanOnLaunch, value);

  int get hostsPerScan => _prefs.getInt(_kHostsPerScan) ?? 0;

  Future<void> setHostsPerScan(int value) =>
      _prefs.setInt(_kHostsPerScan, value);

  bool get keepScreenAwake => _prefs.getBool(_kKeepScreenAwake) ?? false;

  Future<void> setKeepScreenAwake(bool value) =>
      _prefs.setBool(_kKeepScreenAwake, value);

  // ---------------- Startup ----------------

  bool get autoStartOnBoot => _prefs.getBool(_kAutoStartOnBoot) ?? false;

  Future<void> setAutoStartOnBoot(bool value) =>
      _prefs.setBool(_kAutoStartOnBoot, value);

  // ---------------- Updates ----------------

  bool get autoUpdateApp => _prefs.getBool(_kAutoUpdateApp) ?? false;

  Future<void> setAutoUpdateApp(bool value) =>
      _prefs.setBool(_kAutoUpdateApp, value);

  bool get notifyBeforeUpdate =>
      _prefs.getBool(_kNotifyBeforeUpdate) ?? true;

  Future<void> setNotifyBeforeUpdate(bool value) =>
      _prefs.setBool(_kNotifyBeforeUpdate, value);

  bool get betaUpdates => _prefs.getBool(_kBetaUpdates) ?? false;

  Future<void> setBetaUpdates(bool value) =>
      _prefs.setBool(_kBetaUpdates, value);

  // ---------------- Two-Factor Authentication ----------------

  bool get twoFactorEnabled => _prefs.getBool(_kTwoFactorEnabled) ?? false;

  Future<void> setTwoFactorEnabled(bool value) =>
      _prefs.setBool(_kTwoFactorEnabled, value);

  String get twoFactorSecret =>
      _prefs.getString(_kTwoFactorSecret) ?? '';

  Future<void> setTwoFactorSecret(String value) =>
      _prefs.setString(_kTwoFactorSecret, value);

  DateTime? get twoFactorVerifiedUntil {
    final ms = _prefs.getInt(_kTwoFactorVerifiedUntilMs);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setTwoFactorVerifiedUntil(DateTime? value) {
    if (value == null) {
      return _prefs.remove(_kTwoFactorVerifiedUntilMs);
    }
    return _prefs.setInt(
        _kTwoFactorVerifiedUntilMs, value.millisecondsSinceEpoch);
  }
}
