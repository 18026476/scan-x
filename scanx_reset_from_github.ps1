param(
    [string]$BasePath = "C:\Users\Acer\scanx",
    [string]$RepoUrl  = "https://github.com/18026476/scan-x.git",
    [string]$ProjectFolderName = "scanx_app"
)

Write-Host "=== SCAN-X FULL RESET FROM GITHUB ===" -ForegroundColor Cyan

Set-Location $BasePath

$projectPath = Join-Path $BasePath $ProjectFolderName

if (Test-Path $projectPath) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupName = "${ProjectFolderName}_backup_$timestamp"
    $backupPath = Join-Path $BasePath $backupName

    Write-Host "Backing up existing project to '$backupPath'..." -ForegroundColor Yellow
    Rename-Item -Path $projectPath -NewName $backupName
    Write-Host "Backup complete." -ForegroundColor Green
}
else {
    Write-Host "No existing '$ProjectFolderName' folder found – nothing to back up." -ForegroundColor Yellow
}

Write-Host "Cloning from GitHub: $RepoUrl" -ForegroundColor Cyan
git clone $RepoUrl $ProjectFolderName
if (-not $?) {
    Write-Host "Git clone failed. Check your internet / credentials." -ForegroundColor Red
    exit 1
}

Set-Location (Join-Path $BasePath $ProjectFolderName)

Write-Host "Running 'flutter pub get'..." -ForegroundColor Cyan
flutter pub get
if (-not $?) {
    Write-Host "flutter pub get failed – fix this before continuing." -ForegroundColor Red
    exit 1
}

Write-Host "Running 'flutter analyze'..." -ForegroundColor Cyan
flutter analyze

Write-Host "Starting Flutter app for Windows..." -ForegroundColor Cyan
flutter run -d windows
