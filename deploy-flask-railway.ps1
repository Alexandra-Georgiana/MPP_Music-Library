# Deploy Flask backend to Railway and connect to Azure SQL Server
Write-Host "Deploying Flask Backend to Railway..." -ForegroundColor Green

# First, check if we have the Azure SQL config
if (-not (Test-Path "azure-sql-config.json")) {
    Write-Host "ERROR: azure-sql-config.json not found. Please run deploy-sqlserver-azure.ps1 first." -ForegroundColor Red
    exit 1
}

# Read Azure SQL configuration
$config = Get-Content "azure-sql-config.json" | ConvertFrom-Json

# Set Railway environment variables
Write-Host "Setting Railway environment variables..." -ForegroundColor Yellow
railway variables set SQL_SERVER_HOST="$($config.SQL_SERVER_HOST)"
railway variables set SQL_SERVER_DATABASE="$($config.SQL_SERVER_DATABASE)"
railway variables set SQL_SERVER_USERNAME="$($config.SQL_SERVER_USERNAME)"
railway variables set SQL_SERVER_PASSWORD="$($config.SQL_SERVER_PASSWORD)"
railway variables set FLASK_ENV="production"
railway variables set FLASK_APP="app.py"

# Deploy Flask backend
Write-Host "Deploying Flask backend..." -ForegroundColor Yellow
railway up --service flask-backend

# Get the deployment URL
Write-Host "Getting deployment URL..." -ForegroundColor Yellow
$flaskUrl = railway service show flask-backend --json | ConvertFrom-Json | Select-Object -ExpandProperty domain

# Save Flask backend URL to config
@"
{
    "FLASK_API_URL": "https://$flaskUrl"
}
"@ | Out-File -FilePath "backend-urls.json" -Encoding UTF8

Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "Flask Backend URL: https://$flaskUrl" -ForegroundColor Cyan
Write-Host "Configuration saved to backend-urls.json" -ForegroundColor Cyan
