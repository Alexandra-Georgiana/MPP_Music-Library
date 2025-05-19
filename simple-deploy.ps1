# Simplified Master Deployment Script
Write-Host "Starting deployment..." -ForegroundColor Green

# Step 1: Generate SSL certificates
Write-Host "Step 1: Setting up SSL certificates..." -ForegroundColor Yellow
if (-not (Test-Path "./ssl/certificate.crt")) {
    Write-Host "Generating new SSL certificates..."
    ./setup-ssl.ps1
} else {
    Write-Host "SSL certificates already exist" -ForegroundColor Green
}

# Step 2: Login to Azure
Write-Host "Step 2: Logging in to Azure..." -ForegroundColor Yellow
Write-Host "Please log in to your Azure account in the browser window that opens."
az login

# Step 3: Set up Azure Resources
Write-Host "Step 3: Setting up Azure resources..." -ForegroundColor Yellow
$setupAzure = Read-Host "Do you want to set up Azure resources? (y/n) Default: y"
if ($setupAzure -ne "n") {
    Write-Host "Running Azure setup script..."
    ./setup-azure.ps1
    Write-Host "Azure resources set up successfully" -ForegroundColor Green
} else {
    Write-Host "Skipping Azure resource setup." -ForegroundColor Yellow
}

# Step 4: Deploy to Azure
Write-Host "Step 4: Deploying to Azure..." -ForegroundColor Yellow
./deploy-to-azure.ps1

# Completion message
Write-Host "Deployment completed successfully!" -ForegroundColor Green
Write-Host "Check the Azure Portal for your deployed resources: https://portal.azure.com" -ForegroundColor Cyan
