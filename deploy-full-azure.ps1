# Master deployment script for the Music Player Project to Azure
# This script will:
# 1. Generate SSL certificates if needed
# 2. Setup Azure resources
# 3. Build and deploy frontend, backend, and database

# Display colorful banner
Write-Host "`n`n==============================================" -ForegroundColor Cyan
Write-Host "     MUSIC PLAYER PROJECT - AZURE DEPLOYMENT    " -ForegroundColor Cyan
Write-Host "==============================================`n" -ForegroundColor Cyan

# Step 1: Check prerequisites
Write-Host "STEP 1: Checking prerequisites..." -ForegroundColor Yellow

# Check if Azure CLI is installed
try {
    $azVersion = (az --version) | Select-Object -First 1
    Write-Host "✓ Azure CLI found: $azVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Azure CLI not found. Please install Azure CLI:" -ForegroundColor Red
    Write-Host "  https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows" -ForegroundColor Red
    exit 1
}

# Check if Docker is installed
try {
    $dockerVersion = (docker --version)
    Write-Host "✓ Docker found: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker not found. Please install Docker Desktop:" -ForegroundColor Red
    Write-Host "  https://www.docker.com/products/docker-desktop" -ForegroundColor Red
    exit 1
}

# Step 2: Generate SSL certificates
Write-Host "`nSTEP 2: Setting up SSL certificates..." -ForegroundColor Yellow
if (-not (Test-Path "./ssl/certificate.crt") -or -not (Test-Path "./ssl/cert.pfx")) {
    Write-Host "Generating new SSL certificates..."
    ./setup-ssl.ps1
} else {
    Write-Host "✓ SSL certificates already exist" -ForegroundColor Green
}

# Step 3: Login to Azure
Write-Host "`nSTEP 3: Logging in to Azure..." -ForegroundColor Yellow
Write-Host "Please log in to your Azure account in the browser window that opens."
az login
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Azure login failed. Please try again." -ForegroundColor Red
    exit 1
}
Write-Host "✓ Successfully logged in to Azure" -ForegroundColor Green

# Step 4: Set up Azure Resources
Write-Host "`nSTEP 4: Setting up Azure resources..." -ForegroundColor Yellow
Write-Host "This step will create all necessary Azure resources for your application."
Write-Host "If you have already run this step before, you can choose to skip it."

$setupAzure = Read-Host "Do you want to set up Azure resources? (y/n) (Default: y)"
if ($setupAzure -ne "n") {
    Write-Host "Running Azure setup script..."
    ./setup-azure.ps1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "✗ Azure resource setup failed. Please check the error messages above." -ForegroundColor Red
        exit 1
    }
    Write-Host "✓ Azure resources set up successfully" -ForegroundColor Green
} else {
    Write-Host "Skipping Azure resource setup." -ForegroundColor Yellow
}

# Step 5: Deploy to Azure
Write-Host "`nSTEP 5: Deploying to Azure..." -ForegroundColor Yellow
Write-Host "This step will build and deploy your application to Azure."

# Build and deploy
./deploy-to-azure.ps1
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Deployment to Azure failed. Please check the error messages above." -ForegroundColor Red
    exit 1
}

# Display completion message
Write-Host "`n`n===============================================" -ForegroundColor Green
Write-Host "     DEPLOYMENT COMPLETED SUCCESSFULLY!     " -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green

# Read the output URLs and display them
if (Test-Path "./azure-deployment-output.json") {
    $deploymentOutput = Get-Content -Raw -Path "./azure-deployment-output.json" | ConvertFrom-Json
    
    Write-Host "`nYour application is now accessible at:" -ForegroundColor Cyan
    Write-Host "Frontend URL:  $($deploymentOutput.frontendUrl)" -ForegroundColor White
    Write-Host "API Base URL:  $($deploymentOutput.apiUrl)" -ForegroundColor White
    
    Write-Host "`nDatabase Connection Information:" -ForegroundColor Cyan
    Write-Host "Server:       $($deploymentOutput.dbServer)" -ForegroundColor White
    Write-Host "Database:     $($deploymentOutput.dbName)" -ForegroundColor White
} else {
    Write-Host "`nPlease check the Azure Portal for your deployed resources:" -ForegroundColor Cyan
    Write-Host "https://portal.azure.com" -ForegroundColor White
}

Write-Host "`nNote: It may take a few minutes for your services to start up and be accessible." -ForegroundColor Yellow
Write-Host "If you encounter any issues, please check the Azure portal for logs and diagnostics." -ForegroundColor Yellow
