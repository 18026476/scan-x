param(
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
function Read-Raw([string]$path) { Get-Content -LiteralPath $path -Raw }
function Write-Utf8NoBom([string]$path, [string]$content) {
  $dir = Split-Path -Parent $path
  Ensure-Dir $dir
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
  Write-Host "Wrote: $path"
}

if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot "pubspec.yaml"))) {
  throw "pubspec.yaml not found. Run from Flutter project root. Current: $ProjectRoot"
}

Write-Host "=== APPLY PATCH V2: Fix ToggleWiringRegistry + Fix Scan Labs/ML summary compilation ==="
Write-Host "ProjectRoot: $ProjectRoot"

# 1) Overwrite toggle_wiring_registry.dart with known-good version
$reg = Join-Path $ProjectRoot "lib\core\services\toggle_wiring_registry.dart"
Backup-File $reg
Write-Utf8NoBom $reg @"
/// Auto-generated toggle wiring registry.
/// Used by tests to ensure no duplicate keys and no dead toggles.
///
/// NOTE: A toggle being present here only means it is wired to Settings persistence.
/// It does NOT guarantee the underlying feature implementation is production-grade.
enum ToggleConsumer {
  scanEngine,
  routerIotAnalyzer,
  alertsEngine,
  notifier,
  reportingPdf,
  aiAssistant,
  none,
}
class ToggleWiring {
  final String key;
  final ToggleConsumer consumer;
  final String whereUsed;

  const ToggleWiring(this.key, this.consumer, this.whereUsed);
}
class ToggleWiringRegistry {
  static const toggles = <ToggleWiring>[
    ToggleWiring('aiAssistantEnabled', ToggleConsumer.aiAssistant, 'Settings -> AI assistant'),
    ToggleWiring('aiDetectUnnecessaryServices', ToggleConsumer.aiAssistant, 'Settings -> AI assistant'),
    ToggleWiring('aiExplainVuln', ToggleConsumer.aiAssistant, 'Settings -> AI assistant'),
    ToggleWiring('aiOneClickFix', ToggleConsumer.aiAssistant, 'Settings -> AI assistant'),
    ToggleWiring('aiProactiveWarnings', ToggleConsumer.aiAssistant, 'Settings -> AI assistant'),
    ToggleWiring('aiRiskScoring', ToggleConsumer.aiAssistant, 'Settings -> AI assistant'),
    ToggleWiring('aiRouterHardening', ToggleConsumer.aiAssistant, 'Settings -> AI assistant'),
    ToggleWiring('alertArpSpoof', ToggleConsumer.alertsEngine, 'Alerts engine'),
    ToggleWiring('alertMacChange', ToggleConsumer.alertsEngine, 'Alerts engine'),
    ToggleWiring('alertNewDevice', ToggleConsumer.alertsEngine, 'Alerts engine'),
    ToggleWiring('alertPortScanAttempts', ToggleConsumer.alertsEngine, 'Alerts engine'),
    ToggleWiring('alertSilentMode', ToggleConsumer.alertsEngine, 'Alerts engine'),
    ToggleWiring('alertSoundEnabled', ToggleConsumer.alertsEngine, 'Alerts engine'),
    ToggleWiring('alertVibrationEnabled', ToggleConsumer.alertsEngine, 'Alerts engine'),
    ToggleWiring('anonymousUsageAnalytics', ToggleConsumer.scanEngine, 'Settings'),
    ToggleWiring('autoClearScan', ToggleConsumer.scanEngine, 'Settings'),
    ToggleWiring('autoDetectLocalNetwork', ToggleConsumer.scanEngine, 'Settings'),
    ToggleWiring('autoScanOnLaunch', ToggleConsumer.scanEngine, 'Settings'),
    ToggleWiring('autoStartOnBoot', ToggleConsumer.scanEngine, 'Settings'),
    ToggleWiring('autoUpdateApp', ToggleConsumer.scanEngine, 'Settings'),
    ToggleWiring('betaBehaviourThreatDetection', ToggleConsumer.aiAssistant, 'Settings -> AI & labs'),
    ToggleWiring('betaIotFingerprinting', ToggleConsumer.aiAssistant, 'Settings -> AI & labs'),
    ToggleWiring('betaLocalMlProfiling', ToggleConsumer.aiAssistant, 'Settings -> AI & labs'),
    ToggleWiring('betaUpdates', ToggleConsumer.aiAssistant, 'Settings -> AI & labs'),
    ToggleWiring('continuousMonitoring', ToggleConsumer.scanEngine, 'Settings'),
    ToggleWiring('deepScan', ToggleConsumer.scanEngine, 'Settings'),
    ToggleWiring('excludeTrustedDevices', ToggleConsumer.scanEngine, 'Settings'),
    ToggleWiring('filterOnlyNewDevices', ToggleConsumer.scanEngine, 'Settings'),
    ToggleWiring('filterOnlyVulnerable', ToggleConsumer.scanEngine, 'Settings'),
    ToggleWiring('filterRouterIoTOnly', ToggleConsumer.scanEngine, 'Settings'),
    ToggleWiring('hiddenSsidDetection', ToggleConsumer.scanEngine, 'Settings'),
    ToggleWiring('iotAutoRecommendations', ToggleConsumer.routerIotAnalyzer, 'Settings -> Router/IoT security'),
    ToggleWiring('iotDefaultPasswords', ToggleConsumer.routerIotAnalyzer, 'Settings -> Router/IoT security'),
    ToggleWiring('iotOutdatedFirmware', ToggleConsumer.routerIotAnalyzer, 'Settings -> Router/IoT security'),
    ToggleWiring('iotVulnDbMatch', ToggleConsumer.routerIotAnalyzer, 'Settings -> Router/IoT security'),
    ToggleWiring('keepScreenAwake', ToggleConsumer.scanEngine, 'Settings'),
    ToggleWiring('manualIpRange', ToggleConsumer.scanEngine, 'Settings'),
    ToggleWiring('notifyAutoScanResults', ToggleConsumer.notifier, 'Settings'),
    ToggleWiring('notifyBeforeUpdate', ToggleConsumer.notifier, 'Settings'),
    ToggleWiring('notifyHighRisk', ToggleConsumer.notifier, 'Settings'),
    ToggleWiring('notifyIotWarning', ToggleConsumer.notifier, 'Settings'),
    ToggleWiring('notifyNewDevice', ToggleConsumer.notifier, 'Settings'),
    ToggleWiring('notifyRouterVuln', ToggleConsumer.notifier, 'Settings'),
    ToggleWiring('notifyScanCompleted', ToggleConsumer.notifier, 'Settings'),
    ToggleWiring('notifyUnknownDevice', ToggleConsumer.notifier, 'Settings'),
    ToggleWiring('packetSnifferLite', ToggleConsumer.scanEngine, 'Settings'),
    ToggleWiring('quickScan', ToggleConsumer.scanEngine, 'Settings'),
    ToggleWiring('rogueApDetection', ToggleConsumer.scanEngine, 'Settings'),
    ToggleWiring('routerDnsHijack', ToggleConsumer.routerIotAnalyzer, 'Settings -> Router/IoT security'),
    ToggleWiring('routerOpenPorts', ToggleConsumer.routerIotAnalyzer, 'Settings -> Router/IoT security'),
    ToggleWiring('routerOutdatedFirmware', ToggleConsumer.routerIotAnalyzer, 'Settings -> Router/IoT security'),
    ToggleWiring('routerUpnpCheck', ToggleConsumer.routerIotAnalyzer, 'Settings -> Router/IoT security'),
    ToggleWiring('routerWeakPassword', ToggleConsumer.routerIotAnalyzer, 'Settings -> Router/IoT security'),
    ToggleWiring('routerWpsCheck', ToggleConsumer.routerIotAnalyzer, 'Settings -> Router/IoT security'),
    ToggleWiring('stealthScan', ToggleConsumer.scanEngine, 'Settings'),
    ToggleWiring('twoFactorEnabled', ToggleConsumer.scanEngine, 'Settings'),
    ToggleWiring('wifiDeauthDetection', ToggleConsumer.scanEngine, 'Settings'),
  ];
}

"@

# 2) Patch scan_screen.dart to:
#    - remove incorrect .settings. access
#    - ensure _enabledLabsMl() helper exists if Scan screen uses it
$scan = Join-Path $ProjectRoot "lib\features\scan\scan_screen.dart"
if (-not (Test-Path -LiteralPath $scan)) {
  Write-Host "WARN: scan_screen.dart not found at expected path: $scan"
} else {
  $src = Read-Raw $scan
  $orig = $src

  # fix incorrect access pattern introduced by earlier patch
  $src = $src -replace "_settingsService\.settings\.", "_settingsService."

  # If the file references _enabledLabsMl() but method doesn't exist, inject method right after the SettingsService field.
  if (($src -match "_enabledLabsMl\(") -and ($src -notmatch "List<String>\s+_enabledLabsMl\s*\(")) {
    $method = @"
  List<String> _enabledLabsMl() {
    final enabled = <String>[];

    // WiFi / traffic (beta labs)
    if (_settingsService.packetSnifferLite) enabled.add('Sniffer');
    if (_settingsService.wifiDeauthDetection) enabled.add('Deauth');
    if (_settingsService.rogueApDetection) enabled.add('Rogue AP');
    if (_settingsService.hiddenSsidDetection) enabled.add('Hidden SSID');

    if (_settingsService.betaBehaviourThreatDetection) enabled.add('ML: Behaviour');
    if (_settingsService.betaLocalMlProfiling) enabled.add('ML: Profiling');
    if (_settingsService.betaIotFingerprinting) enabled.add('ML: IoT FP');

    // AI assistant toggles (UI wiring)
    if (_settingsService.aiAssistantEnabled) enabled.add('AI Assistant');
    if (_settingsService.aiExplainVuln) enabled.add('Explain Vulns');
    if (_settingsService.aiOneClickFix) enabled.add('One-Click Fix');
    if (_settingsService.aiRiskScoring) enabled.add('AI Risk');
    if (_settingsService.aiRouterHardening) enabled.add('Router Playbooks');
    if (_settingsService.aiDetectUnnecessaryServices) enabled.add('Detect Services');
    if (_settingsService.aiProactiveWarnings) enabled.add('Proactive Warnings');

    return enabled;
  }

"@

    # Insert after the first SettingsService field line
    $src = [regex]::Replace(
      $src,
      "(?m)^\s*final\s+SettingsService\s+_settingsService\s*=\s*SettingsService\(\);\s*$",
      "`$0`n`n$method",
      1
    )
  }

  if ($src -ne $orig) {
    Backup-File $scan
    Write-Utf8NoBom $scan $src
  } else {
    Write-Host "INFO: scan_screen.dart not modified (nothing to patch)."
  }
}

Write-Host ""
Write-Host "=== PATCH V2 APPLIED ==="
Write-Host "Now run:"
Write-Host "  flutter clean"
Write-Host "  flutter pub get"
Write-Host "  flutter test"
Write-Host "  flutter run -d windows"
