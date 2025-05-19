# PowerShell script for building and deploying containers to Azure

# Environment variables
$registryName = Read-Host "Enter your Azure Container Registry name (e.g., mppregistry1234)"
$resourceGroup = Read-Host "Enter your Azure Resource Group name (e.g., mpp-resource-group)"
$sqlServerName = Read-Host "Enter your Azure SQL Server name (e.g., mpp-sqlserver1234)"
$sqlDbName = Read-Host "Enter your SQL Database name (default: MusicLibrary)" -DefaultValue "MusicLibrary"
$sqlAdminUser = Read-Host "Enter your SQL admin username"
$sqlAdminPassword = Read-Host "Enter your SQL admin password" -AsSecureString
$plainTextPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($sqlAdminPassword))

# Login to Azure Container Registry
Write-Host "`nLogging in to Azure Container Registry..."
az acr login --name $registryName

# Set SQL Server password for Docker Compose
$env:SQL_SERVER_PASSWORD = $plainTextPassword

# Update the Docker Compose file with the connection string for SQL Server
$dockerComposeContent = Get-Content -Path ".\docker-compose.azure.yml" -Raw
$connectionString = "mssql+pyodbc://${sqlAdminUser}:${plainTextPassword}@${sqlServerName}.database.windows.net:1433/${sqlDbName}?driver=ODBC+Driver+17+for+SQL+Server"
$dockerComposeContent = $dockerComposeContent -replace "SQL_SERVER_CONNECTION_STRING=mssql\+pyodbc://sa:\$\{SQL_SERVER_PASSWORD\}@database:1433/MusicLibrary", "SQL_SERVER_CONNECTION_STRING=${connectionString}"
$nodeConnectionString = "mssql://${sqlAdminUser}:${plainTextPassword}@${sqlServerName}.database.windows.net:1433/${sqlDbName}"
$dockerComposeContent = $dockerComposeContent -replace "SQL_SERVER_CONNECTION_STRING=mssql://sa:\$\{SQL_SERVER_PASSWORD\}@database:1433/MusicLibrary", "SQL_SERVER_CONNECTION_STRING=${nodeConnectionString}"
Set-Content -Path ".\docker-compose.azure.yml" -Value $dockerComposeContent

# Build and push the Docker images
Write-Host "`nBuilding and pushing Docker images to Azure Container Registry..."

# Build and push Flask backend
Write-Host "Building Flask backend..."
docker build -f ./frontend/backend/Dockerfile.sqlserver -t ${registryName}.azurecr.io/flask-backend:latest ./frontend/backend
docker push ${registryName}.azurecr.io/flask-backend:latest

# Build and push Node backend
Write-Host "Building Node.js backend..."
docker build -f ./frontend/backend/Dockerfile.node -t ${registryName}.azurecr.io/node-backend:latest ./frontend/backend
docker push ${registryName}.azurecr.io/node-backend:latest

# Check if SSL certificates exist
Write-Host "Checking for SSL certificates..."
if (-not (Test-Path "./ssl/certificate.crt") -or -not (Test-Path "./ssl/private.key") -or -not (Test-Path "./ssl/cert.pfx")) {
    Write-Host "SSL certificates not found or incomplete. Running SSL setup script..."
    # Run the SSL setup script
    ./setup-ssl.ps1
    
    if (-not (Test-Path "./ssl/certificate.crt") -or -not (Test-Path "./ssl/cert.pfx")) {
        Write-Host "Error: SSL certificates still not found after running setup script." -ForegroundColor Red
        Write-Host "Please run setup-ssl.ps1 manually and try again." -ForegroundColor Red
        exit 1
    }
}

# Copy SSL certificates to frontend folder
Write-Host "Copying SSL certificates to frontend folder..."
if (-not (Test-Path "./frontend/ssl")) {
    New-Item -Path "./frontend/ssl" -ItemType Directory | Out-Null
}
Copy-Item -Path "./ssl/certificate.crt" -Destination "./frontend/ssl/" -Force
Copy-Item -Path "./ssl/private.key" -Destination "./frontend/ssl/" -Force

# Build and push frontend with HTTPS configuration
Write-Host "Building frontend with HTTPS support..."
docker build -f ./frontend/Dockerfile.https -t ${registryName}.azurecr.io/frontend:latest ./frontend
docker push ${registryName}.azurecr.io/frontend:latest

# Deploy container apps
Write-Host "`nDeploying container apps to Azure..."

# Deploy Flask backend
Write-Host "Deploying Flask backend..."
az containerapp create `
  --name flask-backend `
  --resource-group $resourceGroup `
  --environment "mpp-environment" `
  --image ${registryName}.azurecr.io/flask-backend:latest `
  --target-port 5000 `
  --ingress internal `
  --env-vars SQL_SERVER_CONNECTION_STRING=$connectionString `
  --registry-server "${registryName}.azurecr.io"

# Deploy Node.js backend
Write-Host "Deploying Node.js backend..."
az containerapp create `
  --name node-backend `
  --resource-group $resourceGroup `
  --environment "mpp-environment" `
  --image ${registryName}.azurecr.io/node-backend:latest `
  --target-port 3000 `
  --ingress internal `
  --env-vars SQL_SERVER_CONNECTION_STRING=$nodeConnectionString `
  --registry-server "${registryName}.azurecr.io"

# Deploy frontend
Write-Host "Deploying frontend..."
az containerapp create `
  --name frontend `
  --resource-group $resourceGroup `
  --environment "mpp-environment" `
  --image ${registryName}.azurecr.io/frontend:latest `
  --target-port 443 `
  --ingress external `
  --registry-server "${registryName}.azurecr.io"

# Get the frontend URL
$frontendUrl = az containerapp show `
  --name frontend `
  --resource-group $resourceGroup `
  --query properties.configuration.ingress.fqdn `
  -o tsv

Write-Host "`n======== Deployment Complete ========"
Write-Host "Your application is now deployed to Azure!"
Write-Host "Frontend URL: https://$frontendUrl"
Write-Host "======================================"
