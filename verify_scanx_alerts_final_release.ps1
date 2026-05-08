# SCAN-X Final Alerts Release Verifier
$ErrorActionPreference = "Stop"

$AlertFile = "lib\core\services\alert_rules_engine.dart"
$NotifierFile = "lib\core\services\in_app_notifier.dart"

if (!(Test-Path "pubspec.yaml") -or !(Test-Path "lib")) {
    Write-Host "FAILED: Not in Flutter project root." -ForegroundColor Red
    exit 1
}

if (!(Test-Path $AlertFile)) {
    Write-Host "FAILED: Missing $AlertFile" -ForegroundColor Red
    exit 1
}

if (!(Test-Path $NotifierFile)) {
    Write-Host "FAILED: Missing $NotifierFile" -ForegroundColor Red
    exit 1
}

$Alert = Get-Content $AlertFile -Raw
$Notifier = Get-Content $NotifierFile -Raw

$RequiredAlertTerms = @(
    "notifyNewDevice",
    "notifyUnknownDevice",
    "notifyRouterVuln",
    "notifyIotWarning",
    "notifyHighRisk",
    "notifyScanCompleted",
    "alertNewDevice",
    "alertMacChange",
    "alertArpSpoof",
    "alertPortScanAttempts",
    "alertSensitivity"
)

$RequiredNotifierTerms = @(
    "notifyAutoScanResults",
    "alertSoundEnabled",
    "alertVibrationEnabled",
    "alertSilentMode"
)

$Failed = $false

foreach ($term in $RequiredAlertTerms) {
    if ($Alert -match $term) {
        Write-Host "PASS: $term wired in alert_rules_engine.dart" -ForegroundColor Green
    } else {
        Write-Host "FAIL: $term missing from alert_rules_engine.dart" -ForegroundColor Red
        $Failed = $true
    }
}

foreach ($term in $RequiredNotifierTerms) {
    if ($Notifier -match $term) {
        Write-Host "PASS: $term wired in in_app_notifier.dart" -ForegroundColor Green
    } else {
        Write-Host "FAIL: $term missing from in_app_notifier.dart" -ForegroundColor Red
        $Failed = $true
    }
}

if ($Failed) {
    Write-Host ""
    Write-Host "FINAL: NOT READY" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "FINAL: ALERTS READY" -ForegroundColor Green
