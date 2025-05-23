# Comprehensive Azure Deployment Script for both SQL Server and Flask Web App
param(
    [string]$resourceGroup = "mpp-music-library",
    [string]$location = "eastus",
    [string]$sqlServerName = "mpp-music-library-sql",
    [string]$databaseName = "MusicLibraryDB",
    [string]$adminLogin = "mppadmin",
    [SecureString]$adminPassword = (ConvertTo-SecureString -String "YourStrongPassword123!" -AsPlainText -Force),
    [string]$webAppName = "mpp-music-library-flask",
    [string]$pythonVersion = "3.9"
)

Write-Host "Installing Az module if not present..." -ForegroundColor Yellow
if (-not (Get-Module -ListAvailable Az)) {
    Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
}

Write-Host "Logging into Azure..." -ForegroundColor Yellow
Connect-AzAccount

# Create resource group
Write-Host "Creating resource group..." -ForegroundColor Yellow
New-AzResourceGroup -Name $resourceGroup -Location $location -Force

# Create SQL Server
Write-Host "Creating SQL Server..." -ForegroundColor Yellow
New-AzSqlServer -ResourceGroupName $resourceGroup `
    -ServerName $sqlServerName `
    -Location $location `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminLogin, $adminPassword)

# Configure firewall rules
Write-Host "Configuring firewall rules..." -ForegroundColor Yellow
New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroup `
    -ServerName $sqlServerName `
    -FirewallRuleName "AllowAllAzureIPs" `
    -StartIpAddress "0.0.0.0" `
    -EndIpAddress "255.255.255.255"

# Create database
Write-Host "Creating database..." -ForegroundColor Yellow
New-AzSqlDatabase -ResourceGroupName $resourceGroup `
    -ServerName $sqlServerName `
    -DatabaseName $databaseName `
    -Edition "Basic" `
    -MaxSizeBytes 2GB

# Create App Service Plan
Write-Host "Creating App Service Plan..." -ForegroundColor Yellow
New-AzAppServicePlan -ResourceGroupName $resourceGroup `
    -Name "${webAppName}-plan" `
    -Location $location `
    -Tier "Basic" `
    -NumberofWorkers 1 `
    -WorkerSize "Small" `
    -Linux

# Create Web App
Write-Host "Creating Web App..." -ForegroundColor Yellow
$webApp = New-AzWebApp -ResourceGroupName $resourceGroup `
    -Name $webAppName `
    -Location $location `
    -AppServicePlan "${webAppName}-plan" `
    -Runtime "PYTHON|$pythonVersion"

# Get the connection string
$connectionString = "Server=tcp:$sqlServerName.database.windows.net,1433;Initial Catalog=$databaseName;Persist Security Info=False;User ID=$adminLogin;Password=$($adminPassword | ConvertFrom-SecureString -AsPlainText);MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

# Configure Web App Settings
Write-Host "Configuring Web App Settings..." -ForegroundColor Yellow
$appSettings = @{
    "SQL_SERVER_HOST" = "$sqlServerName.database.windows.net"
    "SQL_SERVER_DATABASE" = $databaseName
    "SQL_SERVER_USERNAME" = $adminLogin
    "SQL_SERVER_PASSWORD" = $($adminPassword | ConvertFrom-SecureString -AsPlainText)
    "FLASK_ENV" = "production"
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
    "PYTHON_VERSION" = $pythonVersion
}

Set-AzWebApp -ResourceGroupName $resourceGroup `
    -Name $webAppName `
    -AppSettings $appSettings

# Save configuration
$config = @{
    "SQL_SERVER_CONNECTION_STRING" = $connectionString
    "SQL_SERVER_HOST" = "$sqlServerName.database.windows.net"
    "SQL_SERVER_DATABASE" = $databaseName
    "SQL_SERVER_USERNAME" = $adminLogin
    "SQL_SERVER_PASSWORD" = $($adminPassword | ConvertFrom-SecureString -AsPlainText)
    "FLASK_API_URL" = "https://$webAppName.azurewebsites.net"
}

$config | ConvertTo-Json | Out-File -FilePath "azure-config.json" -Encoding UTF8

Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "SQL Server Host: $sqlServerName.database.windows.net" -ForegroundColor Cyan
Write-Host "Database Name: $databaseName" -ForegroundColor Cyan
Write-Host "Flask Backend URL: https://$webAppName.azurewebsites.net" -ForegroundColor Cyan
Write-Host "Configuration saved to azure-config.json" -ForegroundColor Cyan