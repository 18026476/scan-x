param(
  [Parameter(Mandatory=$true)]
  [string]$ProjectRoot,

  [Parameter(Mandatory=$true)]
  [string]$PatchZip,

  [switch]$DryRun,

  [switch]$FlutterPubGet,
  [switch]$GitCommit,

  [string]$CommitMessage = "Apply SCAN-X patch"
)

$ErrorActionPreference = "Stop"

function FullPath([string]$p) { [System.IO.Path]::GetFullPath($p) }
function EnsureDir([string]$p) { if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Path $p | Out-Null } }
function Timestamp() { Get-Date -Format "yyyyMMdd_HHmmss" }

function DetectInnerRoot([string]$root) {
  $root = FullPath $root
  $hasLib = Test-Path (Join-Path $root "lib")
  $hasPubspec = Test-Path (Join-Path $root "pubspec.yaml")
  if ($hasLib -or $hasPubspec) { return $root }

  $children = Get-ChildItem -LiteralPath $root -Force
  $dirs = $children | Where-Object { $_.PSIsContainer }
  $files = $children | Where-Object { -not $_.PSIsContainer }

  if ($dirs.Count -eq 1 -and $files.Count -eq 0) { return $dirs[0].FullName }
  return $root
}

function BackupFile([string]$filePath, [string]$backupRoot, [string]$projectRoot) {
  $rel = $filePath.Substring($projectRoot.Length).TrimStart('\','/')
  $dest = Join-Path $backupRoot $rel
  EnsureDir (Split-Path $dest -Parent)

  if ($DryRun) { Write-Host "[DRYRUN] BACKUP $rel -> $dest"; return }
  Copy-Item -LiteralPath $filePath -Destination $dest -Force
}

function CopyTreeMerge([string]$src, [string]$dst, [string]$backupRoot, [string]$projectRoot) {
  $src = FullPath $src
  $dst = FullPath $dst
  EnsureDir $dst

  $files = Get-ChildItem -LiteralPath $src -Recurse -File -Force
  foreach ($f in $files) {
    $rel = $f.FullName.Substring($src.Length).TrimStart('\','/')
    $target = Join-Path $dst $rel
    EnsureDir (Split-Path $target -Parent)

    if (Test-Path -LiteralPath $target) {
      BackupFile -filePath $target -backupRoot $backupRoot -projectRoot $projectRoot
    }

    if ($DryRun) {
      Write-Host "[DRYRUN] COPY $rel -> $target"
    } else {
      Copy-Item -LiteralPath $f.FullName -Destination $target -Force
    }
  }
}

function FlattenNestedLib([string]$projectRoot, [string]$backupRoot) {
  $nested = Join-Path $projectRoot "lib\lib"
  if (-not (Test-Path -LiteralPath $nested)) { return }

  Write-Host "Detected nested folder: $nested"
  Write-Host "Flattening lib\lib -> lib ..."

  $src = $nested
  $dst = Join-Path $projectRoot "lib"

  $files = Get-ChildItem -LiteralPath $src -Recurse -File -Force
  foreach ($f in $files) {
    $rel = $f.FullName.Substring($src.Length).TrimStart('\','/')
    $target = Join-Path $dst $rel
    EnsureDir (Split-Path $target -Parent)

    if (Test-Path -LiteralPath $target) {
      BackupFile -filePath $target -backupRoot $backupRoot -projectRoot $projectRoot
    }

    if ($DryRun) {
      Write-Host "[DRYRUN] MOVE $rel -> $target"
    } else {
      Move-Item -LiteralPath $f.FullName -Destination $target -Force
    }
  }

  if (-not $DryRun) {
    try { Remove-Item -LiteralPath $nested -Recurse -Force } catch { Write-Host "Warning: couldn't remove $nested" }
  }
}

# ---- Main ----
$ProjectRoot = FullPath $ProjectRoot
$PatchZip = FullPath $PatchZip

if (-not (Test-Path -LiteralPath $ProjectRoot)) { throw "ProjectRoot not found: $ProjectRoot" }
if (-not (Test-Path -LiteralPath $PatchZip)) { throw "PatchZip not found: $PatchZip" }

# Require clean tree unless DryRun
if (-not $DryRun) {
  Push-Location $ProjectRoot
  $status = (git status --porcelain)
  Pop-Location
  if ($status) {
    Write-Host "ERROR: Working tree is not clean. Commit/stash first." -ForegroundColor Red
    Write-Host $status
    exit 1
  }
}

$backupRoot = Join-Path $ProjectRoot ("_patch_backup_" + (Timestamp))
EnsureDir $backupRoot

$tempRoot = Join-Path $ProjectRoot ("_patch_tmp_" + (Timestamp))
EnsureDir $tempRoot

Write-Host ""
Write-Host "=== APPLY SCAN-X PATCH ==="
Write-Host "ProjectRoot: $ProjectRoot"
Write-Host "PatchZip   : $PatchZip"
Write-Host "BackupRoot : $backupRoot"
Write-Host "TempRoot   : $tempRoot"
Write-Host "DryRun     : $DryRun"
Write-Host ""

if ($DryRun) {
  Write-Host "[DRYRUN] Would expand zip to $tempRoot"
} else {
  Expand-Archive -LiteralPath $PatchZip -DestinationPath $tempRoot -Force
}

$patchRootDetected = DetectInnerRoot $tempRoot
Write-Host "Detected patch root: $patchRootDetected"

CopyTreeMerge -src $patchRootDetected -dst $ProjectRoot -backupRoot $backupRoot -projectRoot $ProjectRoot
FlattenNestedLib -projectRoot $ProjectRoot -backupRoot $backupRoot

if ($FlutterPubGet) {
  if ($DryRun) {
    Write-Host "[DRYRUN] Would run: flutter pub get"
  } else {
    Push-Location $ProjectRoot
    flutter pub get
    Pop-Location
  }
}

if ($GitCommit) {
  if ($DryRun) {
    Write-Host "[DRYRUN] Would commit: $CommitMessage"
  } else {
    Push-Location $ProjectRoot
    git add -A
    git commit -m $CommitMessage
    Pop-Location
  }
}

Write-Host ""
Write-Host "DONE."
Write-Host "Backup created at: $backupRoot"
Write-Host "Temp extracted at : $tempRoot"
Write-Host ""
