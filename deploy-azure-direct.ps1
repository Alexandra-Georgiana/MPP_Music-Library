# Full Azure Deployment Script (No GitHub Actions)
# This script deploys the entire Music Player Project to Azure
# - Frontend React app
# - Backend services (Flask and/or Node.js)
# - SQL Server database
# All with HTTPS support

#########################################################
# Display banner
#########################################################
function Show-Banner {
    Clear-Host
    Write-Host "`n`n=================================================" -ForegroundColor Cyan
    Write-Host "     MUSIC PLAYER PROJECT - AZURE DEPLOYMENT     " -ForegroundColor Cyan
    Write-Host "         (Direct Deployment, No GitHub)         " -ForegroundColor Cyan 
    Write-Host "=================================================`n" -ForegroundColor Cyan
}

Show-Banner

#########################################################
# Check prerequisites
#########################################################
Write-Host "STEP 1: Checking prerequisites..." -ForegroundColor Yellow

# Check Azure CLI
try {
    $azVersion = (az --version) | Select-Object -First 1
    Write-Host "✓ Azure CLI found: $azVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Azure CLI not found. Please install Azure CLI:" -ForegroundColor Red
    Write-Host "  https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" -ForegroundColor Red
    exit 1
}

# Check Docker
try {
    $dockerVersion = (docker --version)
    Write-Host "✓ Docker found: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker not found. Please install Docker Desktop:" -ForegroundColor Red
    Write-Host "  https://www.docker.com/products/docker-desktop" -ForegroundColor Red
    exit 1
}

# Check Node.js
try {
    $nodeVersion = (node --version)
    Write-Host "✓ Node.js found: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Node.js not found. Please install Node.js:" -ForegroundColor Red
    Write-Host "  https://nodejs.org/" -ForegroundColor Red
    exit 1
}

# Check npm
try {
    $npmVersion = (npm --version)
    Write-Host "✓ npm found: $npmVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ npm not found. Please install npm (comes with Node.js):" -ForegroundColor Red
    Write-Host "  https://nodejs.org/" -ForegroundColor Red
    exit 1
}

#########################################################
# Configuration Variables
#########################################################
Write-Host "`nSTEP 2: Configuring deployment variables..." -ForegroundColor Yellow

# Default values
$defaultResourceGroup = "mpp-resource-group"
$defaultLocation = "eastus"
$defaultSqlDb = "MusicLibrary"
$defaultBackendPort = "5000"

# Get user input or use defaults
$resourceGroupName = Read-Host "Enter resource group name (default: $defaultResourceGroup)"
if ([string]::IsNullOrWhiteSpace($resourceGroupName)) { $resourceGroupName = $defaultResourceGroup }

$location = Read-Host "Enter Azure region (default: $defaultLocation)"
if ([string]::IsNullOrWhiteSpace($location)) { $location = $defaultLocation }

$sqlDbName = Read-Host "Enter SQL database name (default: $defaultSqlDb)"
if ([string]::IsNullOrWhiteSpace($sqlDbName)) { $sqlDbName = $defaultSqlDb }

# Generate unique names for resources
$timestamp = Get-Date -Format "MMddHHmm"
$registryName = "mppregistry$timestamp"
$sqlServerName = "mppsql$timestamp"
$appServicePlan = "mpp-plan-$timestamp"
$webAppName = "mpp-webapp-$timestamp"
$apiAppName = "mpp-api-$timestamp"

# SQL Admin credentials
$sqlAdminUser = "mppadmin"
$sqlAdminPassword = Read-Host "Enter SQL Server admin password" -AsSecureString
$plaintextPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($sqlAdminPassword))

Write-Host "`nDeployment configuration:" -ForegroundColor Cyan
Write-Host "- Resource Group: $resourceGroupName"
Write-Host "- Location: $location"
Write-Host "- Container Registry: $registryName"
Write-Host "- SQL Server: $sqlServerName"
Write-Host "- SQL Database: $sqlDbName"
Write-Host "- Web App Name: $webAppName"
Write-Host "- API App Name: $apiAppName"
Write-Host "- App Service Plan: $appServicePlan"

#########################################################
# Login to Azure
#########################################################
Write-Host "`nSTEP 3: Logging in to Azure..." -ForegroundColor Yellow
az login
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Azure login failed. Please try again." -ForegroundColor Red
    exit 1
}
Write-Host "✓ Successfully logged in to Azure" -ForegroundColor Green

# Select subscription if needed
$subscriptionList = az account list --query "[].{Name:name, ID:id}" -o json | ConvertFrom-Json
if ($subscriptionList.Count -gt 1) {
    Write-Host "`nAvailable subscriptions:" -ForegroundColor Cyan
    for ($i=0; $i -lt $subscriptionList.Count; $i++) {
        Write-Host "[$i] $($subscriptionList[$i].Name) ($($subscriptionList[$i].ID))"
    }
    $subscriptionIndex = Read-Host "`nSelect subscription (enter number)"
    
    if ($subscriptionIndex -ge 0 -and $subscriptionIndex -lt $subscriptionList.Count) {
        $selectedSubscription = $subscriptionList[$subscriptionIndex].ID
        az account set --subscription $selectedSubscription
        Write-Host "Using subscription: $selectedSubscription" -ForegroundColor Green
    } else {
        Write-Host "Invalid selection, using default subscription." -ForegroundColor Yellow
    }
}

#########################################################
# Generate SSL Certificates
#########################################################
Write-Host "`nSTEP 4: Setting up SSL certificates..." -ForegroundColor Yellow
if (-not (Test-Path "./ssl/certificate.crt") -or -not (Test-Path "./ssl/cert.pfx")) {
    Write-Host "Generating new SSL certificates..."
    ./setup-ssl.ps1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "✗ Failed to generate SSL certificates." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "✓ SSL certificates already exist" -ForegroundColor Green
}

#########################################################
# Create Azure Resources
#########################################################
Write-Host "`nSTEP 5: Setting up Azure resources..." -ForegroundColor Yellow

# Create resource group if it doesn't exist
$rgCheck = az group exists --name $resourceGroupName
if ($rgCheck -eq "false") {
    Write-Host "Creating resource group: $resourceGroupName"
    az group create --name $resourceGroupName --location $location
    if ($LASTEXITCODE -ne 0) {
        Write-Host "✗ Failed to create resource group." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "✓ Resource group already exists" -ForegroundColor Green
}

# Create Azure Container Registry
Write-Host "`nCreating container registry: $registryName"
az acr create --resource-group $resourceGroupName --name $registryName --sku Basic --admin-enabled true
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Failed to create container registry." -ForegroundColor Red
    exit 1
}
Write-Host "✓ Container registry created successfully" -ForegroundColor Green

# Get ACR credentials
$acrUsername = az acr credential show --name $registryName --query "username" -o tsv
$acrPassword = az acr credential show --name $registryName --query "passwords[0].value" -o tsv
Write-Host "✓ Retrieved ACR credentials" -ForegroundColor Green

# Create SQL Server
Write-Host "`nCreating SQL Server: $sqlServerName"
az sql server create --name $sqlServerName --resource-group $resourceGroupName --location $location --admin-user $sqlAdminUser --admin-password $plaintextPassword
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Failed to create SQL Server." -ForegroundColor Red
    exit 1
}
Write-Host "✓ SQL Server created successfully" -ForegroundColor Green

# Create SQL Database
Write-Host "Creating SQL Database: $sqlDbName"
az sql db create --resource-group $resourceGroupName --server $sqlServerName --name $sqlDbName --service-objective S0
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Failed to create SQL Database." -ForegroundColor Red
    exit 1
}
Write-Host "✓ SQL Database created successfully" -ForegroundColor Green

# Allow Azure Services to access the SQL Server
Write-Host "Configuring SQL Server firewall..."
az sql server firewall-rule create --resource-group $resourceGroupName --server $sqlServerName --name AllowAzureServices --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Failed to configure SQL Server firewall." -ForegroundColor Red
    exit 1
}
Write-Host "✓ SQL Server firewall configured" -ForegroundColor Green

# Create App Service Plan
Write-Host "`nCreating App Service Plan: $appServicePlan"
az appservice plan create --name $appServicePlan --resource-group $resourceGroupName --sku B1 --is-linux
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Failed to create App Service Plan." -ForegroundColor Red
    exit 1
}
Write-Host "✓ App Service Plan created successfully" -ForegroundColor Green

#########################################################
# Build and Deploy Backend
#########################################################
Write-Host "`nSTEP 6: Building and deploying backend..." -ForegroundColor Yellow

# Login to ACR
Write-Host "Logging in to Azure Container Registry..."
az acr login --name $registryName
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Failed to log in to Azure Container Registry." -ForegroundColor Red
    exit 1
}

# Connection string for SQL Server
$sqlConnString = "mssql+pyodbc://${sqlAdminUser}:${plaintextPassword}@${sqlServerName}.database.windows.net:1433/${sqlDbName}?driver=ODBC+Driver+17+for+SQL+Server"
$nodeSqlConnString = "mssql://${sqlAdminUser}:${plaintextPassword}@${sqlServerName}.database.windows.net:1433/${sqlDbName}"

# Build and push backend Docker image
Write-Host "Building Flask backend Docker image..."
docker build -f ./frontend/backend/Dockerfile.sqlserver -t ${registryName}.azurecr.io/flask-backend:latest ./frontend/backend
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Failed to build Flask backend Docker image." -ForegroundColor Red
    exit 1
}

Write-Host "Pushing Flask backend Docker image to registry..."
docker push ${registryName}.azurecr.io/flask-backend:latest
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Failed to push Flask backend Docker image." -ForegroundColor Red
    exit 1
}

# Create Web App for API
Write-Host "Creating Web App for API: $apiAppName"
az webapp create --resource-group $resourceGroupName --plan $appServicePlan --name $apiAppName --deployment-container-image-name ${registryName}.azurecr.io/flask-backend:latest
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Failed to create API Web App." -ForegroundColor Red
    exit 1
}

# Configure container settings for the API app
az webapp config container set --name $apiAppName --resource-group $resourceGroupName --docker-custom-image-name ${registryName}.azurecr.io/flask-backend:latest --docker-registry-server-url https://${registryName}.azurecr.io --docker-registry-server-user $acrUsername --docker-registry-server-password $acrPassword

# Configure API app settings
Write-Host "Configuring API App settings..."
az webapp config appsettings set --resource-group $resourceGroupName --name $apiAppName --settings SQL_SERVER_CONNECTION_STRING="$sqlConnString" FLASK_ENV="production"

# Enable HTTPS for API app
Write-Host "Enabling HTTPS for API app..."
az webapp update --resource-group $resourceGroupName --name $apiAppName --https-only true

Write-Host "✓ Backend API deployed successfully" -ForegroundColor Green
$apiUrl = "https://${apiAppName}.azurewebsites.net"
Write-Host "API Base URL: $apiUrl"

#########################################################
# Build and Deploy Frontend
#########################################################
Write-Host "`nSTEP 7: Building and deploying frontend..." -ForegroundColor Yellow

# Create a temporary .env file for the frontend build with API URL
Write-Host "Configuring frontend to use deployed API..."
Set-Content -Path "./frontend/.env.production" -Value "VITE_API_BASE_URL=$apiUrl"

# Build the frontend
Write-Host "Installing frontend dependencies..."
Push-Location ./frontend
npm install
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Failed to install frontend dependencies." -ForegroundColor Red
    Pop-Location
    exit 1
}

Write-Host "Building frontend..."
npm run build
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Failed to build frontend." -ForegroundColor Red
    Pop-Location
    exit 1
}
Pop-Location

# Copy SSL certificates to frontend/dist
if (-not (Test-Path "./frontend/dist/ssl")) {
    New-Item -Path "./frontend/dist/ssl" -ItemType Directory | Out-Null
}
Copy-Item -Path "./ssl/certificate.crt" -Destination "./frontend/dist/ssl/" -Force
Copy-Item -Path "./ssl/private.key" -Destination "./frontend/dist/ssl/" -Force

# Create nginx configuration for Azure Web App
$nginxConfig = @"
server {
    listen 8080;
    
    location / {
        root /home/site/wwwroot;
        index index.html index.htm;
        try_files \$uri \$uri/ /index.html;
    }
    
    location /api {
        proxy_pass $apiUrl;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
"@
Set-Content -Path "./frontend/dist/nginx.conf" -Value $nginxConfig

# Create Dockerfile for the frontend deployment
$frontendDockerfile = @"
FROM nginx:alpine
COPY . /home/site/wwwroot
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
"@
Set-Content -Path "./frontend/dist/Dockerfile" -Value $frontendDockerfile

# Build and push frontend Docker image
Write-Host "Building frontend Docker image..."
docker build -t ${registryName}.azurecr.io/frontend:latest ./frontend/dist
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Failed to build frontend Docker image." -ForegroundColor Red
    exit 1
}

Write-Host "Pushing frontend Docker image to registry..."
docker push ${registryName}.azurecr.io/frontend:latest
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Failed to push frontend Docker image." -ForegroundColor Red
    exit 1
}

# Create Web App for frontend
Write-Host "Creating Web App for frontend: $webAppName"
az webapp create --resource-group $resourceGroupName --plan $appServicePlan --name $webAppName --deployment-container-image-name ${registryName}.azurecr.io/frontend:latest
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Failed to create frontend Web App." -ForegroundColor Red
    exit 1
}

# Configure container settings for the frontend app
az webapp config container set --name $webAppName --resource-group $resourceGroupName --docker-custom-image-name ${registryName}.azurecr.io/frontend:latest --docker-registry-server-url https://${registryName}.azurecr.io --docker-registry-server-user $acrUsername --docker-registry-server-password $acrPassword

# Enable HTTPS for frontend
Write-Host "Enabling HTTPS for frontend app..."
az webapp update --resource-group $resourceGroupName --name $webAppName --https-only true

# Get the frontend URL
$frontendUrl = "https://${webAppName}.azurewebsites.net"
Write-Host "✓ Frontend deployed successfully" -ForegroundColor Green
Write-Host "Frontend URL: $frontendUrl"

#########################################################
# SSL Configuration for Azure Web Apps
#########################################################
Write-Host "`nSTEP 8: Configuring SSL for Azure Web Apps..." -ForegroundColor Yellow

# Import SSL certificate to Azure
$pfxPath = "./ssl/cert.pfx"
$pfxPassword = "password123"  # From setup-ssl.ps1

Write-Host "Importing SSL certificate to Azure..."
$thumbprint = az webapp config ssl import --resource-group $resourceGroupName `
                --name $webAppName `
                --key-vault $resourceGroupName `
                --key-vault-certificate-name "mpp-cert" `
                --query thumbprint -o tsv

if ($LASTEXITCODE -ne 0) {
    Write-Host "NOTE: Could not import SSL certificate directly. Will use Azure's managed certificates instead." -ForegroundColor Yellow
    Write-Host "      The application will still be served over HTTPS." -ForegroundColor Yellow
} else {
    Write-Host "Binding SSL certificate to web apps..."
    az webapp config ssl bind --resource-group $resourceGroupName --name $webAppName --certificate-thumbprint $thumbprint --ssl-type SNI
    az webapp config ssl bind --resource-group $resourceGroupName --name $apiAppName --certificate-thumbprint $thumbprint --ssl-type SNI
    Write-Host "✓ SSL certificate bound to web apps" -ForegroundColor Green
}

#########################################################
# Create deployment output file
#########################################################
Write-Host "`nSTEP 9: Creating deployment output file..." -ForegroundColor Yellow

$deploymentOutput = @{
    resourceGroup = $resourceGroupName
    frontendUrl = $frontendUrl
    apiUrl = $apiUrl
    dbServer = "${sqlServerName}.database.windows.net"
    dbName = $sqlDbName
    dbUser = $sqlAdminUser
    timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
}

$deploymentOutputJson = $deploymentOutput | ConvertTo-Json
Set-Content -Path "./azure-deployment-output.json" -Value $deploymentOutputJson
Write-Host "✓ Deployment output saved to azure-deployment-output.json" -ForegroundColor Green

#########################################################
# Display completion message
#########################################################
Write-Host "`n`n===============================================" -ForegroundColor Green
Write-Host "     DEPLOYMENT COMPLETED SUCCESSFULLY!     " -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green

Write-Host "`nYour application is now accessible at:" -ForegroundColor Cyan
Write-Host "Frontend URL:  $frontendUrl" -ForegroundColor White
Write-Host "API Base URL:  $apiUrl" -ForegroundColor White

Write-Host "`nDatabase Connection Information:" -ForegroundColor Cyan
Write-Host "Server:       ${sqlServerName}.database.windows.net" -ForegroundColor White
Write-Host "Database:     $sqlDbName" -ForegroundColor White
Write-Host "Username:     $sqlAdminUser" -ForegroundColor White

Write-Host "`nIMPORTANT: Make sure to update environment variables in your apps if needed." -ForegroundColor Yellow
Write-Host "For specific connection issues, see the DEPLOYMENT_GUIDE_ENHANCED.md file." -ForegroundColor Yellow

# Write a checkmark emoji for successful deployment
Write-Host "`n✅ Your application is now deployed on Azure without GitHub Actions!" -ForegroundColor Green
