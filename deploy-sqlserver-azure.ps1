# Azure SQL Server deployment script
param(
    [string]$resourceGroup = "mpp-music-library",
    [string]$location = "eastus",
    [string]$serverName = "mpp-music-library-sql",
    [string]$databaseName = "MusicLibraryDB",
    [string]$adminLogin = "mppadmin",
    [SecureString]$adminPassword = (ConvertTo-SecureString -String "YourStrongPassword123!" -AsPlainText -Force)
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
    -ServerName $serverName `
    -Location $location `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminLogin, $adminPassword)

# Configure firewall rules
Write-Host "Configuring firewall rules..." -ForegroundColor Yellow
New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroup `
    -ServerName $serverName `
    -FirewallRuleName "AllowAllAzureIPs" `
    -StartIpAddress "0.0.0.0" `
    -EndIpAddress "255.255.255.255"

# Create database
Write-Host "Creating database..." -ForegroundColor Yellow
New-AzSqlDatabase -ResourceGroupName $resourceGroup `
    -ServerName $serverName `
    -DatabaseName $databaseName `
    -Edition "Basic" `
    -MaxSizeBytes 2GB

# Get the connection string
$connectionString = "Server=tcp:$serverName.database.windows.net,1433;Initial Catalog=$databaseName;Persist Security Info=False;User ID=$adminLogin;Password=$($adminPassword | ConvertFrom-SecureString -AsPlainText);MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

# Save connection string to a file
$config = @{
    "SQL_SERVER_CONNECTION_STRING" = $connectionString
    "SQL_SERVER_HOST" = "$serverName.database.windows.net"
    "SQL_SERVER_DATABASE" = $databaseName
    "SQL_SERVER_USERNAME" = $adminLogin
    "SQL_SERVER_PASSWORD" = $($adminPassword | ConvertFrom-SecureString -AsPlainText)
}

$config | ConvertTo-Json | Out-File -FilePath "azure-sql-config.json" -Encoding UTF8

Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "Connection details saved to azure-sql-config.json" -ForegroundColor Cyan
Write-Host "SQL Server Host: $serverName.database.windows.net" -ForegroundColor Cyan
Write-Host "Database Name: $databaseName" -ForegroundColor Cyan
