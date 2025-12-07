Write-Host "`n=== SCAN-X BACKUP STATUS ===`n" -ForegroundColor Cyan

$git = Get-Command git -ErrorAction SilentlyContinue
if (-not $git) {
    Write-Host "ERROR: git is not installed or not in PATH." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path ".git")) {
    Write-Host "This folder is NOT a git repository (no .git found)." -ForegroundColor Red
    exit 1
}

Write-Host "Repository root: $(Get-Location)" -ForegroundColor Green

Write-Host "`nRemotes:" -ForegroundColor DarkCyan
git remote -v

Write-Host "`nLast commit:" -ForegroundColor DarkCyan
git log -1 --oneline

Write-Host "`nWorking tree status:" -ForegroundColor DarkCyan
git status --short

Write-Host "`nIf you see a recent commit and no unpushed changes, backup is OK ✅`n" -ForegroundColor Green
