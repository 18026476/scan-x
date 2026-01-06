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
function Read-Raw([string]$path) { Get-Content -LiteralPath $path -Raw }
function Write-Utf8NoBom([string]$path, [string]$content) {
  $dir = Split-Path -Parent $path
  Ensure-Dir $dir
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
  Write-Host "Wrote: $path"
}

if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot "pubspec.yaml"))) {
  throw "pubspec.yaml not found. Run from project root."
}

Write-Host "=== PATCH V3: Strong mojibake fix + enforce no-dead-toggles ==="
Write-Host "ProjectRoot: $ProjectRoot"

# ------------------------------------------------------------
# 1) Upgrade sanitizer (stronger repair + fallback strip)
# ------------------------------------------------------------
$sanAbs = Join-Path $ProjectRoot "lib\core\utils\text_sanitizer.dart"
Backup-File $sanAbs
Write-Utf8NoBom $sanAbs @"
import 'dart:convert';

bool _looksMojibake(String s) {
  return s.contains('Ã') ||
      s.contains('Â') ||
      s.contains('â€™') ||
      s.contains('â€œ') ||
      s.contains('â€') ||
      s.contains('�');
}

/// Repairs common mojibake where UTF-8 bytes were decoded as latin1/cp1252.
/// Tries twice to handle double-encoding issues.
/// If it still looks broken, strips non-ASCII garbage as a final fallback.
String repairMojibake(String input) {
  if (input.isEmpty) return input;
  if (!_looksMojibake(input)) return input;

  String s = input;

  // Try 1–2 rounds of latin1->utf8 repair
  for (int i = 0; i < 2; i++) {
    try {
      final bytes = latin1.encode(s);
      final repaired = utf8.decode(bytes, allowMalformed: true);
      if (repaired == s) break;
      s = repaired;
      if (!_looksMojibake(s)) break;
    } catch (_) {
      break;
    }
  }

  // If still broken, remove non-ASCII characters (keeps readable English/UI)
  if (_looksMojibake(s)) {
    s = s.replaceAll(RegExp(r'[^\x20-\x7E]+'), ' ');
    s = s.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  }

  return s;
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
# 2) Apply sanitizeUiText to ALL literal Text() nodes containing "Stealth scan:"
#    across lib/**/*.dart, safely (only string literals)
# ------------------------------------------------------------
$libDir = Join-Path $ProjectRoot "lib"
$dartFiles = Get-ChildItem -LiteralPath $libDir -Recurse -Filter *.dart

[int]$changed = 0

foreach ($f in $dartFiles) {
  $path = $f.FullName
  $src = Read-Raw $path
  if ($null -eq $src) { continue }
  $orig = $src

  # Only touch files that contain the phrase
  if ($src -notmatch "Stealth scan:") { continue }

  # Ensure import exists if we modify the file
  $needsImport = ($src -notmatch "core/utils/text_sanitizer\.dart")

  # Wrap Text('...Stealth scan:...') => Text(sanitizeUiText('...Stealth scan:...'))
  # Safe: only matches a single-quoted literal argument.
  $src = [regex]::Replace(
    $src,
    "Text\(\s*'([^']*Stealth scan:[^']*)'\s*\)",
    "Text(sanitizeUiText('$1'))",
    [System.Text.RegularExpressions.RegexOptions]::Singleline
  )

  # Also handle double-quoted literals: Text("...Stealth scan:...")
  $src = [regex]::Replace(
    $src,
    "Text\(\s*""([^""]*Stealth scan:[^""]*)""\s*\)",
    "Text(sanitizeUiText(""$1""))",
    [System.Text.RegularExpressions.RegexOptions]::Singleline
  )

  if ($src -ne $orig) {
    if ($needsImport) {
      # Insert after flutter/material import if present, else prepend
      if ($src -match "(?m)^import\s+'package:flutter/material\.dart';\s*$") {
        $src = $src -replace "(?m)^import\s+'package:flutter/material\.dart';\s*$",
          "import 'package:flutter/material.dart';`nimport 'package:scanx_app/core/utils/text_sanitizer.dart';"
      } else {
        $src = "import 'package:scanx_app/core/utils/text_sanitizer.dart';`n$src"
      }
    }

    Backup-File $path
    Write-Utf8NoBom $path $src
    $changed++
  }
}

Write-Host "Sanitized Text() literals updated in files: $changed"

# ------------------------------------------------------------
# 3) Fix toggle wiring test file quoting (guarantee flutter test compiles)
# ------------------------------------------------------------
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
Write-Host "=== PATCH V3 COMPLETE ==="
Write-Host "Now run:"
Write-Host "  flutter clean"
Write-Host "  flutter pub get"
Write-Host "  flutter test"
Write-Host "  flutter run -d windows"
