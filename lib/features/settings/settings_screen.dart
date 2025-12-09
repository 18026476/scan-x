// lib/features/settings/settings_screen.dart

import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  // -------- LOCAL STATE (visual only for now) --------

  // Scan & detection
  bool quickScan = true;
  bool deepScan = false;
  bool stealthScan = false;
  bool continuousMonitoring = false;
  int scanFrequency = 0; // 0 = manual, 1 = hourly, etc.
  int hostsPerScan = 256;

  // Router & IoT
  bool routerWeakPassword = true;
  bool routerOpenPorts = true;
  bool routerOutdatedFirmware = true;
  bool routerUpnpCheck = true;
  bool routerWpsCheck = true;
  bool routerDnsHijack = true;

  bool iotOutdatedFirmware = true;
  bool iotDefaultPasswords = true;
  bool iotVulnDbMatch = true;
  bool iotAutoRecommendations = true;

  // Alerts (engine level)
  bool alertNewDevice = true;
  bool alertMacChange = true;
  bool alertArpSpoof = true;
  bool alertPortScanAttempts = true;

  // Notifications (user-facing)
  bool notifyNewDevice = false;
  bool notifyUnknownDevice = false;
  bool notifyRouterVuln = false;
  bool notifyIotWarning = false;
  bool notifyHighRisk = true;
  bool notifyScanCompleted = true;
  bool notifyAutoScanResults = true;

  // Alert style
  bool alertSoundEnabled = true;
  bool alertVibrationEnabled = true;
  bool alertSilentMode = false;
  double alertSensitivity = 1; // 0 = low, 1 = normal, 2 = aggressive

  // App & privacy
  bool twoFactorEnabled = true;
  int appTheme = 3; // 0 system, 1 light, 2 dark, 3 SCAN-X dark
  int appLanguage = 0; // 0 EN, others later

  int logRetentionDays = 30;
  bool anonymousUsageAnalytics = false;
  int performanceMode = 1; // 0 battery saver, 1 balanced, 2 performance

  bool autoStartOnBoot = false;
  bool autoScanOnLaunch = false;
  bool keepScreenAwake = false;

  bool autoUpdateApp = true;
  bool notifyBeforeUpdate = true;
  bool betaUpdates = false;

  // AI & Labs
  bool aiAssistantEnabled = true;
  bool aiExplainVuln = true;
  bool aiOneClickFix = true;
  bool aiRiskScoring = true;
  bool aiRouterHardening = false;
  bool aiDetectUnnecessaryServices = false;
  bool aiProactiveWarnings = false;

  bool packetSnifferLite = false;
  bool wifiDeauthDetection = false;
  bool rogueApDetection = false;
  bool hiddenSsidDetection = false;

  bool betaBehaviourThreatDetection = false;
  bool betaLocalMlProfiling = false;
  bool betaIotFingerprinting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          centerTitle: true,
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Scan & detection'),
              Tab(text: 'Router & IoT'),
              Tab(text: 'Alerts'),
              Tab(text: 'App & privacy'),
              Tab(text: 'AI & labs'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildScanTab(theme),
            _buildRouterIotTab(theme),
            _buildAlertsTab(theme),
            _buildAppPrivacyTab(theme),
            _buildAiLabsTab(theme),
          ],
        ),
      ),
    );
  }

  // ------------- TAB 1: SCAN & DETECTION -------------

  Widget _buildScanTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('Scan modes'),
        _switchTile(
          title: 'Quick Smart Scan',
          subtitle: 'Fast scan of common ports and hosts.',
          value: quickScan,
          onChanged: (v) => setState(() => quickScan = v),
        ),
        _switchTile(
          title: 'Deep scan',
          subtitle: 'Slower, full-port scan for more detail.',
          value: deepScan,
          onChanged: (v) => setState(() => deepScan = v),
        ),
        _switchTile(
          title: 'Stealth scan',
          subtitle: 'Use quieter scan patterns to reduce detection.',
          value: stealthScan,
          onChanged: (v) => setState(() => stealthScan = v),
        ),
        _switchTile(
          title: 'Continuous monitoring',
          subtitle: 'Keep watching for new devices and changes in background.',
          value: continuousMonitoring,
          onChanged: (v) => setState(() => continuousMonitoring = v),
        ),
        const SizedBox(height: 16),
        _sectionTitle('Scan schedule'),
        ListTile(
          title: const Text('Scan frequency'),
          subtitle: Text(_scanFrequencyLabel(scanFrequency)),
          trailing: DropdownButton<int>(
            value: scanFrequency,
            onChanged: (v) {
              if (v == null) return;
              setState(() => scanFrequency = v);
            },
            items: const [
              DropdownMenuItem(value: 0, child: Text('Manual only')),
              DropdownMenuItem(value: 1, child: Text('Every hour')),
              DropdownMenuItem(value: 2, child: Text('Every 6 hours')),
              DropdownMenuItem(value: 3, child: Text('Once per day')),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ListTile(
          title: const Text('Max hosts per scan'),
          subtitle: Text('$hostsPerScan hosts'),
        ),
        Slider(
          value: hostsPerScan.toDouble(),
          min: 32,
          max: 1024,
          divisions: (1024 - 32) ~/ 32,
          label: hostsPerScan.toString(),
          onChanged: (v) => setState(() => hostsPerScan = v.round()),
        ),
      ],
    );
  }

  String _scanFrequencyLabel(int value) {
    switch (value) {
      case 1:
        return 'Every hour';
      case 2:
        return 'Every 6 hours';
      case 3:
        return 'Once per day';
      default:
        return 'Manual only';
    }
  }

  // ------------- TAB 2: ROUTER & IOT -------------

  Widget _buildRouterIotTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('Router checks'),
        _switchTile(
          title: 'Weak / default router password',
          subtitle: 'Warn if router uses weak or known default credentials.',
          value: routerWeakPassword,
          onChanged: (v) => setState(() => routerWeakPassword = v),
        ),
        _switchTile(
          title: 'Open risky ports',
          subtitle: 'Detect exposed management or insecure WAN ports.',
          value: routerOpenPorts,
          onChanged: (v) => setState(() => routerOpenPorts = v),
        ),
        _switchTile(
          title: 'Outdated firmware',
          subtitle: 'Flag routers that haven’t been patched in a while.',
          value: routerOutdatedFirmware,
          onChanged: (v) => setState(() => routerOutdatedFirmware = v),
        ),
        _switchTile(
          title: 'UPnP exposure',
          subtitle: 'Detect unsafe automatic port-forwarding.',
          value: routerUpnpCheck,
          onChanged: (v) => setState(() => routerUpnpCheck = v),
        ),
        _switchTile(
          title: 'WPS enabled',
          subtitle: 'Warn about WPS (easy-connect) being enabled.',
          value: routerWpsCheck,
          onChanged: (v) => setState(() => routerWpsCheck = v),
        ),
        _switchTile(
          title: 'DNS hijack / redirection',
          subtitle: 'Check for suspicious DNS servers.',
          value: routerDnsHijack,
          onChanged: (v) => setState(() => routerDnsHijack = v),
        ),
        const SizedBox(height: 16),
        _sectionTitle('IoT device checks'),
        _switchTile(
          title: 'Outdated IoT firmware',
          subtitle: 'Flag smart devices with very old firmware versions.',
          value: iotOutdatedFirmware,
          onChanged: (v) => setState(() => iotOutdatedFirmware = v),
        ),
        _switchTile(
          title: 'Default / weak IoT passwords',
          subtitle: 'Detect common default credentials on cameras, DVRs, etc.',
          value: iotDefaultPasswords,
          onChanged: (v) => setState(() => iotDefaultPasswords = v),
        ),
        _switchTile(
          title: 'Known vulnerabilities (CVE / vuln DB)',
          subtitle: 'Match IoT fingerprints against known vulnerability feeds.',
          value: iotVulnDbMatch,
          onChanged: (v) => setState(() => iotVulnDbMatch = v),
        ),
        _switchTile(
          title: 'Auto recommendations',
          subtitle: 'Show simple hardening tips for each risky IoT device.',
          value: iotAutoRecommendations,
          onChanged: (v) => setState(() => iotAutoRecommendations = v),
        ),
      ],
    );
  }

  // ------------- TAB 3: ALERTS & NOTIFICATIONS -------------

  Widget _buildAlertsTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('Detection rules'),
        _switchTile(
          title: 'New device joins network',
          value: alertNewDevice,
          onChanged: (v) => setState(() => alertNewDevice = v),
        ),
        _switchTile(
          title: 'Device MAC address changed',
          value: alertMacChange,
          onChanged: (v) => setState(() => alertMacChange = v),
        ),
        _switchTile(
          title: 'Possible ARP spoofing',
          value: alertArpSpoof,
          onChanged: (v) => setState(() => alertArpSpoof = v),
        ),
        _switchTile(
          title: 'Port-scan attempts detected',
          value: alertPortScanAttempts,
          onChanged: (v) => setState(() => alertPortScanAttempts = v),
        ),
        const SizedBox(height: 16),
        _sectionTitle('Notifications'),
        _switchTile(
          title: 'Notify on new device',
          value: notifyNewDevice,
          onChanged: (v) => setState(() => notifyNewDevice = v),
        ),
        _switchTile(
          title: 'Notify on unknown / untrusted device',
          value: notifyUnknownDevice,
          onChanged: (v) => setState(() => notifyUnknownDevice = v),
        ),
        _switchTile(
          title: 'Notify on router vulnerability',
          value: notifyRouterVuln,
          onChanged: (v) => setState(() => notifyRouterVuln = v),
        ),
        _switchTile(
          title: 'Notify on IoT warning',
          value: notifyIotWarning,
          onChanged: (v) => setState(() => notifyIotWarning = v),
        ),
        _switchTile(
          title: 'Notify on HIGH-risk findings',
          value: notifyHighRisk,
          onChanged: (v) => setState(() => notifyHighRisk = v),
        ),
        _switchTile(
          title: 'Notify when scan completes',
          value: notifyScanCompleted,
          onChanged: (v) => setState(() => notifyScanCompleted = v),
        ),
        _switchTile(
          title: 'Notify on scheduled auto-scan results',
          value: notifyAutoScanResults,
          onChanged: (v) => setState(() => notifyAutoScanResults = v),
        ),
        const SizedBox(height: 16),
        _sectionTitle('Alert style'),
        _switchTile(
          title: 'Sound',
          value: alertSoundEnabled,
          onChanged: (v) => setState(() => alertSoundEnabled = v),
        ),
        _switchTile(
          title: 'Vibration / haptic feedback',
          value: alertVibrationEnabled,
          onChanged: (v) => setState(() => alertVibrationEnabled = v),
        ),
        _switchTile(
          title: 'Silent mode',
          subtitle: 'Mute sound and vibration but keep in-app banners.',
          value: alertSilentMode,
          onChanged: (v) => setState(() => alertSilentMode = v),
        ),
        const SizedBox(height: 8),
        ListTile(
          title: const Text('Alert sensitivity'),
          subtitle: Text(_alertSensitivityLabel(alertSensitivity)),
        ),
        Slider(
          value: alertSensitivity,
          min: 0,
          max: 2,
          divisions: 2,
          label: _alertSensitivityLabel(alertSensitivity),
          onChanged: (v) => setState(() => alertSensitivity = v),
        ),
      ],
    );
  }

  String _alertSensitivityLabel(double value) {
    if (value <= 0.25) return 'Low (only critical alerts)';
    if (value >= 1.75) return 'Aggressive (more noise, more detail)';
    return 'Normal';
  }

  // ------------- TAB 4: APP & PRIVACY -------------

  Widget _buildAppPrivacyTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('Account & security'),
        _switchTile(
          title: 'Two-factor authentication',
          subtitle: 'Require an extra step when logging into SCAN-X Cloud.',
          value: twoFactorEnabled,
          onChanged: (v) => setState(() => twoFactorEnabled = v),
        ),
        const SizedBox(height: 16),
        _sectionTitle('Appearance'),
        ListTile(
          title: const Text('Theme'),
          subtitle: Text(_themeLabel(appTheme)),
        ),
        Column(
          children: [
            RadioListTile<int>(
              title: const Text('System default'),
              value: 0,
              groupValue: appTheme,
              onChanged: (v) => setState(() => appTheme = v ?? appTheme),
            ),
            RadioListTile<int>(
              title: const Text('Light'),
              value: 1,
              groupValue: appTheme,
              onChanged: (v) => setState(() => appTheme = v ?? appTheme),
            ),
            RadioListTile<int>(
              title: const Text('Dark'),
              value: 2,
              groupValue: appTheme,
              onChanged: (v) => setState(() => appTheme = v ?? appTheme),
            ),
            RadioListTile<int>(
              title: const Text('SCAN-X Dark (recommended)'),
              value: 3,
              groupValue: appTheme,
              onChanged: (v) => setState(() => appTheme = v ?? appTheme),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _sectionTitle('Performance & behaviour'),
        _switchTile(
          title: 'Start with Windows / system boot',
          value: autoStartOnBoot,
          onChanged: (v) => setState(() => autoStartOnBoot = v),
        ),
        _switchTile(
          title: 'Auto-scan when app launches',
          value: autoScanOnLaunch,
          onChanged: (v) => setState(() => autoScanOnLaunch = v),
        ),
        _switchTile(
          title: 'Keep screen awake during scans',
          value: keepScreenAwake,
          onChanged: (v) => setState(() => keepScreenAwake = v),
        ),
        ListTile(
          title: const Text('Performance mode'),
          subtitle: Text(_performanceLabel(performanceMode)),
        ),
        Column(
          children: [
            RadioListTile<int>(
              title: const Text('Battery saver'),
              value: 0,
              groupValue: performanceMode,
              onChanged: (v) => setState(() => performanceMode = v ?? performanceMode),
            ),
            RadioListTile<int>(
              title: const Text('Balanced'),
              value: 1,
              groupValue: performanceMode,
              onChanged: (v) => setState(() => performanceMode = v ?? performanceMode),
            ),
            RadioListTile<int>(
              title: const Text('Performance'),
              value: 2,
              groupValue: performanceMode,
              onChanged: (v) => setState(() => performanceMode = v ?? performanceMode),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _sectionTitle('Privacy & data'),
        _switchTile(
          title: 'Anonymous usage analytics',
          subtitle: 'Help improve SCAN-X by sending anonymised stats.',
          value: anonymousUsageAnalytics,
          onChanged: (v) => setState(() => anonymousUsageAnalytics = v),
        ),
        ListTile(
          title: const Text('Log retention'),
          subtitle: Text('$logRetentionDays days'),
        ),
        Slider(
          value: logRetentionDays.toDouble(),
          min: 7,
          max: 365,
          divisions: (365 - 7),
          label: '$logRetentionDays days',
          onChanged: (v) => setState(() => logRetentionDays = v.round()),
        ),
        const SizedBox(height: 16),
        _sectionTitle('Updates'),
        _switchTile(
          title: 'Auto update app',
          value: autoUpdateApp,
          onChanged: (v) => setState(() => autoUpdateApp = v),
        ),
        _switchTile(
          title: 'Ask before installing updates',
          value: notifyBeforeUpdate,
          onChanged: (v) => setState(() => notifyBeforeUpdate = v),
        ),
        _switchTile(
          title: 'Enable beta / early access builds',
          value: betaUpdates,
          onChanged: (v) => setState(() => betaUpdates = v),
        ),
      ],
    );
  }

  String _themeLabel(int value) {
    switch (value) {
      case 1:
        return 'Light';
      case 2:
        return 'Dark';
      case 3:
        return 'SCAN-X Dark';
      default:
        return 'System default';
    }
  }

  String _performanceLabel(int value) {
    switch (value) {
      case 0:
        return 'Battery saver';
      case 2:
        return 'Performance';
      default:
        return 'Balanced';
    }
  }

  // ------------- TAB 5: AI & LABS -------------

  Widget _buildAiLabsTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('AI assistant'),
        _switchTile(
          title: 'SCAN-X AI assistant',
          subtitle: 'Explain findings and suggest actions in plain language.',
          value: aiAssistantEnabled,
          onChanged: (v) => setState(() => aiAssistantEnabled = v),
        ),
        _switchTile(
          title: 'Explain vulnerabilities',
          subtitle: 'Show “what this means” cards for each issue.',
          value: aiExplainVuln,
          onChanged: (v) => setState(() => aiExplainVuln = v),
        ),
        _switchTile(
          title: 'One-click fixes (where safe)',
          subtitle: 'Provide guided / automated fixes for common issues.',
          value: aiOneClickFix,
          onChanged: (v) => setState(() => aiOneClickFix = v),
        ),
        _switchTile(
          title: 'AI-driven risk scoring',
          subtitle: 'Smarter overall network health score.',
          value: aiRiskScoring,
          onChanged: (v) => setState(() => aiRiskScoring = v),
        ),
        _switchTile(
          title: 'Router hardening playbooks',
          subtitle: 'Generate router-specific lock-down checklists.',
          value: aiRouterHardening,
          onChanged: (v) => setState(() => aiRouterHardening = v),
        ),
        _switchTile(
          title: 'Detect unnecessary services',
          subtitle: 'Suggest disabling rarely used but risky services.',
          value: aiDetectUnnecessaryServices,
          onChanged: (v) => setState(() => aiDetectUnnecessaryServices = v),
        ),
        _switchTile(
          title: 'Proactive warnings',
          subtitle: 'Pre-emptively warn before things become high-risk.',
          value: aiProactiveWarnings,
          onChanged: (v) => setState(() => aiProactiveWarnings = v),
        ),
        const SizedBox(height: 16),
        _sectionTitle('Labs: traffic & Wi-Fi'),
        _switchTile(
          title: 'Packet sniffer (lite)',
          subtitle: 'Basic metadata capture for troubleshooting only.',
          value: packetSnifferLite,
          onChanged: (v) => setState(() => packetSnifferLite = v),
        ),
        _switchTile(
          title: 'Wi-Fi deauth detection',
          subtitle: 'Detect suspicious de-authentication activity.',
          value: wifiDeauthDetection,
          onChanged: (v) => setState(() => wifiDeauthDetection = v),
        ),
        _switchTile(
          title: 'Rogue AP detection',
          subtitle: 'Alert if a fake access point mimics your SSID.',
          value: rogueApDetection,
          onChanged: (v) => setState(() => rogueApDetection = v),
        ),
        _switchTile(
          title: 'Hidden SSID detection',
          subtitle: 'Flag hidden networks near you (experimental).',
          value: hiddenSsidDetection,
          onChanged: (v) => setState(() => hiddenSsidDetection = v),
        ),
        const SizedBox(height: 16),
        _sectionTitle('Experimental ML features'),
        _switchTile(
          title: 'Behaviour-based threat detection (beta)',
          value: betaBehaviourThreatDetection,
          onChanged: (v) => setState(() => betaBehaviourThreatDetection = v),
        ),
        _switchTile(
          title: 'Local ML profiling (beta)',
          value: betaLocalMlProfiling,
          onChanged: (v) => setState(() => betaLocalMlProfiling = v),
        ),
        _switchTile(
          title: 'IoT fingerprinting (beta)',
          value: betaIotFingerprinting,
          onChanged: (v) => setState(() => betaIotFingerprinting = v),
        ),
      ],
    );
  }

  // ------------- HELPERS -------------

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _switchTile({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      value: value,
      onChanged: onChanged,
      dense: false,
    );
  }
}
