# PowerShell script to deploy to Railway for SQL Server deployment

Write-Host "Deploying Music Player Project to Railway..." -ForegroundColor Cyan

# Check if Railway CLI is installed
try {
    $railwayVersion = railway version
    Write-Host "Railway CLI detected: $railwayVersion" -ForegroundColor Green
} catch {
    Write-Host "Railway CLI not found. Installing..." -ForegroundColor Yellow
    npm install -g @railway/cli
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to install Railway CLI. Please install manually with: npm install -g @railway/cli" -ForegroundColor Red
        exit 1
    }
}

# Login to Railway if needed
Write-Host "Checking Railway authentication..." -ForegroundColor Cyan
$loggedIn = $false
try {
    $status = railway status
    if ($status -match "Logged in") {
        $loggedIn = $true
        Write-Host "Already logged in to Railway" -ForegroundColor Green
    }
} catch {
    $loggedIn = $false
}

if (-not $loggedIn) {
    Write-Host "Please log in to Railway:" -ForegroundColor Yellow
    railway login
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to log in to Railway. Exiting." -ForegroundColor Red
        exit 1
    }
}

# Link to an existing project if not already linked
Write-Host "Checking Railway project link..." -ForegroundColor Cyan
$linked = $false
try {
    $project = railway project
    if ($project -match "Project:") {
        $linked = $true
        Write-Host "Already linked to Railway project: $project" -ForegroundColor Green
    }
} catch {
    $linked = $false
}

if (-not $linked) {
    Write-Host "Linking to Railway project..." -ForegroundColor Yellow
    railway link
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to link to Railway project. You may need to create a new project first." -ForegroundColor Red
        $createNew = Read-Host "Create a new project? (y/n)"
        if ($createNew -eq "y") {
            railway project create
            railway link
        } else {
            exit 1
        }
    }
}

# Verify configuration before deployment
Write-Host "Verifying deployment configuration..." -ForegroundColor Cyan

# Check if deployment files exist
$requiredFiles = @(
    "railway.json", 
    "railway.toml", 
    "deploy-nixpacks.toml", 
    "pre-deploy.sh",
    "frontend/backend/Repository.py.railway"
)

$missingFiles = @()
foreach ($file in $requiredFiles) {
    if (-not (Test-Path -Path $file)) {
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host "Missing required files: $($missingFiles -join ', ')" -ForegroundColor Red
    Write-Host "Please create these files before deploying." -ForegroundColor Yellow
    exit 1
}

# Verify Repository.py.railway contains RAILWAY_DATABASE settings
$repoFileContent = Get-Content -Path "frontend/backend/Repository.py.railway" -Raw
if ($repoFileContent -notmatch "RAILWAY_DATABASE_HOST") {
    Write-Host "Warning: Repository.py.railway may not be properly configured for Railway SQL Server." -ForegroundColor Yellow
    $continue = Read-Host "Continue anyway? (y/n)"
    if ($continue -ne "y") {
        exit 1
    }
}

# Make pre-deploy.sh executable
if (Test-Path -Path "pre-deploy.sh") {
    git update-index --chmod=+x pre-deploy.sh
    Write-Host "Made pre-deploy.sh executable" -ForegroundColor Green
}

# Deploy to Railway
Write-Host "Deploying to Railway..." -ForegroundColor Cyan
railway up

Write-Host "Deployment completed!" -ForegroundColor Green
Write-Host "Now initializing database..." -ForegroundColor Cyan

# Initialize the database
Write-Host "Running database initialization..." -ForegroundColor Cyan
railway run "python frontend/backend/init_railway_db.py"

Write-Host "Setup completed! Your application should be available on Railway." -ForegroundColor Green
