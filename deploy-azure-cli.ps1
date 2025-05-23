# Azure CLI Deployment Script
param(
    [string]$resourceGroup = "mpp-music-library",
    [string]$location = "eastus",
    [string]$sqlServerName = "mpp-music-library-sql",
    [string]$databaseName = "MusicLibraryDB",
    [string]$adminLogin = "mppadmin",
    [string]$adminPassword = $null,
    [string]$webAppName = "mpp-music-library-flask",
    [switch]$useExisting
)

# Check if we're logged in
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "Please log in to Azure..." -ForegroundColor Yellow
    az login
}

# Prompt for SQL admin password if not provided
if (-not $adminPassword) {
    $securePassword = Read-Host "Enter SQL Server admin password" -AsSecureString
    $adminPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))
}
)

Write-Host "Checking Azure CLI installation..." -ForegroundColor Yellow
$azCliVersion = az --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Azure CLI not found. Please install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows" -ForegroundColor Red
    exit 1
}

Write-Host "Logging into Azure..." -ForegroundColor Yellow
az login

# Create resource group
Write-Host "Creating resource group..." -ForegroundColor Yellow
az group create --name $resourceGroup --location $location

# Create SQL Server
Write-Host "Creating SQL Server..." -ForegroundColor Yellow
az sql server create `
    --name $sqlServerName `
    --resource-group $resourceGroup `
    --location $location `
    --admin-user $adminLogin `
    --admin-password $adminPassword

# Configure firewall rules
Write-Host "Configuring firewall rules..." -ForegroundColor Yellow
az sql server firewall-rule create `
    --resource-group $resourceGroup `
    --server $sqlServerName `
    --name AllowAllAzureIPs `
    --start-ip-address 0.0.0.0 `
    --end-ip-address 255.255.255.255

# Create database
Write-Host "Creating database..." -ForegroundColor Yellow
az sql db create `
    --resource-group $resourceGroup `
    --server $sqlServerName `
    --name $databaseName `
    --edition Basic `
    --capacity 5

# Create App Service Plan
Write-Host "Creating App Service Plan..." -ForegroundColor Yellow
az appservice plan create `
    --name "${webAppName}-plan" `
    --resource-group $resourceGroup `
    --sku B1 `
    --is-linux

# Create Web App
Write-Host "Creating Web App..." -ForegroundColor Yellow
az webapp create `
    --resource-group $resourceGroup `
    --plan "${webAppName}-plan" `
    --name $webAppName `
    --runtime "PYTHON:3.9"

# Configure Web App Settings
Write-Host "Configuring Web App Settings..." -ForegroundColor Yellow
az webapp config appsettings set `
    --resource-group $resourceGroup `
    --name $webAppName `
    --settings `
    SQL_SERVER_HOST="$sqlServerName.database.windows.net" `
    SQL_SERVER_DATABASE=$databaseName `
    SQL_SERVER_USERNAME=$adminLogin `
    SQL_SERVER_PASSWORD=$adminPassword `
    FLASK_ENV="production" `
    SCM_DO_BUILD_DURING_DEPLOYMENT="true"

# Save configuration
$config = @{
    "SQL_SERVER_CONNECTION_STRING" = "Server=tcp:$sqlServerName.database.windows.net,1433;Initial Catalog=$databaseName;Persist Security Info=False;User ID=$adminLogin;Password=$adminPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    "SQL_SERVER_HOST" = "$sqlServerName.database.windows.net"
    "SQL_SERVER_DATABASE" = $databaseName
    "SQL_SERVER_USERNAME" = $adminLogin
    "SQL_SERVER_PASSWORD" = $adminPassword
    "FLASK_API_URL" = "https://$webAppName.azurewebsites.net"
}

$config | ConvertTo-Json | Out-File -FilePath "azure-config.json" -Encoding UTF8

Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "SQL Server Host: $sqlServerName.database.windows.net" -ForegroundColor Cyan
Write-Host "Database Name: $databaseName" -ForegroundColor Cyan
Write-Host "Flask Backend URL: https://$webAppName.azurewebsites.net" -ForegroundColor Cyan
Write-Host "Configuration saved to azure-config.json" -ForegroundColor Cyan
