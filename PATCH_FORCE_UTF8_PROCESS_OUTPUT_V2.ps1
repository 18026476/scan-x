param()

$ErrorActionPreference = "Stop"
$ProjectRoot = (Resolve-Path -LiteralPath ".").Path
[System.IO.Directory]::SetCurrentDirectory($ProjectRoot)

function Timestamp() { Get-Date -Format "yyyyMMdd_HHmmss" }
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
  if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
  Write-Host "Wrote: $path"
}

Write-Host "=== PATCH V2: Force UTF-8 decoding for Process.run/start output ==="
Write-Host "ProjectRoot: $ProjectRoot"

$lib = Join-Path $ProjectRoot "lib"
if (-not (Test-Path -LiteralPath $lib)) { throw "Missing lib folder: $lib" }

$files = Get-ChildItem -LiteralPath $lib -Recurse -Filter *.dart
[int]$patched = 0

foreach ($f in $files) {
  $p = $f.FullName
  $src = Read-Raw $p
  if ($null -eq $src) { continue }   # <--- fixes your null crash
  $orig = $src

  $src = [regex]::Replace(
    $src,
    "Process\.run\(\s*([^,]+)\s*,\s*([^\)]+?)\)",
    {
      param($m)
      $call = $m.Value
      if ($call -match "stdoutEncoding\s*:") { return $call }
      return ($call.TrimEnd(')') + ", stdoutEncoding: utf8, stderrEncoding: utf8)")
    },
    [System.Text.RegularExpressions.RegexOptions]::Singleline
  )

  $src = [regex]::Replace(
    $src,
    "Process\.start\(\s*([^,]+)\s*,\s*([^\)]+?)\)",
    {
      param($m)
      $call = $m.Value
      if ($call -match "stdoutEncoding\s*:") { return $call }
      return ($call.TrimEnd(')') + ", stdoutEncoding: utf8, stderrEncoding: utf8)")
    },
    [System.Text.RegularExpressions.RegexOptions]::Singleline
  )

  if (($src -ne $orig) -and ($src -notmatch "(?m)^\s*import\s+'dart:convert';\s*$")) {
    if ($src -match "(?m)^import\s+") {
      $src = [regex]::Replace($src, "(?m)^import\s+", "import 'dart:convert';`n`nimport ", 1)
    } else {
      $src = "import 'dart:convert';`n`n$src"
    }
  }

  if ($src -ne $orig) {
    Backup-File $p
    Write-Utf8NoBom $p $src
    $patched++
  }
}

Write-Host ""
Write-Host "Patched dart files: $patched"
Write-Host "Next:"
Write-Host "  flutter clean"
Write-Host "  flutter pub get"
Write-Host "  flutter run -d windows"
