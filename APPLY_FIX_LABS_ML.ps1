\
param(
  [Parameter(Mandatory=$false)]
  [string]$ProjectRoot = (Resolve-Path -LiteralPath ".").Path
)

$ErrorActionPreference = "Stop"
[System.IO.Directory]::SetCurrentDirectory($ProjectRoot)

function Timestamp() { Get-Date -Format "yyyyMMdd_HHmmss" }

function Ensure-Dir([string]$dir) {
  if ([string]::IsNullOrWhiteSpace($dir)) { return }
  if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
}

function Backup-File([string]$path) {
  if (Test-Path -LiteralPath $path) {
    $bak = "$path.bak_$(Timestamp)"
    Copy-Item -LiteralPath $path -Destination $bak -Force
    Write-Host "Backup: $bak"
  }
}

function Write-Utf8NoBom([string]$path, [string]$content) {
  $dir = Split-Path -Parent $path
  Ensure-Dir $dir
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
  Write-Host "Wrote: $path"
}

Write-Host "=== APPLY FIX: Restore ToggleWiringRegistry + Fix Scan screen Labs/ML integration ==="
Write-Host "ProjectRoot: $ProjectRoot"

if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot "pubspec.yaml"))) {
  throw "pubspec.yaml not found. Run this from Flutter project root. Current: $ProjectRoot"
}

# 1) Restore toggle_wiring_registry.dart (keeps ToggleConsumer + consumer field, plus labs/ml/ai toggles)
$toggleAbs = Join-Path $ProjectRoot "lib\core\services\toggle_wiring_registry.dart"
Backup-File $toggleAbs
Write-Utf8NoBom $toggleAbs @'
enum ToggleConsumer {
  scanEngine,
  routerIotAnalyzer,
  alertsEngine,
  notifier,
  reportingPdf,
  none,
}

class ToggleWiring {
  final String key;
  final ToggleConsumer consumer;
  final String notes;
  const ToggleWiring(this.key, this.consumer, this.notes);
}

class ToggleWiringRegistry {
  static const toggles = <ToggleWiring>[
    // Scan & detection
    ToggleWiring('stealthScan', ToggleConsumer.scanEngine, 'Used to build scan profile/args.'),
    ToggleWiring('fullScanEnabled', ToggleConsumer.scanEngine, 'Controls full scan mode.'),
    ToggleWiring('smartScanEnabled', ToggleConsumer.scanEngine, 'Controls smart scan mode.'),

    // Router checks
    ToggleWiring('routerWeakPassword', ToggleConsumer.routerIotAnalyzer, 'Router/IoT advisory.'),
    ToggleWiring('routerOpenPorts', ToggleConsumer.routerIotAnalyzer, 'Router/IoT advisory.'),
    ToggleWiring('routerOutdatedFirmware', ToggleConsumer.routerIotAnalyzer, 'Router advisory.'),
    ToggleWiring('routerUpnpCheck', ToggleConsumer.routerIotAnalyzer, 'UPnP advisory.'),
    ToggleWiring('routerWpsCheck', ToggleConsumer.routerIotAnalyzer, 'WPS advisory.'),
    ToggleWiring('routerDnsHijack', ToggleConsumer.routerIotAnalyzer, 'DNS advisory.'),

    // IoT checks
    ToggleWiring('iotOutdatedFirmware', ToggleConsumer.routerIotAnalyzer, 'IoT advisory.'),
    ToggleWiring('iotDefaultPasswords', ToggleConsumer.routerIotAnalyzer, 'IoT advisory.'),
    ToggleWiring('iotVulnDbMatch', ToggleConsumer.routerIotAnalyzer, 'CVE matching (if enabled).'),
    ToggleWiring('iotAutoRecommendations', ToggleConsumer.routerIotAnalyzer, 'Recommendation surfacing.'),

    // Alerts - detection rules
    ToggleWiring('alertNewDevice', ToggleConsumer.alertsEngine, 'AlertRulesEngine'),
    ToggleWiring('alertMacChange', ToggleConsumer.alertsEngine, 'AlertRulesEngine'),
    ToggleWiring('alertArpSpoof', ToggleConsumer.alertsEngine, 'AlertRulesEngine'),
    ToggleWiring('alertPortScanAttempts', ToggleConsumer.alertsEngine, 'AlertRulesEngine'),

    // Alerts - notifications
    ToggleWiring('notifyNewDevice', ToggleConsumer.notifier, 'InAppNotifier gating'),
    ToggleWiring('notifyUnknownDevice', ToggleConsumer.notifier, 'InAppNotifier gating'),
    ToggleWiring('notifyRouterVulnerability', ToggleConsumer.notifier, 'InAppNotifier gating'),
    ToggleWiring('notifyIotWarning', ToggleConsumer.notifier, 'InAppNotifier gating'),
    ToggleWiring('notifyHighRisk', ToggleConsumer.alertsEngine, 'AlertRulesEngine'),
    ToggleWiring('notifyScanCompleted', ToggleConsumer.alertsEngine, 'AlertRulesEngine'),
    ToggleWiring('notifyAutoScanResults', ToggleConsumer.notifier, 'InAppNotifier gating'),

    // Alert style
    ToggleWiring('alertSoundEnabled', ToggleConsumer.notifier, 'InAppNotifier'),
    ToggleWiring('alertVibrationEnabled', ToggleConsumer.notifier, 'InAppNotifier'),
    ToggleWiring('alertSilentMode', ToggleConsumer.notifier, 'InAppNotifier'),
    ToggleWiring('alertSensitivity', ToggleConsumer.alertsEngine, 'AlertRulesEngine'),

    // Reporting
    ToggleWiring('exportPdfEnabled', ToggleConsumer.reportingPdf, 'PDF export button'),

    // Labs: traffic & Wi‑Fi
    ToggleWiring('betaPacketSnifferLite', ToggleConsumer.settingsUi, 'Settings → AI & labs'),
    ToggleWiring('betaWifiDeauthDetection', ToggleConsumer.settingsUi, 'Settings → AI & labs'),
    ToggleWiring('betaRogueApDetection', ToggleConsumer.settingsUi, 'Settings → AI & labs'),
    ToggleWiring('betaHiddenSsidDetection', ToggleConsumer.settingsUi, 'Settings → AI & labs'),

    // Experimental ML features
    ToggleWiring('betaBehaviourThreatDetection', ToggleConsumer.settingsUi, 'Settings → AI & labs'),
    ToggleWiring('betaLocalMlProfiling', ToggleConsumer.settingsUi, 'Settings → AI & labs'),
    ToggleWiring('betaIotFingerprinting', ToggleConsumer.settingsUi, 'Settings → AI & labs'),

    // AI assistant
    ToggleWiring('aiAssistant', ToggleConsumer.aiAssistant, 'Settings → AI assistant'),
    ToggleWiring('explainVulns', ToggleConsumer.aiAssistant, 'Settings → AI assistant'),
    ToggleWiring('oneClickFixes', ToggleConsumer.aiAssistant, 'Settings → AI assistant'),
    ToggleWiring('aiRiskScoring', ToggleConsumer.aiAssistant, 'Settings → AI assistant'),
    ToggleWiring('routerHardeningPlaybooks', ToggleConsumer.aiAssistant, 'Settings → AI assistant'),
    ToggleWiring('detectUnnecessaryServices', ToggleConsumer.aiAssistant, 'Settings → AI assistant'),
    ToggleWiring('proactiveWarnings', ToggleConsumer.aiAssistant, 'Settings → AI assistant'),
  ];
}
'@

# 2) Fix scan_screen.dart to read labs/ml flags from SettingsService getters (NOT ScanSettings)
$scanAbs = Join-Path $ProjectRoot "lib\features\scan\scan_screen.dart"
Backup-File $scanAbs
Write-Utf8NoBom $scanAbs @'
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

  double _gaugeValue = 0.0; // 0.0 ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦ÃƒÂ¢Ã¢â€šÂ¬Ã…â€œ 1.0
  Timer? _progressTimer;

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

Builder(
  builder: (_) {
    final enabled = _enabledLabsMl();
    final text = enabled.isEmpty
        ? 'Labs/ML: none enabled'
        : 'Labs/ML enabled: ${enabled.join(' • ')}';
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: Colors.white70),
      ),
    );
  },
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
                                  child: Text(
                                  sanitizeUiText('Stealth scan: ${stealth ? 'ON (best-effort)' : 'OFF'}  Full Scan: ${allowFull ? 'ON' : 'OFF'}'),
                                    style: theme.textTheme.bodySmall,
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
                                  sanitizeUiText('Stealth scan: ${stealth ? 'ON (best-effort)' : 'OFF'}  Full Scan: ${allowFull ? 'ON' : 'OFF'}'),
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

Write-Host ""
Write-Host "=== PATCH APPLIED ==="
Write-Host "Next run:"
Write-Host "  flutter clean"
Write-Host "  flutter pub get"
Write-Host "  flutter test"
Write-Host "  flutter run -d windows"
