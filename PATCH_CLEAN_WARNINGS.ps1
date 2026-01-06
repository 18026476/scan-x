param(
  [Parameter(Mandatory=$false)]
  [string]$ProjectRoot
)

$ErrorActionPreference = "Stop"

function Find-ProjectRoot([string]$startDir) {
  $d = (Resolve-Path -LiteralPath $startDir).Path
  for ($i=0; $i -lt 10; $i++) {
    $candidate = Join-Path $d "pubspec.yaml"
    if (Test-Path -LiteralPath $candidate) { return $d }
    $parent = Split-Path -Parent $d
    if ($parent -eq $d -or [string]::IsNullOrWhiteSpace($parent)) { break }
    $d = $parent
  }
  return $null
}

function Timestamp() { Get-Date -Format "yyyyMMdd_HHmmss" }

function Ensure-Dir([string]$dir) {
  if ([string]::IsNullOrWhiteSpace($dir)) { return }
  if (-not (Test-Path -LiteralPath $dir)) {
    New-Item -ItemType Directory -Path $dir | Out-Null
  }
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
  $full = (Resolve-Path -LiteralPath (Split-Path -Parent $path)).Path
  Ensure-Dir $full
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
  Write-Host "Wrote: $path"
}

# ---- Resolve project root and force working directory ----
if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
  $ProjectRoot = Find-ProjectRoot (Get-Location).Path
  if ($null -eq $ProjectRoot) { throw "pubspec.yaml not found. Run from project root or pass -ProjectRoot." }
} else {
  $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot.Trim().Trim('"').Trim("'")).Path
  $auto = Find-ProjectRoot $ProjectRoot
  if ($null -eq $auto) { throw "Could not find pubspec.yaml under: $ProjectRoot" }
  $ProjectRoot = $auto
}

Set-Location $ProjectRoot
Write-Host "=== PATCH_CLEAN_WARNINGS ==="
Write-Host "ProjectRoot: $ProjectRoot"

# Safety check
if (-not (Test-Path -LiteralPath ".\pubspec.yaml")) {
  throw "Not in project root after Set-Location. Aborting."
}

# Helper: de-dupe import lines in a file (keeps first occurrence)
function Dedup-Imports([string]$text) {
  $lines = $text -split "`r?`n"
  $seen = @{}
  $out = New-Object System.Collections.Generic.List[string]
  foreach ($ln in $lines) {
    if ($ln -match "^\s*import\s+") {
      $k = $ln.Trim()
      if ($seen.ContainsKey($k)) { continue }
      $seen[$k] = $true
    }
    $out.Add($ln)
  }
  return ($out -join "`n")
}

# 1) Fix duplicate import in integration_test
$it = ".\integration_test\settings_toggles_smoke_test.dart"
if (Test-Path -LiteralPath $it) {
  Backup-File $it
  $c = Read-Raw $it
  $c2 = Dedup-Imports $c
  Write-Utf8NoBom $it $c2
}

# 2) Remove unused post_scan_pipeline import from scan_screen.dart
$scan = ".\lib\features\scan\scan_screen.dart"
if (Test-Path -LiteralPath $scan) {
  Backup-File $scan
  $c = Read-Raw $scan
  $c = [regex]::Replace($c, "(?m)^\s*import\s+'.+/post_scan_pipeline\.dart';\s*\r?\n", "")
  Write-Utf8NoBom $scan $c
}

# 3) Fix settings_screen.dart: remove unused + duplicate ai_labs_tab imports
$ss = ".\lib\features\settings\settings_screen.dart"
if (Test-Path -LiteralPath $ss) {
  Backup-File $ss
  $c = Read-Raw $ss

  $usesAiLabs = ($c -match "\bAiLabsTab\b") -or ($c -match "\baiLabsTab\b")
  if (-not $usesAiLabs) {
    $c = [regex]::Replace($c, "(?m)^\s*import\s+'.*ai_labs_tab\.dart';\s*\r?\n", "")
  }
  $c = Dedup-Imports $c
  Write-Utf8NoBom $ss $c
}

# 4) in_app_notifier: unnecessary braces in interpolation
$notifier = ".\lib\core\services\in_app_notifier.dart"
if (Test-Path -LiteralPath $notifier) {
  Backup-File $notifier
  $c = Read-Raw $notifier
  $c = $c -replace "\$\{top\.title\}", '$top.title'
  Write-Utf8NoBom $notifier $c
}

# 5) post_scan_pipeline: use_build_context_synchronously -> add context.mounted guard
$pipeline = ".\lib\core\services\post_scan_pipeline.dart"
if (Test-Path -LiteralPath $pipeline) {
  Backup-File $pipeline
  $c = Read-Raw $pipeline
  if ($c -match "InAppNotifier\(\)\.notify") {
    if ($c -notmatch "context\.mounted") {
      $c = [regex]::Replace(
        $c,
        "(\s*)await\s+InAppNotifier\(\)\.notify\(",
        "`$1if (!context.mounted) return;`n`$1await InAppNotifier().notify(",
        [System.Text.RegularExpressions.RegexOptions]::Singleline
      )
    }
  }
  Write-Utf8NoBom $pipeline $c
}

# 6) report_builder: braces on rating chain (if it matches the simple pattern)
$rb = ".\lib\core\services\report_builder.dart"
if (Test-Path -LiteralPath $rb) {
  Backup-File $rb
  $c = Read-Raw $rb
  $c = $c -replace "(?m)^\s*if\s*\(score\s*>=\s*80\)\s*rating\s*=\s*'Critical';\s*$", "    if (score >= 80) { rating = 'Critical'; }"
  $c = $c -replace "(?m)^\s*else\s+if\s*\(score\s*>=\s*50\)\s*rating\s*=\s*'High';\s*$", "    else if (score >= 50) { rating = 'High'; }"
  $c = $c -replace "(?m)^\s*else\s+if\s*\(score\s*>=\s*20\)\s*rating\s*=\s*'Medium';\s*$", "    else if (score >= 20) { rating = 'Medium'; }"
  $c = $c -replace "(?m)^\s*else\s*rating\s*=\s*'Low';\s*$", "    else { rating = 'Low'; }"
  Write-Utf8NoBom $rb $c
}

Write-Host "`n=== PATCH COMPLETE ==="
Write-Host "Next: flutter analyze"
