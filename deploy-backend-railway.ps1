Write-Host "Deploying SQL Server and Flask Backend to Railway" -ForegroundColor Green

# First, deploy SQL Server
Write-Host "Deploying SQL Server..." -ForegroundColor Yellow
$env:RAILWAY_CONFIG_FILE = "railway-database.json"
railway up --service sql-server --detach

# Wait for SQL Server to be ready
Write-Host "Waiting for SQL Server to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Deploy Flask Backend
Write-Host "Deploying Flask Backend..." -ForegroundColor Yellow
$env:RAILWAY_CONFIG_FILE = "railway-backend.json"
railway up --service flask-backend --detach

# Get the deployment URLs
Write-Host "Getting deployment URLs..." -ForegroundColor Yellow
$sqlServerUrl = railway service show sql-server --json | ConvertFrom-Json | Select-Object -ExpandProperty domain
$flaskUrl = railway service show flask-backend --json | ConvertFrom-Json | Select-Object -ExpandProperty domain

Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "SQL Server URL: $sqlServerUrl" -ForegroundColor Cyan
Write-Host "Flask Backend URL: $flaskUrl" -ForegroundColor Cyan

# Save URLs to a config file
@"
{
    "FLASK_API_URL": "https://$flaskUrl",
    "SQL_SERVER_URL": "https://$sqlServerUrl"
}
"@ | Out-File -FilePath "backend-urls.json" -Encoding UTF8
