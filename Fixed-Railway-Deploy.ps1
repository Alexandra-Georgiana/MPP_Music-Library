#!/usr/bin/env pwsh
# Fixed-Railway-Deploy.ps1 - Script to deploy to Railway with fixed configuration

Write-Host "Starting fixed Railway deployment process..." -ForegroundColor Cyan

# Check Railway CLI installation
if (-not (Get-Command railway -ErrorAction SilentlyContinue)) {
    Write-Host "Railway CLI not installed. Installing..." -ForegroundColor Yellow
    npm install -g @railway/cli
}

# Make sure Railway is authenticated
$railwayStatus = railway status 2>&1
if ($railwayStatus -like "*Please login*") {
    Write-Host "Not logged in to Railway. Please login now:" -ForegroundColor Yellow
    railway login
}

# Verify all required files exist
$requiredFiles = @(
    "railway.json",
    "deploy-nixpacks.toml",
    "pre-deploy.sh",
    "railway-up.js",
    "frontend/backend/Repository.py.railway",
    "frontend/backend/server.js.railway",
    "frontend/backend/requirements.txt"
)

foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        Write-Host "ERROR: Required file '$file' is missing!" -ForegroundColor Red
        exit 1
    }
}

# Check if requirements.txt has content
$requirementsTxt = Get-Content "frontend/backend/requirements.txt"
if ($requirementsTxt.Count -eq 0) {
    Write-Host "ERROR: requirements.txt is empty!" -ForegroundColor Red
    
    # Fix requirements.txt if empty
    Write-Host "Creating proper requirements.txt..." -ForegroundColor Yellow
    @(
        "flask==2.2.3",
        "pyodbc==4.0.39",
        "sqlalchemy==2.0.7",
        "psycopg2-binary==2.9.6",
        "python-dotenv==1.0.0",
        "jwt==1.3.1",
        "pyjwt==2.6.0",
        "cryptography==40.0.1",
        "werkzeug==2.2.3",
        "gunicorn==21.2.0"
    ) | Out-File -FilePath "frontend/backend/requirements.txt" -Encoding utf8
}

# Make sure pre-deploy.sh is executable (for Unix systems)
Write-Host "Ensuring pre-deploy.sh is executable..." -ForegroundColor Yellow
git update-index --chmod=+x ./pre-deploy.sh

# Link to Railway project
Write-Host "Linking to Railway project..." -ForegroundColor Yellow
railway link

# Deploy to Railway
Write-Host "Deploying to Railway with fixed configuration..." -ForegroundColor Cyan
railway up

# Status check
if ($LASTEXITCODE -eq 0) {
    Write-Host "Deployment succeeded!" -ForegroundColor Green
    Write-Host "To initialize the database, run:" -ForegroundColor Yellow
    Write-Host "railway run 'python frontend/backend/init_railway_db.py'" -ForegroundColor White
} else {
    Write-Host "Deployment failed with exit code $LASTEXITCODE" -ForegroundColor Red
}
