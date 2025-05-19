# Railway Deployment Script for Music Player Project

# Display banner
Write-Host "`n===============================================" -ForegroundColor Cyan
Write-Host "  Music Player Project - Railway Deployment" -ForegroundColor Cyan
Write-Host "===============================================`n" -ForegroundColor Cyan

# Step 1: Check if Railway CLI is installed
$railwayInstalled = $null
try {
    $railwayInstalled = Get-Command railway -ErrorAction SilentlyContinue
}
catch {
    $railwayInstalled = $null
}

if (-not $railwayInstalled) {
    Write-Host "Railway CLI not found. Installing..." -ForegroundColor Yellow
    npm i -g @railway/cli
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to install Railway CLI. Please install it manually with 'npm i -g @railway/cli'" -ForegroundColor Red
        exit 1
    }
}

# Step 2: Login to Railway
Write-Host "`nStep 2: Logging in to Railway..." -ForegroundColor Yellow
Write-Host "Please follow the prompt to log in to your Railway account." -ForegroundColor Yellow
railway login
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to log in to Railway. Please try again." -ForegroundColor Red
    exit 1
}

# Step 3: Link to an existing Railway project or create a new one
Write-Host "`nStep 3: Setting up Railway project..." -ForegroundColor Yellow

# Check if already linked to a project
$projectLinked = railway project
if ($LASTEXITCODE -ne 0) {
    # Ask user if they want to create a new project or link to existing
    $projectChoice = Read-Host "Do you want to create a new Railway project? (y/n)"
    if ($projectChoice -eq "y") {
        Write-Host "Creating a new Railway project..." -ForegroundColor Yellow
        railway project create
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Failed to create Railway project." -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "Linking to an existing Railway project..." -ForegroundColor Yellow
        railway link
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Failed to link to Railway project." -ForegroundColor Red
            exit 1
        }
    }
}

# Step 4: Set up environment variables
Write-Host "`nStep 4: Setting up environment variables..." -ForegroundColor Yellow
railway variables set FLASK_ENV=production
railway variables set NODE_ENV=production
railway variables set USE_HTTPS=false
railway variables set JWT_SECRET_KEY=$(Get-Random)

# Set cross-service URL environment variables (will be filled automatically by Railway)
Write-Host "Setting up cross-service communication variables..." -ForegroundColor Yellow
railway variables set --service frontend VITE_API_URL='${RAILWAY_SERVICE_NODE_BACKEND_URL}'
railway variables set --service frontend VITE_FLASK_API_URL='${RAILWAY_SERVICE_FLASK_BACKEND_URL}'
railway variables set --service frontend VITE_APP_ENV=production

# Step 5: Prepare files for Railway
Write-Host "`nStep 5: Preparing files for Railway deployment..." -ForegroundColor Yellow

# Copy Railway-specific files to their destinations
Copy-Item -Path ".\frontend\backend\Repository.py.railway" -Destination ".\frontend\backend\Repository.py" -Force
Copy-Item -Path ".\frontend\backend\server.js.railway" -Destination ".\frontend\backend\server.js" -Force

# Step 6: Deploy to Railway
Write-Host "`nStep 6: Deploying to Railway..." -ForegroundColor Yellow
Write-Host "This may take a few minutes. Please wait..." -ForegroundColor Yellow
railway up
if ($LASTEXITCODE -ne 0) {
    Write-Host "Deployment failed. Please check the error messages above." -ForegroundColor Red
    exit 1
}

# Step 7: Get the deployment URL
Write-Host "`nStep 7: Getting deployment information..." -ForegroundColor Yellow
$deployInfo = railway status

# Done
Write-Host "`n===============================================" -ForegroundColor Green
Write-Host "  Deployment Complete!" -ForegroundColor Green
Write-Host "===============================================`n" -ForegroundColor Green
Write-Host "Your application has been deployed to Railway." -ForegroundColor Cyan
Write-Host "Visit your Railway dashboard to see your application:" -ForegroundColor Yellow
Write-Host "https://railway.app/dashboard" -ForegroundColor White
Write-Host "`nTo set up continuous deployment from GitHub:" -ForegroundColor Yellow
Write-Host "1. Go to your Railway project settings" -ForegroundColor White
Write-Host "2. Connect your GitHub repository" -ForegroundColor White
Write-Host "3. Select the branch to deploy from" -ForegroundColor White
Write-Host "`nIMPORTANT: You may need to run the database migration script:" -ForegroundColor Yellow
Write-Host "railway run python frontend/backend/init_railway_db.py" -ForegroundColor White
