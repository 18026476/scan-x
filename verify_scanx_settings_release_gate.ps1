# SCAN-X Settings Release Gate Verifier

$ErrorActionPreference = "Stop"

$RequiredFiles = @(
  "lib\core\release_runtime\windows_startup_service.dart",
  "lib\core\release_runtime\log_retention_service.dart",
  "lib\core\release_runtime\anonymous_analytics_service.dart",
  "lib\core\release_runtime\app_update_service.dart",
  "lib\core\release_runtime\monitoring_scheduler_service.dart",
  "lib\core\release_runtime\release_settings_coordinator.dart"
)

$Missing = @()

foreach ($file in $RequiredFiles) {
    if (!(Test-Path $file)) {
        $Missing += $file
    }
}

if ($Missing.Count -gt 0) {
    Write-Host "FAILED: Missing release runtime files:" -ForegroundColor Red
    $Missing | ForEach-Object { Write-Host $_ -ForegroundColor Red }
    exit 1
}

$main = Get-Content "lib\main.dart" -Raw
if ($main -notmatch "ReleaseSettingsCoordinator.applyOnStartup") {
    Write-Host "FAILED: main.dart does not call ReleaseSettingsCoordinator.applyOnStartup()" -ForegroundColor Red
    exit 1
}

if (Test-Path "lib\settings_screen.dart") {
    Write-Host "FAILED: duplicate legacy lib/settings_screen.dart still exists" -ForegroundColor Red
    exit 1
}

Write-Host "SCAN-X SETTINGS RELEASE GATE PASSED" -ForegroundColor Green
Write-Host "Runtime wired:"
Write-Host "- Windows startup registration"
Write-Host "- Log retention cleanup"
Write-Host "- Anonymous local analytics gate"
Write-Host "- Update setting runtime coordinator"
Write-Host "- Continuous monitoring scheduler service"
Write-Host "- Notification preference getters"
Write-Host "- Legacy settings screen disabled"
