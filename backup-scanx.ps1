param(
    [string]$Message
)

Write-Host "`n=== SCAN-X GIT BACKUP ===`n" -ForegroundColor Cyan

# 1. Check git is available
$git = Get-Command git -ErrorAction SilentlyContinue
if (-not $git) {
    Write-Host "ERROR: git is not installed or not in PATH." -ForegroundColor Red
    Write-Host "Install Git from https://git-scm.com/downloads and reopen PowerShell."
    exit 1
}

# 2. Ensure we are inside a git repo
if (-not (Test-Path ".git")) {
    Write-Host "No .git folder found. Initializing new git repository..." -ForegroundColor Yellow
    git init

    # Make sure we are on 'main' branch
    git branch -M main
}

# 3. Ensure username/email are set (only if missing)
$existingName  = git config user.name
$existingEmail = git config user.email

if (-not $existingName) {
    Write-Host "Setting git user.name to '18026476' (customise if needed)..." -ForegroundColor Yellow
    git config user.name "18026476"
}

if (-not $existingEmail) {
    Write-Host "Setting git user.email to '18026476kh@gmail.com'..." -ForegroundColor Yellow
    git config user.email "18026476kh@gmail.com"
}

# 4. Ensure remote 'origin' is configured
$remoteUrl = "https://github.com/18026476/scanx_app.git"

try {
    $origin = git remote get-url origin 2>$null
} catch {
    $origin = $null
}

if (-not $origin) {
    Write-Host "Adding remote 'origin' -> $remoteUrl" -ForegroundColor Yellow
    git remote add origin $remoteUrl
} else {
    Write-Host "Remote 'origin' already set to $origin" -ForegroundColor Green
}

# 5. Show current changes
Write-Host "`nGit status (before commit):" -ForegroundColor DarkCyan
git status --short

# 6. If nothing to commit, exit gracefully
$changes = git status --porcelain
if (-not $changes) {
    Write-Host "`nNo changes to commit. Working tree clean." -ForegroundColor Green
    exit 0
}

# 7. Build commit message
if (-not $Message -or $Message.Trim() -eq "") {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
    $Message = "Auto backup - $timestamp"
}

Write-Host "`nStaging all changes..." -ForegroundColor Yellow
git add .

Write-Host "Creating commit: '$Message'" -ForegroundColor Yellow
git commit -m "$Message"

# 8. Push to origin/main
Write-Host "`nPushing to origin/main..." -ForegroundColor Yellow
git push -u origin main

Write-Host "`n=== BACKUP COMPLETE ✅ ===`n" -ForegroundColor Green
