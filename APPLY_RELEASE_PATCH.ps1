param(
  [Parameter(Mandatory=$false)]
  [string]$ProjectRoot = (Resolve-Path -LiteralPath '.').Path
)

$ErrorActionPreference = 'Stop'

function Timestamp() { Get-Date -Format 'yyyyMMdd_HHmmss' }
function Ensure-Dir([string]$dir) {
  if ([string]::IsNullOrWhiteSpace($dir)) { return }
  if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
}
function Backup-File([string]$path) {
  if (Test-Path -LiteralPath $path) {
    $bak = "$path.bak_$(Timestamp)"
    Copy-Item -LiteralPath $path -Destination $bak -Force
    Write-Host "Backup: $bak" -ForegroundColor DarkGray
  }
}
function Write-Utf8NoBom([string]$path, [string]$content) {
  $dir = Split-Path -Parent $path
  Ensure-Dir $dir
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
  Write-Host "Wrote: $path"
}

if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot 'pubspec.yaml'))) {
  throw "pubspec.yaml not found. Run this from your Flutter project root. Current: $ProjectRoot"
}

Write-Host "=== APPLY RELEASE PATCH: Toggle registry + Scan screen labs/ML summary ==="
Write-Host "ProjectRoot: $ProjectRoot"

# 1) toggle_wiring_registry.dart
$regPath = Join-Path $ProjectRoot 'lib\core\services\toggle_wiring_registry.dart'
Backup-File $regPath
Write-Utf8NoBom $regPath @'
/// Toggle wiring registry
///
/// Purpose:
/// - Provide a single inventory of *all* Settings toggles that should not be "dead".
/// - Support tests that prevent accidental removal / duplication and help enforce usage.
///
/// IMPORTANT
/// - `key` MUST match the SharedPreferences key used by `SettingsService`.
/// - `consumerHint` describes where this toggle should be consumed at runtime.
///
/// This file is intentionally data-only and safe to edit.

class ToggleWiring {
  final String key;
  final String area;
  final String settingGetter;
  final String consumerHint;

  const ToggleWiring({
    required this.key,
    required this.area,
    required this.settingGetter,
    required this.consumerHint,
  });
}

class ToggleWiringRegistry {
  /// If you add a new toggle in SettingsService + UI, add it here as well.
  static const List<ToggleWiring> toggles = [
    // ------------------------------------------------------------
    // Scan & detection
    // ------------------------------------------------------------
    ToggleWiring(
      key: 'stealth_scan',
      area: 'Scan & detection',
      settingGetter: 'SettingsService.stealthScan',
      consumerHint: 'ScanService: adds -sS and related flags',
    ),
    ToggleWiring(
      key: 'full_scan',
      area: 'Scan & detection',
      settingGetter: 'SettingsService.fullScan',
      consumerHint: 'ScanService: controls port depth / service detection',
    ),
    ToggleWiring(
      key: 'os_detection',
      area: 'Scan & detection',
      settingGetter: 'SettingsService.osDetection',
      consumerHint: 'ScanService: -O where supported',
    ),
    ToggleWiring(
      key: 'vuln_scripts',
      area: 'Scan & detection',
      settingGetter: 'SettingsService.vulnScripts',
      consumerHint: 'ScanService: --script=vuln where enabled',
    ),
    ToggleWiring(
      key: 'sniff_risky_ports',
      area: 'Scan & detection',
      settingGetter: 'SettingsService.riskyPorts',
      consumerHint: 'ScanService/analysis: add risky port findings',
    ),
    ToggleWiring(
      key: 'sniff_open_shares',
      area: 'Scan & detection',
      settingGetter: 'SettingsService.openShares',
      consumerHint: 'ScanService/analysis: SMB share heuristics',
    ),
    ToggleWiring(
      key: 'sniff_weak_tls',
      area: 'Scan & detection',
      settingGetter: 'SettingsService.weakTls',
      consumerHint: 'ScanService/analysis: TLS heuristic',
    ),

    // ------------------------------------------------------------
    // Router & IoT
    // ------------------------------------------------------------
    ToggleWiring(
      key: 'router_weak_password',
      area: 'Router & IoT',
      settingGetter: 'SettingsService.routerWeakPassword',
      consumerHint: 'Router/IoT analyzer: credential advisories',
    ),
    ToggleWiring(
      key: 'router_open_ports',
      area: 'Router & IoT',
      settingGetter: 'SettingsService.routerOpenPorts',
      consumerHint: 'Router/IoT analyzer: WAN mgmt / exposed ports',
    ),
    ToggleWiring(
      key: 'router_outdated_firmware',
      area: 'Router & IoT',
      settingGetter: 'SettingsService.routerOutdatedFirmware',
      consumerHint: 'Router/IoT analyzer: firmware age advisories',
    ),
    ToggleWiring(
      key: 'router_upnp',
      area: 'Router & IoT',
      settingGetter: 'SettingsService.routerUpnp',
      consumerHint: 'Router/IoT analyzer: UPnP exposure checks',
    ),
    ToggleWiring(
      key: 'router_wps',
      area: 'Router & IoT',
      settingGetter: 'SettingsService.routerWps',
      consumerHint: 'Router/IoT analyzer: WPS advisories',
    ),
    ToggleWiring(
      key: 'router_dns_hijack',
      area: 'Router & IoT',
      settingGetter: 'SettingsService.routerDnsHijack',
      consumerHint: 'Router/IoT analyzer: DNS server anomalies',
    ),
    ToggleWiring(
      key: 'iot_outdated_firmware',
      area: 'Router & IoT',
      settingGetter: 'SettingsService.iotOutdatedFirmware',
      consumerHint: 'IoT analyzer: device firmware advisories',
    ),

    // ------------------------------------------------------------
    // Alerts
    // ------------------------------------------------------------
    ToggleWiring(
      key: 'alerts_enabled',
      area: 'Alerts',
      settingGetter: 'SettingsService.alertsEnabled',
      consumerHint: 'AlertsEngine: emit alerts after scans',
    ),
    ToggleWiring(
      key: 'alert_high_risk_only',
      area: 'Alerts',
      settingGetter: 'SettingsService.alertHighRiskOnly',
      consumerHint: 'AlertsEngine: filters alerts',
    ),
    ToggleWiring(
      key: 'alert_open_port_spike',
      area: 'Alerts',
      settingGetter: 'SettingsService.alertOpenPortSpike',
      consumerHint: 'AlertsEngine: detects port spikes across snapshots',
    ),
    ToggleWiring(
      key: 'alert_new_device',
      area: 'Alerts',
      settingGetter: 'SettingsService.alertNewDevice',
      consumerHint: 'AlertsEngine: detects new hosts',
    ),
    ToggleWiring(
      key: 'alert_unknown_vendor',
      area: 'Alerts',
      settingGetter: 'SettingsService.alertUnknownVendor',
      consumerHint: 'AlertsEngine: flags unknown vendors',
    ),

    // ------------------------------------------------------------
    // App & privacy
    // ------------------------------------------------------------
    ToggleWiring(
      key: 'allow_metrics',
      area: 'App & privacy',
      settingGetter: 'SettingsService.allowMetrics',
      consumerHint: 'Telemetry pipeline: disabled when off',
    ),
    ToggleWiring(
      key: 'store_scan_history',
      area: 'App & privacy',
      settingGetter: 'SettingsService.storeScanHistory',
      consumerHint: 'ScanSnapshotStore: persistence disabled when off',
    ),
    ToggleWiring(
      key: 'auto_export_pdf',
      area: 'App & privacy',
      settingGetter: 'SettingsService.autoExportPdf',
      consumerHint: 'PDF exporter: automatic export after scan',
    ),

    // ------------------------------------------------------------
    // AI & labs
    // ------------------------------------------------------------
    // AI assistant toggles
    ToggleWiring(
      key: 'ai_assistant',
      area: 'AI & labs',
      settingGetter: 'SettingsService.aiAssistant',
      consumerHint: 'Insights layer: AI explanations gated here',
    ),
    ToggleWiring(
      key: 'ai_explain_vulns',
      area: 'AI & labs',
      settingGetter: 'SettingsService.aiExplainVulns',
      consumerHint: 'Insights layer: "what this means" cards',
    ),
    ToggleWiring(
      key: 'ai_one_click_fixes',
      area: 'AI & labs',
      settingGetter: 'SettingsService.aiOneClickFixes',
      consumerHint: 'Guided remediation UI (when supported)',
    ),
    ToggleWiring(
      key: 'ai_risk_scoring',
      area: 'AI & labs',
      settingGetter: 'SettingsService.aiRiskScoring',
      consumerHint: 'Risk scoring engine: enhanced weighting',
    ),
    ToggleWiring(
      key: 'ai_router_playbooks',
      area: 'AI & labs',
      settingGetter: 'SettingsService.aiRouterPlaybooks',
      consumerHint: 'Playbooks generator UI',
    ),
    ToggleWiring(
      key: 'ai_detect_unnecessary_services',
      area: 'AI & labs',
      settingGetter: 'SettingsService.aiDetectUnnecessaryServices',
      consumerHint: 'Analysis layer: risky service suggestions',
    ),
    ToggleWiring(
      key: 'ai_proactive_warnings',
      area: 'AI & labs',
      settingGetter: 'SettingsService.aiProactiveWarnings',
      consumerHint: 'Alerts/insights: pre-emptive warnings',
    ),

    // Labs: traffic & Wi-Fi
    ToggleWiring(
      key: 'lab_packet_sniffer_lite',
      area: 'AI & labs',
      settingGetter: 'SettingsService.packetSnifferLite',
      consumerHint: 'Labs module: metadata capture (where supported)',
    ),
    ToggleWiring(
      key: 'lab_wifi_deauth_detection',
      area: 'AI & labs',
      settingGetter: 'SettingsService.wifiDeauthDetection',
      consumerHint: 'Labs module: deauth detection (where supported)',
    ),
    ToggleWiring(
      key: 'lab_rogue_ap_detection',
      area: 'AI & labs',
      settingGetter: 'SettingsService.rogueApDetection',
      consumerHint: 'Labs module: rogue AP detection (where supported)',
    ),
    ToggleWiring(
      key: 'lab_hidden_ssid_detection',
      area: 'AI & labs',
      settingGetter: 'SettingsService.hiddenSsidDetection',
      consumerHint: 'Labs module: hidden SSID detection (where supported)',
    ),

    // Experimental ML
    ToggleWiring(
      key: 'ml_behaviour_threat_detection',
      area: 'AI & labs',
      settingGetter: 'SettingsService.behaviourThreatDetection',
      consumerHint: 'ML pipeline: behaviour heuristics (beta)',
    ),
    ToggleWiring(
      key: 'ml_local_profiling',
      area: 'AI & labs',
      settingGetter: 'SettingsService.localMlProfiling',
      consumerHint: 'ML pipeline: local profiling (beta)',
    ),
    ToggleWiring(
      key: 'ml_iot_fingerprinting',
      area: 'AI & labs',
      settingGetter: 'SettingsService.iotFingerprinting',
      consumerHint: 'ML pipeline: IoT fingerprinting (beta)',
    ),
  ];
}
'@

# 2) scan_screen.dart
$scanPath = Join-Path $ProjectRoot 'lib\features\scan\scan_screen.dart'
Backup-File $scanPath
Write-Utf8NoBom $scanPath @'
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:scanx_app/core/utils/text_sanitizer.dart';
import '../../core/services/pdf_report_service.dart';
import '../../core/services/report_builder.dart';
import 'package:printing/printing.dart';
import '../../core/services/scan_service.dart';
import '../../core/services/settings_service.dart';
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ScanService _scanService = ScanService();
  final SettingsService _settingsService = SettingsService();

  final TextEditingController _targetController = TextEditingController();

  bool _isScanning = false;
  String? _errorMessage;
  ScanResult? _lastResult;

  double _gaugeValue = 0.0; // 0.0 - 1.0
  Timer? _progressTimer;

  String _enabledLabsSummary() {
    final enabled = <String>[];

    // Labs: traffic & Wi‑Fi
    if (_settingsService.settings.packetSnifferLite) enabled.add('Sniffer');
    if (_settingsService.settings.wifiDeauthDetection) enabled.add('Deauth');
    if (_settingsService.settings.rogueApDetection) enabled.add('Rogue AP');
    if (_settingsService.settings.hiddenSsidDetection) enabled.add('Hidden SSID');

    // Experimental ML
    if (_settingsService.settings.behaviourThreatDetection) enabled.add('ML: Behaviour');
    if (_settingsService.settings.localMlProfiling) enabled.add('ML: Profiling');
    if (_settingsService.settings.iotFingerprinting) enabled.add('ML: IoT FP');

    if (enabled.isEmpty) return '';
    return 'Labs/ML: ${enabled.join(' · ')}';
  }

  @override
  void initState() {
    super.initState();

    final defaultTarget = _settingsService.settings.defaultTargetCidr;
    _targetController.text = defaultTarget;
    _lastResult = _scanService.lastResult;
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _targetController.dispose();
    super.dispose();
  }

  void _startFakeProgress() {
    _progressTimer?.cancel();
    setState(() {
      _gaugeValue = 0.0;
    });

    _progressTimer = Timer.periodic(const Duration(milliseconds: 250), (t) {
      if (!mounted) return;
      setState(() {
        _gaugeValue += 0.03;
        if (_gaugeValue > 0.9) _gaugeValue = 0.9;
      });
    });
  }

  void _stopProgress(double finalValue) {
    _progressTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _gaugeValue = finalValue.clamp(0.0, 1.0);
    });
  }

  Future<void> _runSmartScan() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _errorMessage = null;
    });

    _startFakeProgress();
    final target = _targetController.text.trim();

    try {
      final result = await _scanService.runSmartScan(target);

      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _lastResult = result;

      // Alerts pipeline (additive; does not change scan engine)
// Alerts pipeline (additive; does not change scan engine)
});

      _stopProgress(0.8);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Smart scan completed for $target')),
    );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _errorMessage = e.toString();
      });

      _stopProgress(0.0);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Smart scan failed: $e')),
    );
    }
  }

  Future<void> _runFullScan() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _errorMessage = null;
    });

    _startFakeProgress();
    final target = _targetController.text.trim();

    try {
      final result = await _scanService.runFullScan(target);

      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _lastResult = result;
      });

      _stopProgress(1.0);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Full scan completed for $target')),
    );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _errorMessage = e.toString();
      });

      _stopProgress(0.0);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Full scan failed: $e')),
    );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = _lastResult;
    final hosts = result?.hosts ?? [];

    final highRisk = hosts.where((h) => h.risk == RiskLevel.high).length;
    final mediumRisk = hosts.where((h) => h.risk == RiskLevel.medium).length;
    final lowRisk = hosts.where((h) => h.risk == RiskLevel.low).length;

    final allowSmart = _settingsService.quickScan;
    final allowFull = _settingsService.deepScan;
    final stealth = _settingsService.stealthScan;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Export Security Report (PDF)',
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              if (_lastResult == null) return;
              final reportJson = ReportBuilder().buildReportJson(
                result: _lastResult!,
                scanModeLabel: 'Scan',
              );
              final bytes = await PdfReportService().buildReport(reportJson: reportJson);
              await Printing.layoutPdf(onLayout: (_) async => bytes);
            },
          ),
        ],
        title: const Text('Scan'),
        centerTitle: true,
      ),
      // FIX: make screen scrollable so dynamic content never overflows after scans.
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 6,
                      child: SizedBox(
                        height: 220,
                        child: Column(
                          children: [
                            const SizedBox(height: 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32),
                                child: _ScanGauge(
                                  value: _gaugeValue,
                                  isActive: _isScanning,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            TextField(
                              controller: _targetController,
                              decoration: const InputDecoration(
                                labelText: 'Target (CIDR or host)',
                                hintText: 'e.g. 192.168.1.0/24',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: (_isScanning || !allowSmart) ? null : _runSmartScan,
                                    icon: _isScanning
                                        ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                        : const Icon(Icons.bolt),
                                    label: Text(
                                      _isScanning ? 'Scanning' : (allowSmart ? 'Smart Scan' : 'Smart Scan (disabled)'),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: (_isScanning || !allowFull) ? null : _runFullScan,
                                    icon: const Icon(Icons.all_inclusive),
                                    label: const Text('Full Scan'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  stealth ? Icons.visibility_off : Icons.visibility,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Builder(
                                    builder: (context) {
                                      final labs = _enabledLabsSummary();
                                      final suffix = labs.isNotEmpty ? '  |  $labs' : '';
                                      return Text(
                                        sanitizeUiText('Stealth scan: ${stealth ? 'ON (best-effort)' : 'OFF'} Full Scan: ${allowFull ? 'ON' : 'OFF'}$suffix'),
                                        style: theme.textTheme.bodySmall,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (result == null)
                      Expanded(
                        child: Center(
                          child: Text(
                            'No scans yet.\nRun a Smart or Full Scan to see devices.',
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Results summary',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _summaryChip(
                                label: 'Devices',
                                value: hosts.length.toString(),
                                color: Colors.blueAccent,
                              ),
                              _summaryChip(
                                label: 'High',
                                value: highRisk.toString(),
                                color: Colors.redAccent,
                              ),
                              _summaryChip(
                                label: 'Medium',
                                value: mediumRisk.toString(),
                                color: Colors.orangeAccent,
                              ),
                              _summaryChip(
                                label: 'Low',
                                value: lowRisk.toString(),
                                color: Colors.greenAccent,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                stealth ? Icons.visibility_off : Icons.visibility,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                      sanitizeUiText('Stealth scan: ${stealth ? 'ON (best-effort)' : 'OFF'} Full Scan: ${allowFull ? 'ON' : 'OFF'}'),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                  ],
                ),
              ),
            ),
    );
        },
      ),
    );
  }

  Widget _summaryChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color.withOpacity(0.15),
        child: Text(sanitizeUiText(value),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
      label: Text(sanitizeUiText(label)),
      backgroundColor: color.withOpacity(0.08),
    );
  }
}

// SCAN-O-METER GAUGE (top semicircle)
class _ScanGauge extends StatelessWidget {
  final double value; // 0.0ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦ÃƒÂ¢Ã¢â€šÂ¬Ã…â€œ1.0
  final bool isActive;

  const _ScanGauge({
    required this.value,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    // Key fix: force readable contrast on labels/ticks in dark theme.
    final labelColor =
    isDark ? Colors.white.withOpacity(0.78) : Colors.black.withOpacity(0.78);

    final minorTickColor =
    isDark ? Colors.white.withOpacity(0.42) : Colors.black.withOpacity(0.25);

    final majorTickColor =
    isDark ? Colors.white.withOpacity(0.62) : Colors.black.withOpacity(0.45);

    return LayoutBuilder(
      builder: (_, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _GaugePainter(
            value: value,
            isActive: isActive,
            labelColor: labelColor,
            minorTickColor: minorTickColor,
            majorTickColor: majorTickColor,
          ),
    );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value; // 0.0ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦ÃƒÂ¢Ã¢â€šÂ¬Ã…â€œ1.0
  final bool isActive;

  // Theme-safe colors (passed from widget, so we don't need BuildContext here)
  final Color labelColor;
  final Color minorTickColor;
  final Color majorTickColor;

  _GaugePainter({
    required this.value,
    required this.isActive,
    required this.labelColor,
    required this.minorTickColor,
    required this.majorTickColor,
  });

  double _degToRad(double deg) => deg * math.pi / 180.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.65);
    final radius = math.min(size.width, size.height) * 0.45;

    final startAngle = _degToRad(180);
    final sweepAngle = _degToRad(180);

    final basePaint = Paint()
      ..color = const Color(0xFF111827)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Colors.greenAccent,
          Colors.orangeAccent,
          Colors.redAccent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(rect, startAngle, sweepAngle, false, basePaint);

    final clampedValue = value.clamp(0.0, 1.0);
    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle * clampedValue,
      false,
      activePaint,
    );
    final tickPaint = Paint()
      ..color = minorTickColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final majorTickPaint = Paint()
      ..color = majorTickColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    const tickCount = 20;
    for (int i = 0; i <= tickCount; i++) {
      final t = i / tickCount;
      final angle = startAngle + sweepAngle * t;
      final isMajor = i % 5 == 0;

      final outerRadius = radius;
      final innerRadius = radius - (isMajor ? 18.0 : 10.0);

      final start = Offset(
        center.dx + outerRadius * math.cos(angle),
        center.dy + outerRadius * math.sin(angle),
    );
      final end = Offset(
        center.dx + innerRadius * math.cos(angle),
        center.dy + innerRadius * math.sin(angle),
    );
      canvas.drawLine(start, end, isMajor ? majorTickPaint : tickPaint);
    }

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    void drawLabel(double t, String label) {
      final angle = startAngle + sweepAngle * t;
      final labelRadius = radius + 20;

      final pos = Offset(
        center.dx + labelRadius * math.cos(angle),
        center.dy + labelRadius * math.sin(angle),
    );
      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(
          // Key fix: do NOT hardcode black labels on dark themes.
          color: labelColor,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
    );
      textPainter.layout();

      final offset = Offset(
        pos.dx - textPainter.width / 2,
        pos.dy - textPainter.height / 2,
    );
      textPainter.paint(canvas, offset);
    }

    drawLabel(0.0, '0');
    drawLabel(0.5, '50');
    drawLabel(1.0, '100');

    final needleAngle = startAngle + sweepAngle * clampedValue;
    final needleLength = radius * 0.9;

    final needlePaint = Paint()
      ..color = isActive ? Colors.greenAccent : Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final needleEnd = Offset(
      center.dx + needleLength * math.cos(needleAngle),
      center.dy + needleLength * math.sin(needleAngle),
    );
    canvas.drawLine(center, needleEnd, needlePaint);

    if (isActive) {
      final glowPaint = Paint()
        ..color = Colors.greenAccent.withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8;
      canvas.drawLine(center, needleEnd, glowPaint);
    }

    final knobPaint = Paint()
      ..color = const Color(0xFF111827)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 9, knobPaint);

    final knobBorder = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, 9, knobBorder);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.isActive != isActive ||
        oldDelegate.labelColor != labelColor ||
        oldDelegate.minorTickColor != minorTickColor ||
        oldDelegate.majorTickColor != majorTickColor;
  }
}
'@

Write-Host ''
Write-Host '=== PATCH APPLIED ==='
Write-Host 'Next run:'
Write-Host '  flutter clean'
Write-Host '  flutter pub get'
Write-Host '  flutter test'
Write-Host '  flutter run -d windows'
