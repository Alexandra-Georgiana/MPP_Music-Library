# Deploy to Heroku
Write-Host "Deploying to Heroku..." -ForegroundColor Yellow

# Make sure we're in the right directory
Set-Location D:\MPP

# Check if git is initialized
if (-not (Test-Path .git)) {
    Write-Host "Initializing git repository..." -ForegroundColor Yellow
    git init
    git add .
    git commit -m "Initial commit"
}

# Login to Heroku if not already logged in
$loginStatus = heroku auth:whoami 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Please log in to Heroku..." -ForegroundColor Yellow
    heroku login
}

# Create Heroku apps if they don't exist
$appName = "mpp-music-library"
$dbAppName = "mpp-music-library-db"

Write-Host "Creating Heroku apps..." -ForegroundColor Yellow
heroku apps:create $appName --stack container
heroku apps:create $dbAppName --stack container

# Add SQL Server addon
Write-Host "Adding SQL Server addon..." -ForegroundColor Yellow
heroku addons:create jawsdb-mssql:kitefin --app $appName

# Set environment variables
Write-Host "Setting environment variables..." -ForegroundColor Yellow
heroku config:set --app $appName FLASK_APP=app.py
heroku config:set --app $appName FLASK_ENV=production

# Deploy the applications
Write-Host "Deploying applications..." -ForegroundColor Yellow

# Initialize git if not already done
if (-not (Test-Path .git)) {
    git init
    git add .
    git commit -m "Initial commit"
}

# Add Heroku remotes
git remote add heroku https://git.heroku.com/$appName.git
git remote add heroku-db https://git.heroku.com/$dbAppName.git

# Push to Heroku
git push heroku main
git push heroku-db main

Write-Host "Deployment complete!" -ForegroundColor Green
Write-Host "Main app URL: https://$appName.herokuapp.com" -ForegroundColor Cyan
Write-Host "Database URL: https://$dbAppName.herokuapp.com" -ForegroundColor Cyan
