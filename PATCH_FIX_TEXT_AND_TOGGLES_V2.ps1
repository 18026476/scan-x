param()

$ErrorActionPreference = "Stop"

# Force .NET relative paths to resolve inside project root
$ProjectRoot = (Resolve-Path -LiteralPath ".").Path
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

function Ensure-Import([string]$content, [string]$importLine) {
  if ($content -match [regex]::Escape($importLine)) { return $content }
  if ($content -match "(?m)^import\s+'package:flutter/material\.dart';\s*$") {
    return ($content -replace "(?m)^import\s+'package:flutter/material\.dart';\s*$", "import 'package:flutter/material.dart';`n$importLine")
  }
  return "$importLine`n$content"
}

if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot "pubspec.yaml"))) {
  throw "Run from Flutter project root (pubspec.yaml missing). Current: $ProjectRoot"
}

Write-Host "=== PATCH V2: Fix mojibake + enforce no dead toggles + fix failing widget_test ==="
Write-Host "ProjectRoot: $ProjectRoot"

# ------------------------------------------------------------
# A) Mojibake sanitizer utility (absolute path)
# ------------------------------------------------------------
$sanAbs = Join-Path $ProjectRoot "lib\core\utils\text_sanitizer.dart"
Backup-File $sanAbs
Write-Utf8NoBom $sanAbs @"
import 'dart:convert';

/// Repairs common mojibake where UTF-8 bytes were decoded as latin1/cp1252.
/// If the string contains typical mojibake markers, it attempts to fix it.
/// Safe: if not mojibake, returns original.
String repairMojibake(String input) {
  if (input.isEmpty) return input;

  final looksBroken = input.contains('Ã') ||
      input.contains('Â') ||
      input.contains('â€™') ||
      input.contains('â€œ') ||
      input.contains('â€') ||
      input.contains('�');

  if (!looksBroken) return input;

  try {
    final bytes = latin1.encode(input);
    return utf8.decode(bytes, allowMalformed: true);
  } catch (_) {
    return input;
  }
}

String normalizePunctuation(String s) {
  return s
      .replaceAll('\u2018', "'")
      .replaceAll('\u2019', "'")
      .replaceAll('\u201C', '"')
      .replaceAll('\u201D', '"')
      .replaceAll('\u2013', '-')
      .replaceAll('\u2014', '-')
      .replaceAll('\u2026', '...')
      .replaceAll('\u00A0', ' ');
}

String sanitizeUiText(String s) => normalizePunctuation(repairMojibake(s));
"@

# ------------------------------------------------------------
# B) Patch Scan screen: sanitize the line that contains "Stealth scan:"
# ------------------------------------------------------------
$scanAbs = Join-Path $ProjectRoot "lib\features\scan\scan_screen.dart"
if (-not (Test-Path -LiteralPath $scanAbs)) { throw "Missing file: $scanAbs" }

Backup-File $scanAbs
$scan = Read-Raw $scanAbs
$scan = Ensure-Import $scan "import 'package:scanx_app/core/utils/text_sanitizer.dart';"

# Wrap ONLY if not already wrapped
if ($scan -notmatch "sanitizeUiText\(") {
  # Best-effort: wrap Text(...) content that contains "Stealth scan:"
  $scan2 = [regex]::Replace(
    $scan,
    "Text\(\s*([^\)]*Stealth scan:[^\)]*)\)",
    "Text(sanitizeUiText($1))",
    [System.Text.RegularExpressions.RegexOptions]::Singleline
  )

  if ($scan2 -ne $scan) {
    $scan = $scan2
    Write-Host "Patched Scan screen status Text(...) with sanitizeUiText(...)"
  } else {
    Write-Host "WARN: Could not auto-locate the exact Text(...) node for 'Stealth scan:'. Import was added; may need manual wrap."
  }
}

Write-Utf8NoBom $scanAbs $scan

# ------------------------------------------------------------
# C) Toggle wiring registry + test (absolute paths)
# ------------------------------------------------------------
$regAbs = Join-Path $ProjectRoot "lib\core\services\toggle_wiring_registry.dart"
Backup-File $regAbs
Write-Utf8NoBom $regAbs @"
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
  ];
}
"@

$testDirAbs = Join-Path $ProjectRoot "test"
Ensure-Dir $testDirAbs

$wiringTestAbs = Join-Path $testDirAbs "toggle_wiring_registry_test.dart"
Backup-File $wiringTestAbs
Write-Utf8NoBom $wiringTestAbs @"
import 'package:flutter_test/flutter_test.dart';
import 'package:scanx_app/core/services/toggle_wiring_registry.dart';

void main() {
  test('No dead toggles: every toggle has a consumer', () {
    final dead = ToggleWiringRegistry.toggles
        .where((t) => t.consumer == ToggleConsumer.none)
        .toList();
    expect(dead, isEmpty,
        reason: 'Dead toggles found: \${dead.map((e) => e.key).join(', ')}');
  });

  test('No duplicate toggle keys', () {
    final keys = ToggleWiringRegistry.toggles.map((t) => t.key).toList();
    expect(keys.toSet().length, keys.length,
        reason: 'Duplicate toggle keys found in registry.');
  });
}
"@

# ------------------------------------------------------------
# D) Fix failing widget_test.dart (SettingsService init)
# ------------------------------------------------------------
$widgetTestAbs = Join-Path $ProjectRoot "test\widget_test.dart"
if (Test-Path -LiteralPath $widgetTestAbs) {
  Backup-File $widgetTestAbs

  Write-Utf8NoBom $widgetTestAbs @"
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:scanx_app/main.dart';
import 'package:scanx_app/core/services/settings_service.dart';

void main() {
  testWidgets('SCAN-X app builds', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.init();

    await tester.pumpWidget(const ScanXApp());
    await tester.pumpAndSettle();

    expect(find.byType(ScanXApp), findsOneWidget);
  });
}
"@

  Write-Host "Patched test/widget_test.dart to init SettingsService before pumping."
} else {
  Write-Host "WARN: test/widget_test.dart not found; skipping."
}

Write-Host ""
Write-Host "=== PATCH V2 COMPLETE ==="
Write-Host "Next run:"
Write-Host "  flutter clean"
Write-Host "  flutter pub get"
Write-Host "  flutter test"
Write-Host "  flutter run -d windows"
