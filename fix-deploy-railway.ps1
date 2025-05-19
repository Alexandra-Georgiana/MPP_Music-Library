# Simple but effective Railway deployment script
# Fixes "Is a directory (os error 21)" error

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  RAILWAY DEPLOYMENT WITH ERROR FIX     " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Step 1: Check for conflicting 'app' directory
Write-Host "Checking for 'app' directory conflicts..." -ForegroundColor Yellow
if (Test-Path -Path "app") {
    if (Test-Path -Path "app" -PathType Container) {
        $timestamp = Get-Date -Format "yyyyMMddHHmmss"
        $newName = "app_folder_$timestamp"
        Write-Host "Found 'app' directory! Renaming to $newName" -ForegroundColor Red
        Rename-Item -Path "app" -NewName $newName -Force
    } else {
        Write-Host "'app' is a file. Renaming to app.bak" -ForegroundColor Yellow
        Rename-Item -Path "app" -NewName "app.bak" -Force
    }
}

# Step 2: Update Nixpacks configuration
Write-Host "Setting custom output directory in deploy-nixpacks.toml..." -ForegroundColor Yellow
$nixpacksContent = Get-Content -Path "deploy-nixpacks.toml" -Raw
if ($nixpacksContent -match "output = ") {
    $nixpacksContent = $nixpacksContent -replace 'output = ".*?"', 'output = "dist_railway"'
} else {
    $nixpacksContent += "`noutput = `"dist_railway`""
}
Set-Content -Path "deploy-nixpacks.toml" -Value $nixpacksContent
Write-Host "Updated deploy-nixpacks.toml with custom output directory" -ForegroundColor Green

# Step 3: Create a clean railway.json
Write-Host "Creating clean railway.json..." -ForegroundColor Yellow
$railwayJson = @"
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "NIXPACKS",
    "nixpacksConfigPath": "deploy-nixpacks.toml",
    "buildCommand": "bash ./pre-deploy-clean2.sh"
  },
  "deploy": {
    "numReplicas": 1,
    "startCommand": "node railway-up-clean2.js",
    "healthcheckPath": "/",
    "healthcheckTimeout": 100,
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 5,
    "sleepApplication": false
  }
}
"@
Set-Content -Path "railway.json" -Value $railwayJson
Write-Host "Created clean railway.json" -ForegroundColor Green

# Step 4: Make pre-deploy script executable in Git
Write-Host "Making pre-deploy-clean2.sh executable..." -ForegroundColor Yellow
git update-index --chmod=+x pre-deploy-clean2.sh

# Step 5: Deployment
Write-Host "Ready to deploy to Railway!" -ForegroundColor Cyan
$deploy = Read-Host "Do you want to deploy now? (y/n)"

if ($deploy -eq "y") {
    Write-Host "Deploying to Railway..." -ForegroundColor Cyan
    railway up
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`nDeployment successful!" -ForegroundColor Green
    } else {
        Write-Host "`nDeployment failed with exit code $LASTEXITCODE" -ForegroundColor Red
    }
} else {
    Write-Host "Deployment skipped. Run 'railway up' to deploy manually." -ForegroundColor Yellow
}

Write-Host "Process completed." -ForegroundColor Cyan
