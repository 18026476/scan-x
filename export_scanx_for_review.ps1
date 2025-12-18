param(
  [string]$ProjectRoot = "C:\Users\Acer\scanx\scanx_app",
  [string]$OutDir = "$env:USERPROFILE\Desktop\scanx_exports"
)

$ErrorActionPreference = "Stop"

function Ensure-Dir([string]$p) {
  if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p | Out-Null }
}

function Timestamp() { Get-Date -Format "yyyyMMdd_HHmmss" }

$ts = Timestamp
Ensure-Dir $OutDir

$staging = Join-Path $OutDir "scanx_export_$ts"
Ensure-Dir $staging

Write-Host "ProjectRoot: $ProjectRoot"
Write-Host "Staging:     $staging"

# 1) Save a project tree
Push-Location $ProjectRoot
tree /A /F > (Join-Path $staging "project_tree.txt")
Pop-Location

# 2) Copy only key files/folders
$includePaths = @(
  "pubspec.yaml",
  "pubspec.lock",
  "README.md",
  "analysis_options.yaml",
  ".gitignore",
  "lib",
  "test",
  "integration_test"
)

foreach ($p in $includePaths) {
  $src = Join-Path $ProjectRoot $p
  if (Test-Path $src) {
    $dst = Join-Path $staging $p
    Write-Host "Copying $p ..."
    Copy-Item $src $dst -Recurse -Force
  }
}

# 3) Remove noisy folders if they got included
$removeIfExists = @(
  ".dart_tool",
  "build",
  ".idea",
  "backups"
)

foreach ($r in $removeIfExists) {
  $rp = Join-Path $staging $r
  if (Test-Path $rp) {
    Write-Host "Removing noisy folder: $r"
    Remove-Item $rp -Recurse -Force
  }
}

# 4) Create ZIP
$zipPath = Join-Path $OutDir "scanx_export_$ts.zip"
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

Compress-Archive -Path "$staging\*" -DestinationPath $zipPath -Force

Write-Host "`nDONE."
Write-Host "ZIP created: $zipPath"
