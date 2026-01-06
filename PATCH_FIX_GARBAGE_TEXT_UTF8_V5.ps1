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
  throw "pubspec.yaml not found. Run from Flutter project root."
}

Write-Host "=== PATCH V5: Fix garbage UI text + force UTF-8 process output ==="
Write-Host "ProjectRoot: $ProjectRoot"

# ------------------------------------------------------------
# A) Ensure / upgrade sanitizer (safe, deterministic)
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

String repairMojibake(String input) {
  if (input.isEmpty) return input;
  if (!_looksMojibake(input)) return input;

  String s = input;

  // Try 2 rounds of latin1 -> utf8 repair (double-mojibake cases)
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

  // Still broken? Strip non-ASCII garbage to keep UI readable.
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
# B) Global mojibake normalization in Dart string literals
#    (Safe: only replaces known broken sequences)
# ------------------------------------------------------------
$libDir = Join-Path $ProjectRoot "lib"
$dartFiles = Get-ChildItem -LiteralPath $libDir -Recurse -Filter *.dart

[int]$normalized = 0

$replacements = @(
  # Most common CP1252/UTF-8 mojibake apostrophe patterns
  @{ from = "Ã¢â‚¬â„¢"; to = "'" },
  @{ from = "â€™";        to = "'" },
  @{ from = "Ã¢â‚¬Å“";    to = '"' },
  @{ from = "Ã¢â‚¬Â";    to = '"' },
  @{ from = "â€œ";        to = '"' },
  @{ from = "â€";        to = '"' },
  @{ from = "Ã¢â‚¬â€œ";    to = "-" },
  @{ from = "â€“";        to = "-" },
  @{ from = "Ã¢â‚¬Â¦";    to = "..." },
  @{ from = "â€¦";        to = "..." }
)

foreach ($f in $dartFiles) {
  $p = $f.FullName
  $src = Read-Raw $p
  if ($null -eq $src) { continue }
  $orig = $src

  foreach ($r in $replacements) {
    $src = $src.Replace($r.from, $r.to)
  }

  if ($src -ne $orig) {
    Backup-File $p
    Write-Utf8NoBom $p $src
    $normalized++
  }
}

Write-Host "Normalized mojibake sequences in files: $normalized"

# ------------------------------------------------------------
# C) Targeted UI fix: sanitize variable-based status lines
#    Only touches files that contain 'Stealth scan:' OR 'Scanning'
#    and ONLY wraps Text(variable) / SelectableText(variable).
# ------------------------------------------------------------
[int]$uiPatched = 0

foreach ($f in $dartFiles) {
  $p = $f.FullName
  $src = Read-Raw $p
  if ($null -eq $src) { continue }

  if (($src -notmatch "Stealth scan:") -and ($src -notmatch "(?i)\bScanning\b")) { continue }

  $orig = $src
  $needsImport = ($src -notmatch "core/utils/text_sanitizer\.dart")

  # Wrap Text(identifier) and SelectableText(identifier)
  # Safe: only matches a single identifier argument, not expressions.
  $src = [regex]::Replace(
    $src,
    "(?m)\bText\(\s*([A-Za-z_][A-Za-z0-9_]*)\s*\)",
    "Text(sanitizeUiText(`$1))"
  )
  $src = [regex]::Replace(
    $src,
    "(?m)\bText\(\s*([A-Za-z_][A-Za-z0-9_]*)\s*,",
    "Text(sanitizeUiText(`$1),"
  )

  $src = [regex]::Replace(
    $src,
    "(?m)\bSelectableText\(\s*([A-Za-z_][A-Za-z0-9_]*)\s*\)",
    "SelectableText(sanitizeUiText(`$1))"
  )
  $src = [regex]::Replace(
    $src,
    "(?m)\bSelectableText\(\s*([A-Za-z_][A-Za-z0-9_]*)\s*,",
    "SelectableText(sanitizeUiText(`$1),"
  )

  if ($src -ne $orig) {
    if ($needsImport) {
      if ($src -match "(?m)^import\s+'package:flutter/material\.dart';\s*$") {
        $src = $src -replace "(?m)^import\s+'package:flutter/material\.dart';\s*$",
          "import 'package:flutter/material.dart';`nimport 'package:scanx_app/core/utils/text_sanitizer.dart';"
      } else {
        $src = "import 'package:scanx_app/core/utils/text_sanitizer.dart';`n$src"
      }
    }

    Backup-File $p
    Write-Utf8NoBom $p $src
    $uiPatched++
    Write-Host "UI sanitize patched: $p"
  }
}

Write-Host "UI sanitize patched files: $uiPatched"

# ------------------------------------------------------------
# D) Force UTF-8 decoding for Process.run/start across lib/**/*.dart
#    (Stops garbage at the source)
# ------------------------------------------------------------
[int]$procPatched = 0

foreach ($f in $dartFiles) {
  $p = $f.FullName
  $src = Read-Raw $p
  if ($null -eq $src) { continue }
  $orig = $src

  # Patch Process.run(...) without stdoutEncoding
  $src = [regex]::Replace(
    $src,
    "Process\.run\(([\s\S]*?)\)",
    {
      param($m)
      $call = $m.Value
      if ($call -notmatch "Process\.run\(") { return $call }
      if ($call -match "stdoutEncoding\s*:") { return $call }
      # Add encodings just before the final ')'
      return ($call.TrimEnd(')') + ", stdoutEncoding: utf8, stderrEncoding: utf8)")
    }
  )

  # Patch Process.start(...) without stdoutEncoding
  $src = [regex]::Replace(
    $src,
    "Process\.start\(([\s\S]*?)\)",
    {
      param($m)
      $call = $m.Value
      if ($call -notmatch "Process\.start\(") { return $call }
      if ($call -match "stdoutEncoding\s*:") { return $call }
      return ($call.TrimEnd(')') + ", stdoutEncoding: utf8, stderrEncoding: utf8)")
    }
  )

  # If we inserted utf8 usage, ensure dart:convert import exists
  if (($src -ne $orig) -and ($src -match "\butf8\b") -and ($src -notmatch "(?m)^\s*import\s+'dart:convert';\s*$")) {
    if ($src -match "(?m)^import\s+") {
      $src = [regex]::Replace($src, "(?m)^import\s+", "import 'dart:convert';`n`nimport ", 1)
    } else {
      $src = "import 'dart:convert';`n`n$src"
    }
  }

  if ($src -ne $orig) {
    Backup-File $p
    Write-Utf8NoBom $p $src
    $procPatched++
  }
}

Write-Host "Process UTF-8 patched files: $procPatched"

Write-Host ""
Write-Host "=== PATCH V5 COMPLETE ==="
Write-Host "Now run:"
Write-Host "  flutter clean"
Write-Host "  flutter pub get"
Write-Host "  flutter test"
Write-Host "  flutter run -d windows"
