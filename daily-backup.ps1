param(
    [string]$Message = "Daily auto backup"
)

# Call the main backup script from the same folder
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$backupScript = Join-Path $scriptDir "backup-scanx.ps1"

if (-not (Test-Path $backupScript)) {
    Write-Host "ERROR: backup-scanx.ps1 not found in $scriptDir" -ForegroundColor Red
    exit 1
}

& $backupScript -Message $Message
