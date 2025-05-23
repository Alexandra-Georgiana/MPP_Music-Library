# Clean deployment script for Railway
# Fixes "Is a directory (os error 21)" error and cleans up deployment files

$ErrorActionPreference = "Stop"

# Banner function
function Write-Banner {
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "  RAILWAY CLEAN DEPLOYMENT              " -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
}

# Message function
function Write-Message {
    param(
        [string]$Message,
        [string]$Type = "Info"
    )
    
    switch ($Type) {
        "Info"    { Write-Host "INFO: $Message" -ForegroundColor White }
        "Success" { Write-Host "SUCCESS: $Message" -ForegroundColor Green }
        "Warning" { Write-Host "WARNING: $Message" -ForegroundColor Yellow }
        "Error"   { Write-Host "ERROR: $Message" -ForegroundColor Red }
    }
}

try {
    Write-Banner
    
    # Step 1: Create deployment_backups folder
    Write-Message "Creating backup folder for unused deployment files..."
    if (-not (Test-Path -Path "deployment_backups")) {
        New-Item -Path "deployment_backups" -ItemType Directory -Force | Out-Null
    }
    
    # Step 2: Apply the fixes for the directory conflict
    Write-Message "Fixing directory conflict issues..."
    
    # Use clean pre-deploy script
    if (Test-Path -Path "pre-deploy-clean.sh") {
        Write-Message "Using clean pre-deploy script..."
        Copy-Item -Path "pre-deploy-clean.sh" -Destination "pre-deploy.sh" -Force
        Write-Message "Copied pre-deploy-clean.sh to pre-deploy.sh" -Type "Success"
    }
    
    # Use clean .railwayignore
    if (Test-Path -Path ".railwayignore-clean") {
        Write-Message "Using clean .railwayignore..."
        Copy-Item -Path ".railwayignore-clean" -Destination ".railwayignore" -Force
        Write-Message "Copied .railwayignore-clean to .railwayignore" -Type "Success"
    }
    
    # Use clean railway-up.js
    if (Test-Path -Path "railway-up-clean.js") {
        Write-Message "Using clean railway-up.js..."
        Copy-Item -Path "railway-up-clean.js" -Destination "railway-up.js" -Force
        Write-Message "Copied railway-up-clean.js to railway-up.js" -Type "Success"
    }
    
    # Use clean railway.json
    if (Test-Path -Path "railway-clean.json") {
        Write-Message "Using clean railway.json..."
        Copy-Item -Path "railway-clean.json" -Destination "railway.json" -Force
        Write-Message "Copied railway-clean.json to railway.json" -Type "Success"
    }
    
    # Fix deploy-nixpacks.toml if needed
    if (Test-Path -Path "deploy-nixpacks.toml") {
        Write-Message "Checking deploy-nixpacks.toml for output setting..."
        $nixpacksContent = Get-Content -Path "deploy-nixpacks.toml" -Raw
        
        if ($nixpacksContent -notmatch "output\s*=") {
            Write-Message "Adding output setting to deploy-nixpacks.toml..."
            $updatedContent = $nixpacksContent + "`n[phases.build]`noutput = `"railway-app`"`n"
            Set-Content -Path "deploy-nixpacks.toml" -Value $updatedContent -Force
            Write-Message "Added output setting to deploy-nixpacks.toml" -Type "Success"
        } else {
            Write-Message "deploy-nixpacks.toml already has output setting" -Type "Success"
        }
    }
    
    # Check for app directory
    if (Test-Path -Path "app" -PathType Container) {
        $timestamp = Get-Date -Format "yyyyMMddHHmmss"
        $newName = "app_backup_$timestamp"
        Write-Message "Found 'app' directory which conflicts with deployment!" -Type "Warning"
        Write-Message "Renaming 'app' to '$newName'..."
        Rename-Item -Path "app" -NewName $newName -Force
        Write-Message "Renamed 'app' directory to '$newName'" -Type "Success"
    }
    
    # Step 3: Deploy to Railway
    Write-Message "Ready to deploy to Railway..."
    Write-Host ""
    $deploy = Read-Host "Do you want to deploy now? (y/n)"
    
    if ($deploy -eq "y" -or $deploy -eq "Y") {
        Write-Message "Deploying to Railway..."
        railway up
        
        if ($LASTEXITCODE -eq 0) {
            Write-Message "Deployment successful!" -Type "Success"
        } else {
            Write-Message "Deployment failed. Check the output above for errors." -Type "Error"
        }
    } else {
        Write-Message "Deployment skipped. Run 'railway up' to deploy when ready." -Type "Warning"
    }
} catch {
    Write-Message "An error occurred: $_" -Type "Error"
    exit 1
}
