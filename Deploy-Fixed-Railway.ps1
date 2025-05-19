# Deploy-Fixed-Railway.ps1
# Script to deploy to Railway with the directory error fix

Write-Host "===== RAILWAY DEPLOYMENT WITH DIRECTORY ERROR FIX =====" -ForegroundColor Cyan
Write-Host "This script will deploy your app to Railway with fixes for the 'Is a directory (os error 21)' error" -ForegroundColor Yellow

# Verify required files exist
if (-not (Test-Path -Path railway.json)) {
    Write-Host "ERROR: railway.json not found in current directory" -ForegroundColor Red
    exit 1
}

# Check if Railway CLI is installed
try {
    $railwayInstalled = Get-Command railway -ErrorAction Stop
    Write-Host "✓ Railway CLI is installed" -ForegroundColor Green
}
catch {
    Write-Host "× Railway CLI not found" -ForegroundColor Red
    Write-Host "Please install Railway CLI with: npm i -g @railway/cli" -ForegroundColor Yellow
    exit 1
}

# Ensure all needed directories exist
Write-Host "Ensuring proper directory structure..." -ForegroundColor Yellow
if (-not (Test-Path -Path frontend/backend/uploads)) {
    New-Item -Path frontend/backend/uploads -ItemType Directory -Force | Out-Null
    Write-Host "✓ Created frontend/backend/uploads directory" -ForegroundColor Green
} 
else {
    Write-Host "✓ frontend/backend/uploads directory already exists" -ForegroundColor Green
}

# Ensure file paths are not directories
Write-Host "Checking for directory/file conflicts..." -ForegroundColor Yellow

# Check Repository.py
$repoPath = "frontend/backend/Repository.py"
if (Test-Path -Path $repoPath -PathType Container) {
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    $newName = "${repoPath}_dir_${timestamp}"
    Write-Host "⚠ $repoPath is a directory! Renaming to $newName" -ForegroundColor Yellow
    Rename-Item -Path $repoPath -NewName $newName -Force
}

# Check server.js
$serverPath = "frontend/backend/server.js"
if (Test-Path -Path $serverPath -PathType Container) {
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    $newName = "${serverPath}_dir_${timestamp}"
    Write-Host "⚠ $serverPath is a directory! Renaming to $newName" -ForegroundColor Yellow
    Rename-Item -Path $serverPath -NewName $newName -Force
}

# Deploy to Railway
Write-Host "`nDeploying to Railway..." -ForegroundColor Green
railway up

# Check deployment status
if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✓ Deployment successful!" -ForegroundColor Green
    Write-Host "Your app should now be running on Railway without the 'Is a directory' error" -ForegroundColor Green
} 
else {
    Write-Host "`n× Deployment failed with exit code $LASTEXITCODE" -ForegroundColor Red
    Write-Host "Check the error messages above for more details" -ForegroundColor Yellow
}
