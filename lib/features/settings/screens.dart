import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SCAN-X Settings Screen with persistence
/// - Saves all settings into SharedPreferences
/// - Loads them on startup
/// - Adds "Hosts per scan" (network ID auto from scanner)
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

enum AppTheme { light, dark, amoled, system }
enum AppLanguage {
  english,
  hindi,
  indonesian,
  filipino,
  chineseSimplified,
  arabic,
}

enum ScanFrequency { manual, fiveMinutes, fifteenMinutes, oneHour, oneDay }
enum AlertSensitivity { low, medium, high }
enum PerformanceMode { batterySaver, balanced, performance }

class _SettingsScreenState extends State<SettingsScreen> {
  SharedPreferences? _prefs;

  // 1. Account & User Settings
  bool _twoFactorEnabled = false;

  AppTheme _appTheme = AppTheme.system;
  AppLanguage _appLanguage = AppLanguage.english;

  // 2. Network Scan Settings
  bool _autoDetectLocalNetwork = true;
  bool _manualIpRange = false;
  bool _quickScan = true;
  bool _deepScan = false;
  bool _stealthScan = false;
  bool _continuousMonitoring = false;

  bool _filterOnlyVulnerable = false;
  bool _filterOnlyNewDevices = false;
  bool _excludeTrustedDevices = false;
  bool _filterRouterIoTOnly = false;

  ScanFrequency _scanFrequency = ScanFrequency.manual;

  // NEW: Hosts per scan (0 = all hosts, subnet chosen automatically by scanner)
  int _hostsPerScan = 256;

  // 3. Security & Protection Settings
  bool _alertNewDevice = true;
  bool _alertMacChange = true;
  bool _alertArpSpoof = true;
  bool _alertPortScanAttempts = true;

  bool _routerWeakPassword = true;
  bool _routerOpenPorts = true;
  bool _routerOutdatedFirmware = true;
  bool _routerUpnpCheck = true;
  bool _routerWpsCheck = true;
  bool _routerDnsHijack = true;

  bool _iotOutdatedFirmware = true;
  bool _iotDefaultPasswords = true;
  bool _iotVulnDbMatch = true;
  bool _iotAutoRecommendations = true;

  bool _packetSnifferLite = false;
  bool _wifiDeauthDetection = false;
  bool _rogueApDetection = false;
  bool _hiddenSsidDetection = false;

  // 4. Notifications & Alerts
  bool _notifyNewDevice = true;
  bool _notifyUnknownDevice = true;
  bool _notifyRouterVuln = true;
  bool _notifyIotWarning = true;
  bool _notifyHighRisk = true;
  bool _notifyScanCompleted = true;
  bool _notifyAutoScanResults = true;

  bool _alertSoundEnabled = true;
  bool _alertVibrationEnabled = true;
  bool _alertSilentMode = false;

  AlertSensitivity _alertSensitivity = AlertSensitivity.medium;

  // 5. Data & Logs
  int _logRetentionDays = 30; // 7, 30, 90, 0 (0 = never)
  bool _anonymousUsageAnalytics = false;

  // 6. App Preferences
  PerformanceMode _performanceMode = PerformanceMode.balanced;
  bool _autoStartOnBoot = false;
  bool _autoScanOnLaunch = false;
  bool _keepScreenAwake = false;

  bool _autoUpdateApp = true;
  bool _notifyBeforeUpdate = true;
  bool _betaUpdates = false;

  // 8. Experimental & AI Features
  bool _aiAssistantEnabled = true;
  bool _aiExplainVuln = true;
  bool _aiOneClickFix = true;
  bool _aiRiskScoring = true;

  bool _aiRouterHardening = false;
  bool _aiDetectUnnecessaryServices = false;
  bool _aiProactiveWarnings = false;

  bool _betaBehaviourThreatDetection = false;
  bool _betaLocalMlProfiling = false;
  bool _betaIotFingerprinting = false;

  @override
  void initState() {
    super.initState();
    _initAndLoadSettings();
  }

  // ---------- PERSISTENCE LAYER ----------

  Future<void> _initAndLoadSettings() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final jsonStr = _prefs!.getString('scanx_settings_v1');
      if (jsonStr == null) {
        debugPrint('[SCANX][Settings] No saved settings found, using defaults.');
        return;
      }

      final Map<String, dynamic> map = jsonDecode(jsonStr);
      debugPrint('[SCANX][Settings] Loaded settings: $map');

      int _enumIndex(dynamic v, int max, int fallback) {
        final n = (v is num) ? v.toInt() : fallback;
        if (n < 0 || n >= max) return fallback;
        return n;
      }

      setState(() {
        _twoFactorEnabled = map['twoFactorEnabled'] ?? _twoFactorEnabled;

        _appTheme = AppTheme.values[_enumIndex(
          map['appTheme'],
          AppTheme.values.length,
          _appTheme.index,
        )];
        _appLanguage = AppLanguage.values[_enumIndex(
          map['appLanguage'],
          AppLanguage.values.length,
          _appLanguage.index,
        )];

        _autoDetectLocalNetwork =
            map['autoDetectLocalNetwork'] ?? _autoDetectLocalNetwork;
        _manualIpRange = map['manualIpRange'] ?? _manualIpRange;
        _quickScan = map['quickScan'] ?? _quickScan;
        _deepScan = map['deepScan'] ?? _deepScan;
        _stealthScan = map['stealthScan'] ?? _stealthScan;
        _continuousMonitoring =
            map['continuousMonitoring'] ?? _continuousMonitoring;

        _filterOnlyVulnerable =
            map['filterOnlyVulnerable'] ?? _filterOnlyVulnerable;
        _filterOnlyNewDevices =
            map['filterOnlyNewDevices'] ?? _filterOnlyNewDevices;
        _excludeTrustedDevices =
            map['excludeTrustedDevices'] ?? _excludeTrustedDevices;
        _filterRouterIoTOnly =
            map['filterRouterIoTOnly'] ?? _filterRouterIoTOnly;

        _scanFrequency = ScanFrequency.values[_enumIndex(
          map['scanFrequency'],
          ScanFrequency.values.length,
          _scanFrequency.index,
        )];

        _hostsPerScan =
            (map['hostsPerScan'] as num?)?.toInt() ?? _hostsPerScan;

        _alertNewDevice = map['alertNewDevice'] ?? _alertNewDevice;
        _alertMacChange = map['alertMacChange'] ?? _alertMacChange;
        _alertArpSpoof = map['alertArpSpoof'] ?? _alertArpSpoof;
        _alertPortScanAttempts =
            map['alertPortScanAttempts'] ?? _alertPortScanAttempts;

        _routerWeakPassword =
            map['routerWeakPassword'] ?? _routerWeakPassword;
        _routerOpenPorts = map['routerOpenPorts'] ?? _routerOpenPorts;
        _routerOutdatedFirmware =
            map['routerOutdatedFirmware'] ?? _routerOutdatedFirmware;
        _routerUpnpCheck = map['routerUpnpCheck'] ?? _routerUpnpCheck;
        _routerWpsCheck = map['routerWpsCheck'] ?? _routerWpsCheck;
        _routerDnsHijack = map['routerDnsHijack'] ?? _routerDnsHijack;

        _iotOutdatedFirmware =
            map['iotOutdatedFirmware'] ?? _iotOutdatedFirmware;
        _iotDefaultPasswords =
            map['iotDefaultPasswords'] ?? _iotDefaultPasswords;
        _iotVulnDbMatch = map['iotVulnDbMatch'] ?? _iotVulnDbMatch;
        _iotAutoRecommendations =
            map['iotAutoRecommendations'] ?? _iotAutoRecommendations;

        _packetSnifferLite =
            map['packetSnifferLite'] ?? _packetSnifferLite;
        _wifiDeauthDetection =
            map['wifiDeauthDetection'] ?? _wifiDeauthDetection;
        _rogueApDetection = map['rogueApDetection'] ?? _rogueApDetection;
        _hiddenSsidDetection =
            map['hiddenSsidDetection'] ?? _hiddenSsidDetection;

        _notifyNewDevice = map['notifyNewDevice'] ?? _notifyNewDevice;
        _notifyUnknownDevice =
            map['notifyUnknownDevice'] ?? _notifyUnknownDevice;
        _notifyRouterVuln = map['notifyRouterVuln'] ?? _notifyRouterVuln;
        _notifyIotWarning = map['notifyIotWarning'] ?? _notifyIotWarning;
        _notifyHighRisk = map['notifyHighRisk'] ?? _notifyHighRisk;
        _notifyScanCompleted =
            map['notifyScanCompleted'] ?? _notifyScanCompleted;
        _notifyAutoScanResults =
            map['notifyAutoScanResults'] ?? _notifyAutoScanResults;

        _alertSoundEnabled =
            map['alertSoundEnabled'] ?? _alertSoundEnabled;
        _alertVibrationEnabled =
            map['alertVibrationEnabled'] ?? _alertVibrationEnabled;
        _alertSilentMode = map['alertSilentMode'] ?? _alertSilentMode;

        _alertSensitivity = AlertSensitivity.values[_enumIndex(
          map['alertSensitivity'],
          AlertSensitivity.values.length,
          _alertSensitivity.index,
        )];

        _logRetentionDays =
            (map['logRetentionDays'] as num?)?.toInt() ?? _logRetentionDays;
        _anonymousUsageAnalytics =
            map['anonymousUsageAnalytics'] ?? _anonymousUsageAnalytics;

        _performanceMode = PerformanceMode.values[_enumIndex(
          map['performanceMode'],
          PerformanceMode.values.length,
          _performanceMode.index,
        )];
        _autoStartOnBoot = map['autoStartOnBoot'] ?? _autoStartOnBoot;
        _autoScanOnLaunch = map['autoScanOnLaunch'] ?? _autoScanOnLaunch;
        _keepScreenAwake = map['keepScreenAwake'] ?? _keepScreenAwake;

        _autoUpdateApp = map['autoUpdateApp'] ?? _autoUpdateApp;
        _notifyBeforeUpdate =
            map['notifyBeforeUpdate'] ?? _notifyBeforeUpdate;
        _betaUpdates = map['betaUpdates'] ?? _betaUpdates;

        _aiAssistantEnabled =
            map['aiAssistantEnabled'] ?? _aiAssistantEnabled;
        _aiExplainVuln = map['aiExplainVuln'] ?? _aiExplainVuln;
        _aiOneClickFix = map['aiOneClickFix'] ?? _aiOneClickFix;
        _aiRiskScoring = map['aiRiskScoring'] ?? _aiRiskScoring;

        _aiRouterHardening =
            map['aiRouterHardening'] ?? _aiRouterHardening;
        _aiDetectUnnecessaryServices =
            map['aiDetectUnnecessaryServices'] ?? _aiDetectUnnecessaryServices;
        _aiProactiveWarnings =
            map['aiProactiveWarnings'] ?? _aiProactiveWarnings;

        _betaBehaviourThreatDetection =
            map['betaBehaviourThreatDetection'] ??
                _betaBehaviourThreatDetection;
        _betaLocalMlProfiling =
            map['betaLocalMlProfiling'] ?? _betaLocalMlProfiling;
        _betaIotFingerprinting =
            map['betaIotFingerprinting'] ?? _betaIotFingerprinting;
      });
    } catch (e, st) {
      debugPrint('[SCANX][Settings] Error loading settings: $e');
      debugPrint(st.toString());
    }
  }

  Future<void> _saveSettings() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();

      final map = <String, dynamic>{
        'twoFactorEnabled': _twoFactorEnabled,
        'appTheme': _appTheme.index,
        'appLanguage': _appLanguage.index,
        'autoDetectLocalNetwork': _autoDetectLocalNetwork,
        'manualIpRange': _manualIpRange,
        'quickScan': _quickScan,
        'deepScan': _deepScan,
        'stealthScan': _stealthScan,
        'continuousMonitoring': _continuousMonitoring,
        'filterOnlyVulnerable': _filterOnlyVulnerable,
        'filterOnlyNewDevices': _filterOnlyNewDevices,
        'excludeTrustedDevices': _excludeTrustedDevices,
        'filterRouterIoTOnly': _filterRouterIoTOnly,
        'scanFrequency': _scanFrequency.index,
        'hostsPerScan': _hostsPerScan,
        'alertNewDevice': _alertNewDevice,
        'alertMacChange': _alertMacChange,
        'alertArpSpoof': _alertArpSpoof,
        'alertPortScanAttempts': _alertPortScanAttempts,
        'routerWeakPassword': _routerWeakPassword,
        'routerOpenPorts': _routerOpenPorts,
        'routerOutdatedFirmware': _routerOutdatedFirmware,
        'routerUpnpCheck': _routerUpnpCheck,
        'routerWpsCheck': _routerWpsCheck,
        'routerDnsHijack': _routerDnsHijack,
        'iotOutdatedFirmware': _iotOutdatedFirmware,
        'iotDefaultPasswords': _iotDefaultPasswords,
        'iotVulnDbMatch': _iotVulnDbMatch,
        'iotAutoRecommendations': _iotAutoRecommendations,
        'packetSnifferLite': _packetSnifferLite,
        'wifiDeauthDetection': _wifiDeauthDetection,
        'rogueApDetection': _rogueApDetection,
        'hiddenSsidDetection': _hiddenSsidDetection,
        'notifyNewDevice': _notifyNewDevice,
        'notifyUnknownDevice': _notifyUnknownDevice,
        'notifyRouterVuln': _notifyRouterVuln,
        'notifyIotWarning': _notifyIotWarning,
        'notifyHighRisk': _notifyHighRisk,
        'notifyScanCompleted': _notifyScanCompleted,
        'notifyAutoScanResults': _notifyAutoScanResults,
        'alertSoundEnabled': _alertSoundEnabled,
        'alertVibrationEnabled': _alertVibrationEnabled,
        'alertSilentMode': _alertSilentMode,
        'alertSensitivity': _alertSensitivity.index,
        'logRetentionDays': _logRetentionDays,
        'anonymousUsageAnalytics': _anonymousUsageAnalytics,
        'performanceMode': _performanceMode.index,
        'autoStartOnBoot': _autoStartOnBoot,
        'autoScanOnLaunch': _autoScanOnLaunch,
        'keepScreenAwake': _keepScreenAwake,
        'autoUpdateApp': _autoUpdateApp,
        'notifyBeforeUpdate': _notifyBeforeUpdate,
        'betaUpdates': _betaUpdates,
        'aiAssistantEnabled': _aiAssistantEnabled,
        'aiExplainVuln': _aiExplainVuln,
        'aiOneClickFix': _aiOneClickFix,
        'aiRiskScoring': _aiRiskScoring,
        'aiRouterHardening': _aiRouterHardening,
        'aiDetectUnnecessaryServices': _aiDetectUnnecessaryServices,
        'aiProactiveWarnings': _aiProactiveWarnings,
        'betaBehaviourThreatDetection': _betaBehaviourThreatDetection,
        'betaLocalMlProfiling': _betaLocalMlProfiling,
        'betaIotFingerprinting': _betaIotFingerprinting,
      };

      await _prefs!.setString('scanx_settings_v1', jsonEncode(map));
      debugPrint('[SCANX][Settings] Saved settings: $map');
    } catch (e, st) {
      debugPrint('[SCANX][Settings] Error saving settings: $e');
      debugPrint(st.toString());
    }
  }

  // ---------- DISPLAY HELPERS ----------

  String _themeLabel(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return 'Light';
      case AppTheme.dark:
        return 'Dark';
      case AppTheme.amoled:
        return 'AMOLED Black';
      case AppTheme.system:
        return 'Follow System';
    }
  }

  String _languageLabel(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.english:
        return 'English';
      case AppLanguage.hindi:
        return 'Hindi';
      case AppLanguage.indonesian:
        return 'Indonesian';
      case AppLanguage.filipino:
        return 'Filipino';
      case AppLanguage.chineseSimplified:
        return 'Simplified Chinese';
      case AppLanguage.arabic:
        return 'Arabic';
    }
  }

  String _scanFrequencyLabel(ScanFrequency f) {
    switch (f) {
      case ScanFrequency.manual:
        return 'Manual';
      case ScanFrequency.fiveMinutes:
        return 'Every 5 minutes';
      case ScanFrequency.fifteenMinutes:
        return 'Every 15 minutes';
      case ScanFrequency.oneHour:
        return 'Every 1 hour';
      case ScanFrequency.oneDay:
        return 'Every 24 hours';
    }
  }

  String _alertSensitivityLabel(AlertSensitivity s) {
    switch (s) {
      case AlertSensitivity.low:
        return 'Low (only major issues)';
      case AlertSensitivity.medium:
        return 'Medium';
      case AlertSensitivity.high:
        return 'High (every event)';
    }
  }

  String _performanceModeLabel(PerformanceMode m) {
    switch (m) {
      case PerformanceMode.batterySaver:
        return 'Battery Saver';
      case PerformanceMode.balanced:
        return 'Balanced';
      case PerformanceMode.performance:
        return 'Performance';
    }
  }

  String _hostsPerScanLabel(int value) {
    if (value == 0) return 'All hosts (full subnet)';
    return '$value hosts per scan';
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          _buildAccountSection(),
          _buildNetworkScanSection(),
          _buildSecuritySection(),
          _buildNotificationsSection(),
          _buildDataLogsSection(),
          _buildAppPreferencesSection(),
          _buildToolsSection(),
          _buildExperimentalSection(),
          _buildSupportLegalSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // SECTION 1: Account & User Settings
  Widget _buildAccountSection() {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.person),
        title: const Text('Account & User Settings'),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        children: [
          const SizedBox(height: 8),
          const Text(
            'Profile',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Name'),
            onTap: () {
              // TODO: Implement Edit Name
            },
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Edit Email'),
            onTap: () {
              // TODO: Implement Edit Email
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Change Password'),
            onTap: () {
              // TODO: Implement Change Password
            },
          ),
          SwitchListTile(
            title: const Text('Two-Factor Authentication'),
            secondary: const Icon(Icons.security),
            value: _twoFactorEnabled,
            onChanged: (v) {
              setState(() => _twoFactorEnabled = v);
              _saveSettings();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text(
              'Delete Account',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              // TODO: Implement Delete Account confirmation
            },
          ),
          const Divider(),
          const Text(
            'App Theme',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text('Theme'),
            trailing: DropdownButton<AppTheme>(
              value: _appTheme,
              onChanged: (v) {
                if (v == null) return;
                setState(() => _appTheme = v);
                _saveSettings();
              },
              items: AppTheme.values
                  .map(
                    (t) => DropdownMenuItem(
                  value: t,
                  child: Text(_themeLabel(t)),
                ),
              )
                  .toList(),
            ),
          ),
          const Divider(),
          const Text(
            'Language',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('App Language'),
            trailing: DropdownButton<AppLanguage>(
              value: _appLanguage,
              onChanged: (v) {
                if (v == null) return;
                setState(() => _appLanguage = v);
                _saveSettings();
              },
              items: AppLanguage.values
                  .map(
                    (l) => DropdownMenuItem(
                  value: l,
                  child: Text(_languageLabel(l)),
                ),
              )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  // SECTION 2: Network Scan Settings
  Widget _buildNetworkScanSection() {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.wifi),
        title: const Text('Network Scan Settings'),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        children: [
          const SizedBox(height: 8),
          const Text(
            'Scan Preferences',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SwitchListTile(
            title: const Text('Auto-detect local network'),
            value: _autoDetectLocalNetwork,
            onChanged: (v) {
              setState(() => _autoDetectLocalNetwork = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Manual IP range input'),
            value: _manualIpRange,
            onChanged: (v) {
              setState(() => _manualIpRange = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Quick Scan (Fast)'),
            value: _quickScan,
            onChanged: (v) {
              setState(() => _quickScan = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Deep Scan (Thorough)'),
            value: _deepScan,
            onChanged: (v) {
              setState(() => _deepScan = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Stealth Scan (Silent Mode)'),
            value: _stealthScan,
            onChanged: (v) {
              setState(() => _stealthScan = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Continuous Monitoring Mode'),
            value: _continuousMonitoring,
            onChanged: (v) {
              setState(() => _continuousMonitoring = v);
              _saveSettings();
            },
          ),

          // NEW: Hosts per scan
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('Hosts per scan'),
            subtitle: Text(_hostsPerScanLabel(_hostsPerScan)),
            trailing: DropdownButton<int>(
              value: _hostsPerScan,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _hostsPerScan = value);
                _saveSettings();
              },
              items: const [
                DropdownMenuItem(value: 16, child: Text('16')),
                DropdownMenuItem(value: 32, child: Text('32')),
                DropdownMenuItem(value: 64, child: Text('64')),
                DropdownMenuItem(value: 128, child: Text('128')),
                DropdownMenuItem(value: 256, child: Text('256')),
                DropdownMenuItem(value: 512, child: Text('512')),
                DropdownMenuItem(value: 1024, child: Text('1024')),
                DropdownMenuItem(
                  value: 0,
                  child: Text('All hosts'),
                ),
              ],
            ),
          ),

          const Divider(),
          const Text(
            'Smart Scan Filters',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SwitchListTile(
            title: const Text('Show only vulnerable devices'),
            value: _filterOnlyVulnerable,
            onChanged: (v) {
              setState(() => _filterOnlyVulnerable = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Show only new devices'),
            value: _filterOnlyNewDevices,
            onChanged: (v) {
              setState(() => _filterOnlyNewDevices = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Exclude known trusted devices'),
            value: _excludeTrustedDevices,
            onChanged: (v) {
              setState(() => _excludeTrustedDevices = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Show router-connected IoT only'),
            value: _filterRouterIoTOnly,
            onChanged: (v) {
              setState(() => _filterRouterIoTOnly = v);
              _saveSettings();
            },
          ),
          const Divider(),
          const Text(
            'Scan Frequency',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Auto-scan frequency'),
            subtitle: Text(_scanFrequencyLabel(_scanFrequency)),
            trailing: DropdownButton<ScanFrequency>(
              value: _scanFrequency,
              onChanged: (v) {
                if (v == null) return;
                setState(() => _scanFrequency = v);
                _saveSettings();
              },
              items: ScanFrequency.values
                  .map(
                    (f) => DropdownMenuItem(
                  value: f,
                  child: Text(_scanFrequencyLabel(f)),
                ),
              )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  // SECTION 3: Security & Protection Settings
  Widget _buildSecuritySection() {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.shield),
        title: const Text('Security & Protection'),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        children: [
          const SizedBox(height: 8),
          const Text(
            'Intrusion Detection',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SwitchListTile(
            title: const Text('Alert on new device'),
            value: _alertNewDevice,
            onChanged: (v) {
              setState(() => _alertNewDevice = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Alert on MAC address change'),
            value: _alertMacChange,
            onChanged: (v) {
              setState(() => _alertMacChange = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Alert on ARP spoofing'),
            value: _alertArpSpoof,
            onChanged: (v) {
              setState(() => _alertArpSpoof = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Alert on port scanning attempts'),
            value: _alertPortScanAttempts,
            onChanged: (v) {
              setState(() => _alertPortScanAttempts = v);
              _saveSettings();
            },
          ),
          const Divider(),
          const Text(
            'Router Security Checks',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SwitchListTile(
            title: const Text('Weak password detection'),
            value: _routerWeakPassword,
            onChanged: (v) {
              setState(() => _routerWeakPassword = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Open ports audit'),
            value: _routerOpenPorts,
            onChanged: (v) {
              setState(() => _routerOpenPorts = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Outdated firmware warning'),
            value: _routerOutdatedFirmware,
            onChanged: (v) {
              setState(() => _routerOutdatedFirmware = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('UPnP exploit check'),
            value: _routerUpnpCheck,
            onChanged: (v) {
              setState(() => _routerUpnpCheck = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('WPS vulnerability check'),
            value: _routerWpsCheck,
            onChanged: (v) {
              setState(() => _routerWpsCheck = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('DNS hijack check'),
            value: _routerDnsHijack,
            onChanged: (v) {
              setState(() => _routerDnsHijack = v);
              _saveSettings();
            },
          ),
          const Divider(),
          const Text(
            'IoT Security',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SwitchListTile(
            title: const Text('Outdated IoT firmware alerts'),
            value: _iotOutdatedFirmware,
            onChanged: (v) {
              setState(() => _iotOutdatedFirmware = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Default password detection'),
            value: _iotDefaultPasswords,
            onChanged: (v) {
              setState(() => _iotDefaultPasswords = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('IoT vulnerability DB matching'),
            value: _iotVulnDbMatch,
            onChanged: (v) {
              setState(() => _iotVulnDbMatch = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Auto-recommendations for securing devices'),
            value: _iotAutoRecommendations,
            onChanged: (v) {
              setState(() => _iotAutoRecommendations = v);
              _saveSettings();
            },
          ),
          const Divider(),
          const Text(
            'Advanced Security (Pro)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SwitchListTile(
            title: const Text('Packet Sniffer Lite'),
            value: _packetSnifferLite,
            onChanged: (v) {
              setState(() => _packetSnifferLite = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('WiFi deauth attempt detection'),
            value: _wifiDeauthDetection,
            onChanged: (v) {
              setState(() => _wifiDeauthDetection = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Rogue access point detection'),
            value: _rogueApDetection,
            onChanged: (v) {
              setState(() => _rogueApDetection = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Hidden SSID detection'),
            value: _hiddenSsidDetection,
            onChanged: (v) {
              setState(() => _hiddenSsidDetection = v);
              _saveSettings();
            },
          ),
        ],
      ),
    );
  }

  // SECTION 4: Notifications & Alerts
  Widget _buildNotificationsSection() {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.notifications),
        title: const Text('Notifications & Alerts'),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        children: [
          const SizedBox(height: 8),
          const Text(
            'Push Notifications',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SwitchListTile(
            title: const Text('New device connected'),
            value: _notifyNewDevice,
            onChanged: (v) {
              setState(() => _notifyNewDevice = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Unknown device detected'),
            value: _notifyUnknownDevice,
            onChanged: (v) {
              setState(() => _notifyUnknownDevice = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Router vulnerability found'),
            value: _notifyRouterVuln,
            onChanged: (v) {
              setState(() => _notifyRouterVuln = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('IoT security warning'),
            value: _notifyIotWarning,
            onChanged: (v) {
              setState(() => _notifyIotWarning = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('High-risk alert (critical)'),
            value: _notifyHighRisk,
            onChanged: (v) {
              setState(() => _notifyHighRisk = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Scan completed notification'),
            value: _notifyScanCompleted,
            onChanged: (v) {
              setState(() => _notifyScanCompleted = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Auto-scan results notification'),
            value: _notifyAutoScanResults,
            onChanged: (v) {
              setState(() => _notifyAutoScanResults = v);
              _saveSettings();
            },
          ),
          const Divider(),
          const Text(
            'Sounds & Vibration',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SwitchListTile(
            title: const Text('Alert sounds'),
            value: _alertSoundEnabled,
            onChanged: (v) {
              setState(() => _alertSoundEnabled = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Vibrate on alert'),
            value: _alertVibrationEnabled,
            onChanged: (v) {
              setState(() => _alertVibrationEnabled = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Silent mode'),
            value: _alertSilentMode,
            onChanged: (v) {
              setState(() => _alertSilentMode = v);
              _saveSettings();
            },
          ),
          const Divider(),
          const Text(
            'Alert Sensitivity',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Alert sensitivity'),
            subtitle: Text(_alertSensitivityLabel(_alertSensitivity)),
            trailing: DropdownButton<AlertSensitivity>(
              value: _alertSensitivity,
              onChanged: (v) {
                if (v == null) return;
                setState(() => _alertSensitivity = v);
                _saveSettings();
              },
              items: AlertSensitivity.values
                  .map(
                    (s) => DropdownMenuItem(
                  value: s,
                  child: Text(_alertSensitivityLabel(s)),
                ),
              )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  // SECTION 5: Data & Logs Settings
  Widget _buildDataLogsSection() {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.storage),
        title: const Text('Data & Logs'),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        children: [
          const SizedBox(height: 8),
          const Text(
            'Activity Logs',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('View scan history'),
            onTap: () {
              // TODO: Navigate to Scan History
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('Export logs (PDF / CSV)'),
            onTap: () {
              // TODO: Implement log export
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Auto-delete logs after'),
            subtitle: Text(
              _logRetentionDays == 0 ? 'Never' : '$_logRetentionDays days',
            ),
            trailing: DropdownButton<int>(
              value: _logRetentionDays,
              onChanged: (v) {
                if (v == null) return;
                setState(() => _logRetentionDays = v);
                _saveSettings();
              },
              items: const [
                DropdownMenuItem(
                  value: 7,
                  child: Text('7 days'),
                ),
                DropdownMenuItem(
                  value: 30,
                  child: Text('30 days'),
                ),
                DropdownMenuItem(
                  value: 90,
                  child: Text('90 days'),
                ),
                DropdownMenuItem(
                  value: 0,
                  child: Text('Never'),
                ),
              ],
            ),
          ),
          const Divider(),
          const Text(
            'Data Export',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('Export network report'),
            onTap: () {
              // TODO: Implement export
            },
          ),
          ListTile(
            leading: const Icon(Icons.devices_other),
            title: const Text('Export IoT device list'),
            onTap: () {
              // TODO: Implement export
            },
          ),
          ListTile(
            leading: const Icon(Icons.router),
            title: const Text('Export router health report'),
            onTap: () {
              // TODO: Implement export
            },
          ),
          const Divider(),
          const Text(
            'Privacy Control',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SwitchListTile(
            title: const Text('Anonymous usage analytics'),
            value: _anonymousUsageAnalytics,
            onChanged: (v) {
              setState(() => _anonymousUsageAnalytics = v);
              _saveSettings();
            },
          ),
          ListTile(
            leading: const Icon(Icons.cleaning_services),
            title: const Text('Clear local cache'),
            onTap: () {
              // TODO: Implement clear cache
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep),
            title: const Text('Delete all logs'),
            onTap: () {
              // TODO: Confirm & delete logs
            },
          ),
        ],
      ),
    );
  }

  // SECTION 6: App Preferences
  Widget _buildAppPreferencesSection() {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.settings_applications),
        title: const Text('App Preferences'),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        children: [
          const SizedBox(height: 8),
          const Text(
            'Performance Mode',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ListTile(
            leading: const Icon(Icons.speed),
            title: const Text('Performance mode'),
            subtitle: Text(_performanceModeLabel(_performanceMode)),
            trailing: DropdownButton<PerformanceMode>(
              value: _performanceMode,
              onChanged: (v) {
                if (v == null) return;
                setState(() => _performanceMode = v);
                _saveSettings();
              },
              items: PerformanceMode.values
                  .map(
                    (m) => DropdownMenuItem(
                  value: m,
                  child: Text(_performanceModeLabel(m)),
                ),
              )
                  .toList(),
            ),
          ),
          const Divider(),
          const Text(
            'App Behaviour',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SwitchListTile(
            title: const Text('Auto-start on device boot'),
            value: _autoStartOnBoot,
            onChanged: (v) {
              setState(() => _autoStartOnBoot = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Auto-scan on app launch'),
            value: _autoScanOnLaunch,
            onChanged: (v) {
              setState(() => _autoScanOnLaunch = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Keep screen awake during scan'),
            value: _keepScreenAwake,
            onChanged: (v) {
              setState(() => _keepScreenAwake = v);
              _saveSettings();
            },
          ),
          const Divider(),
          const Text(
            'Update Settings',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SwitchListTile(
            title: const Text('Auto-update app'),
            value: _autoUpdateApp,
            onChanged: (v) {
              setState(() => _autoUpdateApp = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Notify me before updating'),
            value: _notifyBeforeUpdate,
            onChanged: (v) {
              setState(() => _notifyBeforeUpdate = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Check for beta updates'),
            value: _betaUpdates,
            onChanged: (v) {
              setState(() => _betaUpdates = v);
              _saveSettings();
            },
          ),
        ],
      ),
    );
  }

  // SECTION 7: Tools & Utilities
  Widget _buildToolsSection() {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.build),
        title: const Text('Tools & Utilities'),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        children: [
          const SizedBox(height: 8),
          const Text(
            'Network Tools',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ListTile(
            leading: const Icon(Icons.network_ping),
            title: const Text('Ping tool'),
            onTap: () {
              // TODO: Navigate to Ping Tool
            },
          ),
          ListTile(
            leading: const Icon(Icons.dns),
            title: const Text('Port scanner'),
            onTap: () {
              // TODO: Navigate to Port Scanner
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('DNS lookup'),
            onTap: () {
              // TODO: Navigate to DNS Lookup
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('WHOIS lookup'),
            onTap: () {
              // TODO: Navigate to WHOIS
            },
          ),
          ListTile(
            leading: const Icon(Icons.alt_route),
            title: const Text('Trace route'),
            onTap: () {
              // TODO: Navigate to Traceroute
            },
          ),
          const Divider(),
          const Text(
            'WiFi Tools',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ListTile(
            leading: const Icon(Icons.wifi_tethering),
            title: const Text('Signal strength meter'),
            onTap: () {
              // TODO: Navigate to signal strength
            },
          ),
          ListTile(
            leading: const Icon(Icons.wifi_channel),
            title: const Text('Channel overlap analyzer'),
            onTap: () {
              // TODO: Navigate to channel analyzer
            },
          ),
          ListTile(
            leading: const Icon(Icons.speed),
            title: const Text('Bandwidth monitor'),
            onTap: () {
              // TODO: Navigate to bandwidth monitor
            },
          ),
          ListTile(
            leading: const Icon(Icons.graphic_eq),
            title: const Text('Interference detector'),
            onTap: () {
              // TODO: Navigate to interference detector
            },
          ),
          const Divider(),
          const Text(
            'Device Finder',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ListTile(
            leading: const Icon(Icons.location_searching),
            title: const Text('Locate device via signal strength'),
            onTap: () {
              // TODO: Navigate to device finder
            },
          ),
          ListTile(
            leading: const Icon(Icons.track_changes),
            title: const Text('Real-time tracking mode'),
            onTap: () {
              // TODO: Navigate to tracking mode
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.router),
            title: const Text('Router login shortcut'),
            onTap: () {
              // TODO: Implement router login shortcut
            },
          ),
        ],
      ),
    );
  }

  // SECTION 8: Experimental & AI Features
  Widget _buildExperimentalSection() {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.auto_awesome),
        title: const Text('Experimental & AI Features'),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        children: [
          const SizedBox(height: 8),
          const Text(
            'SCAN-X AI Assistant',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SwitchListTile(
            title: const Text('Enable SCAN-X AI Assistant'),
            value: _aiAssistantEnabled,
            onChanged: (v) {
              setState(() => _aiAssistantEnabled = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Explain vulnerabilities in simple terms'),
            value: _aiExplainVuln,
            onChanged: (v) {
              setState(() => _aiExplainVuln = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('One-click fix recommendations'),
            value: _aiOneClickFix,
            onChanged: (v) {
              setState(() => _aiOneClickFix = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('AI device risk scoring'),
            value: _aiRiskScoring,
            onChanged: (v) {
              setState(() => _aiRiskScoring = v);
              _saveSettings();
            },
          ),
          const Divider(),
          const Text(
            'AI Router Hardening',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SwitchListTile(
            title: const Text('Auto-generate best router settings'),
            value: _aiRouterHardening,
            onChanged: (v) {
              setState(() => _aiRouterHardening = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Detect unnecessary router services'),
            value: _aiDetectUnnecessaryServices,
            onChanged: (v) {
              setState(() => _aiDetectUnnecessaryServices = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Proactive warnings before attacks'),
            value: _aiProactiveWarnings,
            onChanged: (v) {
              setState(() => _aiProactiveWarnings = v);
              _saveSettings();
            },
          ),
          const Divider(),
          const Text(
            'Beta Features',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SwitchListTile(
            title: const Text('Behaviour-based threat detection'),
            value: _betaBehaviourThreatDetection,
            onChanged: (v) {
              setState(() => _betaBehaviourThreatDetection = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Local ML model for device profiling'),
            value: _betaLocalMlProfiling,
            onChanged: (v) {
              setState(() => _betaLocalMlProfiling = v);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('IoT device fingerprinting'),
            value: _betaIotFingerprinting,
            onChanged: (v) {
              setState(() => _betaIotFingerprinting = v);
              _saveSettings();
            },
          ),
        ],
      ),
    );
  }

  // SECTION 9: Support & Legal
  Widget _buildSupportLegalSection() {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.help_outline),
        title: const Text('Support & Legal'),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        children: [
          const SizedBox(height: 8),
          const Text(
            'Support',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ListTile(
            leading: const Icon(Icons.question_answer),
            title: const Text('FAQs'),
            onTap: () {
              // TODO: Navigate to FAQs
            },
          ),
          ListTile(
            leading: const Icon(Icons.build_circle),
            title: const Text('Troubleshooting guides'),
            onTap: () {
              // TODO: Navigate to troubleshooting
            },
          ),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('Report a bug'),
            onTap: () {
              // TODO: Implement bug report
            },
          ),
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: const Text('Contact support'),
            onTap: () {
              // TODO: Implement contact support
            },
          ),
          const Divider(),
          const Text(
            'Legal',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ListTile(
            leading: const Icon(Icons.article),
            title: const Text('Terms & Conditions'),
            onTap: () {
              // TODO: Navigate to Terms
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            onTap: () {
              // TODO: Navigate to Privacy Policy
            },
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Open source licenses'),
            onTap: () {
              // TODO: Navigate to OSS licenses
            },
          ),
        ],
      ),
    );
  }
}
