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

Write-Host "=== PATCH V5.1: Fix garbage UI text + force UTF-8 process output (ASCII-safe) ==="
Write-Host "ProjectRoot: $ProjectRoot"

# ------------------------------------------------------------
# A) Ensure sanitizer exists (ASCII-only file content)
# ------------------------------------------------------------
$sanAbs = Join-Path $ProjectRoot "lib\core\utils\text_sanitizer.dart"
Backup-File $sanAbs
Write-Utf8NoBom $sanAbs @"
import 'dart:convert';

bool _looksBroken(String s) {
  return s.contains('Ã') || s.contains('Â') || s.contains('â€') || s.contains('�');
}

/// Attempts to repair common UTF-8-as-latin1 mojibake.
/// If still broken, strips non-ASCII to keep UI readable.
String repairMojibake(String input) {
  if (input.isEmpty) return input;
  if (!_looksBroken(input)) return input;

  String s = input;

  // Try 2 rounds of latin1 -> utf8 repair
  for (int i = 0; i < 2; i++) {
    try {
      final bytes = latin1.encode(s);
      final repaired = utf8.decode(bytes, allowMalformed: true);
      if (repaired == s) break;
      s = repaired;
      if (!_looksBroken(s)) break;
    } catch (_) {
      break;
    }
  }

  // Still broken? remove non-ASCII garbage
  if (_looksBroken(s)) {
    s = s.replaceAll(RegExp(r'[^\x20-\x7E]+'), ' ');
    s = s.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  }

  return s;
}

String sanitizeUiText(String s) => repairMojibake(s);
"@

# ------------------------------------------------------------
# B) Targeted UI patch:
#    - only files containing "Stealth scan:" or "Scanning"
#    - only wraps Text(identifier) / SelectableText(identifier)
# ------------------------------------------------------------
$libDir = Join-Path $ProjectRoot "lib"
$dartFiles = Get-ChildItem -LiteralPath $libDir -Recurse -Filter *.dart

[int]$uiPatched = 0

foreach ($f in $dartFiles) {
  $p = $f.FullName
  $src = Read-Raw $p
  if ($null -eq $src) { continue }

  if (($src -notmatch "Stealth scan:") -and ($src -notmatch "(?i)\bScanning\b")) { continue }

  $orig = $src
  $needsImport = ($src -notmatch "core/utils/text_sanitizer\.dart")

  # Wrap Text(varName)
  $src = [regex]::Replace(
    $src,
    'Text\(\s*([A-Za-z_][A-Za-z0-9_]*)\s*\)',
    'Text(sanitizeUiText($1))'
  )
  # Wrap Text(varName, ...)
  $src = [regex]::Replace(
    $src,
    'Text\(\s*([A-Za-z_][A-Za-z0-9_]*)\s*,',
    'Text(sanitizeUiText($1),'
  )

  # Wrap SelectableText(varName)
  $src = [regex]::Replace(
    $src,
    'SelectableText\(\s*([A-Za-z_][A-Za-z0-9_]*)\s*\)',
    'SelectableText(sanitizeUiText($1))'
  )
  # Wrap SelectableText(varName, ...)
  $src = [regex]::Replace(
    $src,
    'SelectableText\(\s*([A-Za-z_][A-Za-z0-9_]*)\s*,',
    'SelectableText(sanitizeUiText($1),'
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
# C) Force UTF-8 decoding for Process.run/start across lib/**/*.dart
#    (stops garbage at the source)
# ------------------------------------------------------------
[int]$procPatched = 0

foreach ($f in $dartFiles) {
  $p = $f.FullName
  $src = Read-Raw $p
  if ($null -eq $src) { continue }
  $orig = $src

  # Patch Process.run( ... ) if it doesn't already have stdoutEncoding:
  $src = [regex]::Replace(
    $src,
    'Process\.run\(([\s\S]*?)\)',
    {
      param($m)
      $call = $m.Value
      if ($call -match 'stdoutEncoding\s*:') { return $call }
      return ($call.TrimEnd(')') + ', stdoutEncoding: utf8, stderrEncoding: utf8)')
    }
  )

  # Patch Process.start( ... ) if it doesn't already have stdoutEncoding:
  $src = [regex]::Replace(
    $src,
    'Process\.start\(([\s\S]*?)\)',
    {
      param($m)
      $call = $m.Value
      if ($call -match 'stdoutEncoding\s*:') { return $call }
      return ($call.TrimEnd(')') + ', stdoutEncoding: utf8, stderrEncoding: utf8)')
    }
  )

  # Ensure dart:convert is imported if utf8 is referenced
  if (($src -ne $orig) -and ($src -match '\butf8\b') -and ($src -notmatch "(?m)^\s*import\s+'dart:convert';\s*$")) {
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
Write-Host "=== PATCH V5.1 COMPLETE ==="
Write-Host "Now run:"
Write-Host "  flutter clean"
Write-Host "  flutter pub get"
Write-Host "  flutter test"
Write-Host "  flutter run -d windows"
