param()

$ErrorActionPreference = "Stop"
$ProjectRoot = (Resolve-Path -LiteralPath ".").Path
[System.IO.Directory]::SetCurrentDirectory($ProjectRoot)

function Timestamp() { Get-Date -Format "yyyyMMdd_HHmmss" }
function Ensure-Dir([string]$dir) { if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null } }
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
function Read-Raw([string]$path) { Get-Content -LiteralPath $path -Raw }

Write-Host "=== RECOVERY PATCH: restore Scan screen + fix tests + safe mojibake wrap ==="
Write-Host "ProjectRoot: $ProjectRoot"

# 1) Restore scan_screen.dart from the exact backup created earlier
$scan = Join-Path $ProjectRoot "lib\features\scan\scan_screen.dart"
$bak  = Join-Path $ProjectRoot "lib\features\scan\scan_screen.dart.bak_20260106_204304"

if (-not (Test-Path -LiteralPath $bak)) {
  # If timestamp differs, auto-pick latest backup
  $dir = Split-Path -Parent $scan
  $candidates = Get-ChildItem -LiteralPath $dir -Filter "scan_screen.dart.bak_*" | Sort-Object Name -Descending
  if ($candidates.Count -eq 0) { throw "No scan_screen.dart backup found. Cannot recover safely." }
  $bak = $candidates[0].FullName
  Write-Host "INFO: Using latest backup: $bak"
}

Backup-File $scan
Copy-Item -LiteralPath $bak -Destination $scan -Force
Write-Host "Restored scan_screen.dart from: $bak"

# 2) Ensure sanitizer utility exists (safe)
$san = Join-Path $ProjectRoot "lib\core\utils\text_sanitizer.dart"
Ensure-Dir (Split-Path -Parent $san)
if (-not (Test-Path -LiteralPath $san)) {
  Write-Utf8NoBom $san @"
import 'dart:convert';

String repairMojibake(String input) {
  if (input.isEmpty) return input;
  final looksBroken = input.contains('Ã') || input.contains('Â') || input.contains('â€™') || input.contains('â€œ') || input.contains('â€') || input.contains('�');
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
}

# 3) Apply a SAFE scan_screen patch:
#    - add import (idempotent)
#    - only wrap Text('Stealth scan: ... Full Scan: ...') IF it is a literal Text('...') line
#    - NO broad regex across widgets
Backup-File $scan
$c = Read-Raw $scan

if ($c -notmatch "core/utils/text_sanitizer.dart") {
  # Insert after flutter/material import when possible
  if ($c -match "(?m)^import\s+'package:flutter/material\.dart';\s*$") {
    $c = $c -replace "(?m)^import\s+'package:flutter/material\.dart';\s*$", "import 'package:flutter/material.dart';`nimport 'package:scanx_app/core/utils/text_sanitizer.dart';"
  } else {
    $c = "import 'package:scanx_app/core/utils/text_sanitizer.dart';`n$c"
  }
}

# Wrap ONLY this pattern: Text('Stealth scan: .... Full Scan: ....')
# This avoids breaking any widget trees.
$c2 = [regex]::Replace(
  $c,
  "Text\(\s*'([^']*Stealth scan:[^']*Full Scan:[^']*)'\s*\)",
  "Text(sanitizeUiText('$1'))",
  [System.Text.RegularExpressions.RegexOptions]::Singleline
)

if ($c2 -ne $c) {
  $c = $c2
  Write-Host "Applied safe sanitizeUiText wrap to Stealth/Full scan status label."
} else {
  Write-Host "WARN: Could not find literal Text('Stealth scan: ... Full Scan: ...') in scan_screen.dart. No changes made to label."
}

Write-Utf8NoBom $scan $c

# 4) Fix toggle_wiring_registry_test.dart (your error was broken quotes)
$tw = Join-Path $ProjectRoot "test\toggle_wiring_registry_test.dart"
Ensure-Dir (Split-Path -Parent $tw)
Backup-File $tw

Write-Utf8NoBom $tw @"
import 'package:flutter_test/flutter_test.dart';
import 'package:scanx_app/core/services/toggle_wiring_registry.dart';

void main() {
  test('No dead toggles: every toggle has a consumer', () {
    final dead = ToggleWiringRegistry.toggles
        .where((t) => t.consumer == ToggleConsumer.none)
        .toList();

    expect(
      dead,
      isEmpty,
      reason: "Dead toggles found: \${dead.map((e) => e.key).join(', ')}",
    );
  });

  test('No duplicate toggle keys', () {
    final keys = ToggleWiringRegistry.toggles.map((t) => t.key).toList();
    expect(
      keys.toSet().length,
      keys.length,
      reason: 'Duplicate toggle keys found in registry.',
    );
  });
}
"@

Write-Host ""
Write-Host "=== RECOVERY PATCH COMPLETE ==="
Write-Host "Now run:"
Write-Host "  flutter clean"
Write-Host "  flutter pub get"
Write-Host "  flutter test"
Write-Host "  flutter run -d windows"
