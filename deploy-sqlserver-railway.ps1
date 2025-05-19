# Deploy Music Player Project to Railway with SQL Server

Write-Host "Deploying Music Player Project to Railway with SQL Server configuration..." -ForegroundColor Cyan

# Verify pre-deploy script is executable
if (Test-Path ./pre-deploy.sh) {
    Write-Host "Ensuring pre-deploy.sh is executable..." -ForegroundColor Yellow
    # In Windows, you can't directly chmod, but we're preparing for Railway which is Linux-based
    git update-index --chmod=+x ./pre-deploy.sh
}

# Check Railway CLI
if (-not (Get-Command railway -ErrorAction SilentlyContinue)) {
    Write-Host "Railway CLI not found. Installing..." -ForegroundColor Yellow
    npm install -g @railway/cli
}

# Verify the Repository.py.railway file exists
if (-not (Test-Path ./frontend/backend/Repository.py.railway)) {
    Write-Host "Error: Repository.py.railway file missing!" -ForegroundColor Red
    Write-Host "Please ensure the Railway-specific version of Repository.py exists." -ForegroundColor Red
    exit 1
}

# Verify the server.js.railway file exists
if (-not (Test-Path ./frontend/backend/server.js.railway)) {
    Write-Host "Error: server.js.railway file missing!" -ForegroundColor Red
    Write-Host "Please ensure the Railway-specific version of server.js exists." -ForegroundColor Red
    exit 1
}

# Link to Railway project
Write-Host "Linking to Railway project..." -ForegroundColor Yellow
railway link
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to link to Railway project. You may need to create a project first." -ForegroundColor Red
    exit 1
}

# Deploy to Railway
Write-Host "Deploying to Railway..." -ForegroundColor Cyan
railway up
if ($LASTEXITCODE -ne 0) {
    Write-Host "Deployment failed!" -ForegroundColor Red
    exit 1
}

Write-Host "Running database initialization script..." -ForegroundColor Yellow
railway run "python frontend/backend/init_railway_db.py"

Write-Host "Deployment completed successfully!" -ForegroundColor Green
Write-Host "Your application is now running on Railway with SQL Server." -ForegroundColor Green
Write-Host "Use 'railway open' to open the application." -ForegroundColor Cyan
