$ErrorActionPreference = 'Stop'

# Display banner
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "       RAILWAY DEPLOYMENT SCRIPT        " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Create the uploads directory if it doesn't exist
Write-Host "Checking directory structure..." -ForegroundColor Yellow
if (-not (Test-Path -Path "frontend/backend/uploads")) {
    Write-Host "Creating uploads directory..." -ForegroundColor Yellow
    New-Item -Path "frontend/backend/uploads" -ItemType Directory -Force | Out-Null
    Write-Host "✓ Created uploads directory" -ForegroundColor Green
}

# Check for directory conflicts
Write-Host "Checking for directory/file conflicts..." -ForegroundColor Yellow
$repoPath = "frontend/backend/Repository.py"
if (Test-Path -Path $repoPath -PathType Container) {
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    $newName = "$repoPath-dir-$timestamp"
    Write-Host "⚠ $repoPath is a directory! Renaming to $newName" -ForegroundColor Yellow
    Rename-Item -Path $repoPath -NewName $newName -Force
}

$serverPath = "frontend/backend/server.js"
if (Test-Path -Path $serverPath -PathType Container) {
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    $newName = "$serverPath-dir-$timestamp"
    Write-Host "⚠ $serverPath is a directory! Renaming to $newName" -ForegroundColor Yellow
    Rename-Item -Path $serverPath -NewName $newName -Force
}

# Deploy with Railway
Write-Host "Deploying to Railway..." -ForegroundColor Green
railway up
