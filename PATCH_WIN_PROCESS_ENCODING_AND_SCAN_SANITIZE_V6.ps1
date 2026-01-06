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

Write-Host "=== V6 PATCH: Windows-safe process decoding (systemEncoding) + scan screen sanitization ==="
Write-Host "ProjectRoot: $ProjectRoot"

# ------------------------------------------------------------
# 1) Ensure sanitizer exists (ASCII-safe)
# ------------------------------------------------------------
$sanAbs = Join-Path $ProjectRoot "lib\core\utils\text_sanitizer.dart"
Backup-File $sanAbs
Write-Utf8NoBom $sanAbs @"
import 'dart:convert';

bool _looksBroken(String s) {
  return s.contains('Ã') || s.contains('Â') || s.contains('â€') || s.contains('�');
}

String repairMojibake(String input) {
  if (input.isEmpty) return input;
  if (!_looksBroken(input)) return input;

  String s = input;

  // Try 2 rounds latin1 -> utf8 repair (handles double-mojibake)
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

  // Still broken? Strip non-ASCII to keep UI readable
  if (_looksBroken(s)) {
    s = s.replaceAll(RegExp(r'[^\x20-\x7E]+'), ' ');
    s = s.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  }

  return s;
}

String sanitizeUiText(String s) => repairMojibake(s);
"@

# ------------------------------------------------------------
# 2) Patch Process.run/start decoding across lib/**/*.dart:
#    - prefer systemEncoding on Windows to avoid garbage output
# ------------------------------------------------------------
$libDir = Join-Path $ProjectRoot "lib"
$dartFiles = Get-ChildItem -LiteralPath $libDir -Recurse -Filter *.dart

[int]$procTouched = 0

foreach ($f in $dartFiles) {
  $p = $f.FullName
  $src = Read-Raw $p
  if ($null -eq $src) { continue }
  $orig = $src

  # Replace existing utf8 decoding with systemEncoding (safer on Windows)
  $src = $src -replace "stdoutEncoding\s*:\s*utf8", "stdoutEncoding: systemEncoding"
  $src = $src -replace "stderrEncoding\s*:\s*utf8", "stderrEncoding: systemEncoding"

  # Add encoding args if missing (best-effort, only when Process.run/start present)
  if ($src -match "Process\.run\(" -and $src -notmatch "stdoutEncoding\s*:") {
    $src = [regex]::Replace(
      $src,
      "Process\.run\(([\s\S]*?)\)",
      {
        param($m)
        $call = $m.Value
        if ($call -match "stdoutEncoding\s*:") { return $call }
        return ($call.TrimEnd(')') + ", stdoutEncoding: systemEncoding, stderrEncoding: systemEncoding)")
      }
    )
  }

  if ($src -match "Process\.start\(" -and $src -notmatch "stdoutEncoding\s*:") {
    $src = [regex]::Replace(
      $src,
      "Process\.start\(([\s\S]*?)\)",
      {
        param($m)
        $call = $m.Value
        if ($call -match "stdoutEncoding\s*:") { return $call }
        return ($call.TrimEnd(')') + ", stdoutEncoding: systemEncoding, stderrEncoding: systemEncoding)")
      }
    )
  }

  # Ensure dart:io imported if systemEncoding referenced
  if (($src -ne $orig) -and ($src -match "\bsystemEncoding\b") -and ($src -notmatch "(?m)^\s*import\s+'dart:io';\s*$")) {
    if ($src -match "(?m)^import\s+") {
      $src = [regex]::Replace($src, "(?m)^import\s+", "import 'dart:io';`n`nimport ", 1)
    } else {
      $src = "import 'dart:io';`n`n$src"
    }
  }

  if ($src -ne $orig) {
    Backup-File $p
    Write-Utf8NoBom $p $src
    $procTouched++
  }
}

Write-Host "Process decoding patched files: $procTouched"

# ------------------------------------------------------------
# 3) Patch scan_screen.dart ONLY (safe and targeted)
#    - sanitize the Stealth scan status line
#    - replace unicode ellipsis with ASCII to avoid rendering weirdness
# ------------------------------------------------------------
$scanAbs = Join-Path $ProjectRoot "lib\features\scan\scan_screen.dart"
if (Test-Path -LiteralPath $scanAbs) {
  Backup-File $scanAbs
  $scan = Read-Raw $scanAbs
  $scanOrig = $scan

  # Ensure sanitizer import exists
  if ($scan -notmatch "core/utils/text_sanitizer\.dart") {
    if ($scan -match "(?m)^import\s+'package:flutter/material\.dart';\s*$") {
      $scan = $scan -replace "(?m)^import\s+'package:flutter/material\.dart';\s*$",
        "import 'package:flutter/material.dart';`nimport 'package:scanx_app/core/utils/text_sanitizer.dart';"
    } else {
      $scan = "import 'package:scanx_app/core/utils/text_sanitizer.dart';`n$scan"
    }
  }

  # Replace unicode ellipsis with ASCII (Scanning… -> Scanning...)
  $scan = $scan.Replace("Scanning…", "Scanning...")

  # Wrap the specific Stealth scan Text(...) string literal with sanitizeUiText(...)
  # Matches: Text('Stealth scan: ... Full Scan: ...', ...)
  $scan = [regex]::Replace(
    $scan,
    "Text\(\s*'([^']*Stealth scan:[^']*Full Scan:[^']*)'\s*(,)?",
    { param($m)
      $inner = $m.Groups[1].Value
      $comma = $m.Groups[2].Value
      if ($m.Value -match "sanitizeUiText\(") { return $m.Value }
      if ([string]::IsNullOrWhiteSpace($comma)) {
        return "Text(sanitizeUiText('$inner'))"
      } else {
        return "Text(sanitizeUiText('$inner'),"
      }
    },
    [System.Text.RegularExpressions.RegexOptions]::Singleline
  )

  if ($scan -ne $scanOrig) {
    Write-Utf8NoBom $scanAbs $scan
    Write-Host "Patched scan_screen.dart (sanitize + ellipsis)."
  } else {
    Write-Host "NOTE: scan_screen.dart did not match expected pattern for Stealth/Full line; no changes applied there."
  }
} else {
  Write-Host "WARN: scan_screen.dart not found at expected path; skipped scan UI patch."
}

Write-Host ""
Write-Host "=== V6 PATCH COMPLETE ==="
Write-Host "Now run:"
Write-Host "  flutter clean"
Write-Host "  flutter pub get"
Write-Host "  flutter test"
Write-Host "  flutter run -d windows"
