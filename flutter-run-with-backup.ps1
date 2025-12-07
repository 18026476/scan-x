param(
    [string]$Message = "Backup before flutter run"
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$backupScript = Join-Path $scriptDir "backup-scanx.ps1"

Write-Host "Running backup before flutter run..." -ForegroundColor Cyan

if (Test-Path $backupScript) {
    & $backupScript -Message $Message
} else {
    Write-Host "WARNING: backup-scanx.ps1 not found, skipping backup." -ForegroundColor Yellow
}

Write-Host "`nStarting flutter run -d windows...`n" -ForegroundColor Cyan
flutter run -d windows
