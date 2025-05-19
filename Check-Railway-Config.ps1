# Check-Railway-Config.ps1
# Validates Railway deployment configuration files

$ErrorActionPreference = "Stop"

Write-Host "Checking Railway deployment configuration..." -ForegroundColor Cyan

$requiredFiles = @(
    "railway.json",
    "railway.toml",
    "nixpacks.toml",
    "deploy-nixpacks.toml",
    "pre-deploy.sh",
    "Procfile",
    "package.json",
    "railway-up.js",
    "frontend/backend/Repository.py.railway",
    "frontend/backend/server.js.railway"
)

Write-Host "`nVerifying required files exist:" -ForegroundColor Yellow
$missingFiles = @()
foreach ($file in $requiredFiles) {
    $exists = Test-Path -Path $file
    $status = if ($exists) { "✓" } else { "✗" }
    $color = if ($exists) { "Green" } else { "Red" }
    Write-Host "  $status $file" -ForegroundColor $color
    
    if (-not $exists) {
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host "`nMissing files: $($missingFiles -join ', ')" -ForegroundColor Red
    Write-Host "Please create these files before deploying." -ForegroundColor Yellow
}

Write-Host "`nChecking configurations for Railway SQL Server deployment:" -ForegroundColor Yellow

# Check railway.toml for SQL Server service
$railwayToml = Get-Content -Path "railway.toml" -Raw
if ($railwayToml -match '\[\[services\]\]\s+name\s+=\s+"sqlserver"') {
    Write-Host "  ✓ SQL Server service defined in railway.toml" -ForegroundColor Green
} else {
    Write-Host "  ✗ SQL Server service not properly defined in railway.toml" -ForegroundColor Red
}

# Check Repository.py.railway for SQL Server connection
$repositoryRailway = Get-Content -Path "frontend/backend/Repository.py.railway" -Raw
if ($repositoryRailway -match "RAILWAY_DATABASE_HOST") {
    Write-Host "  ✓ Repository.py.railway contains RAILWAY_DATABASE_HOST reference" -ForegroundColor Green
} else {
    Write-Host "  ✗ Repository.py.railway might not be properly configured for Railway SQL Server" -ForegroundColor Red
}

# Check nixpacks config
$nixpacks = Get-Content -Path "deploy-nixpacks.toml" -Raw
if ($nixpacks -match "unixODBC" -and $nixpacks -match "unixODBCDrivers") {
    Write-Host "  ✓ deploy-nixpacks.toml includes ODBC drivers" -ForegroundColor Green
} else {
    Write-Host "  ✗ deploy-nixpacks.toml might be missing ODBC drivers" -ForegroundColor Red
}

Write-Host "`nChecking start commands:" -ForegroundColor Yellow

# Check railway.json start command
$railwayJson = Get-Content -Path "railway.json" -Raw | ConvertFrom-Json
if ($railwayJson.deploy.startCommand -eq "npm start") {
    Write-Host "  ✓ railway.json uses 'npm start' as the start command" -ForegroundColor Green
} else {
    Write-Host "  ✗ railway.json start command is not 'npm start'" -ForegroundColor Red
}

# Check package.json start script
$packageJson = Get-Content -Path "package.json" -Raw | ConvertFrom-Json
if ($packageJson.scripts.start -eq "node railway-up.js") {
    Write-Host "  ✓ package.json has correct 'start' script" -ForegroundColor Green
} else {
    Write-Host "  ✗ package.json 'start' script is not properly configured" -ForegroundColor Red
}

Write-Host "`nConfiguration check completed!" -ForegroundColor Cyan
