# Comprehensive Railway deployment script for Windows
# Fixes "Is a directory (os error 21)" error

# Set error action preference
$ErrorActionPreference = "Stop"

# Function for colored messages
function Write-ColorMessage {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

try {
    # Display banner
    Write-ColorMessage "=======================================" "Cyan"
    Write-ColorMessage "  COMPREHENSIVE RAILWAY DEPLOYMENT FIX " "Cyan"
    Write-ColorMessage "=======================================" "Cyan"
    Write-Host ""

    # STEP 1: Ensure we have no directory conflicts
    Write-ColorMessage "STEP 1: Checking for directory conflicts..." "Yellow"

    # Check for top-level app directory (Nixpacks default output)
    if (Test-Path -Path "app") {
        if (Test-Path -Path "app" -PathType Container) {
            $timestamp = Get-Date -Format "yyyyMMddHHmmss"
            $newName = "app_folder_$timestamp"
            Write-ColorMessage "Found 'app' directory at project root!" "Red"
            Write-ColorMessage "Renaming to '$newName'..." "Yellow"
            Rename-Item -Path "app" -NewName $newName -Force
            Write-ColorMessage "[OK] Directory renamed successfully" "Green"
        } else {
            Write-ColorMessage "WARNING: 'app' is a file, not a directory" "Yellow"
            Rename-Item -Path "app" -NewName "app.bak$(Get-Date -Format 'yyyyMMddHHmmss')" -Force
            Write-ColorMessage "[OK] File renamed" "Green"
        }
    } else {
        Write-ColorMessage "No top-level 'app' directory found." "Green"
    }

    # STEP 2: Create proper Railway configuration
    Write-Host ""
    Write-ColorMessage "STEP 2: Creating proper Railway configuration..." "Yellow"

    # Create clean railway.json
    $railwayJson = @'
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "NIXPACKS",
    "nixpacksConfigPath": "deploy-nixpacks.toml",
    "buildCommand": "bash ./pre-deploy-clean2.sh"
  },
  "deploy": {
    "numReplicas": 1,
    "startCommand": "cd $PROJECT_DIR && node railway-up-clean2.js",
    "healthcheckPath": "/",
    "healthcheckTimeout": 100,
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 5,
    "sleepApplication": false
  }
}
'@
    Set-Content -Path "railway.json" -Value $railwayJson
    Write-ColorMessage "[OK] Created clean railway.json" "Green"

    # Create better .railwayignore
    $railwayIgnore = @'
# Comprehensive .railwayignore file
# Prevents conflicts with 'app' directories during deployment

# Ignore node_modules to prevent app directory conflicts
node_modules/

# Explicitly ignore all backup directories and files
**/*_backup_*
**/*_bak_*
**/*.bak

# Ignore any app directories that might cause conflicts
**/app/
app/

# Ignore dev files not needed in production
**/.git/
**/.vscode/
**/__pycache__/
**/.pytest_cache/
**/.DS_Store
**/*.log
**/*.md
**/*.ps1
**/*.bat

# Ignore old deployment scripts
deploy-*.sh
*-deploy.sh
*-deploy.ps1
Fixed-*.ps1
Run-*.ps1
Check-*.ps1
'@
    Set-Content -Path ".railwayignore" -Value $railwayIgnore
    Write-ColorMessage "[OK] Created comprehensive .railwayignore" "Green"

    # Mark shell script as executable (in Git)
    git update-index --chmod=+x pre-deploy-clean2.sh
    Write-ColorMessage "[OK] Made pre-deploy-clean2.sh executable in Git" "Green"

    # STEP 3: Deploy to Railway
    Write-Host ""
    Write-ColorMessage "STEP 3: Ready to deploy" "Yellow"
    Write-ColorMessage "All files have been prepared. Ready to deploy to Railway." "White"
    Write-Host ""
    $deployNow = Read-Host "Do you want to deploy to Railway now? (y/n)"

    if ($deployNow -eq "y") {
        Write-ColorMessage "Deploying to Railway..." "Cyan"
        railway up

        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-ColorMessage "✓ Deployment succeeded! Your app should now be available on Railway." "Green"
        } else {
            Write-Host ""
            Write-ColorMessage "× Deployment failed. Please check the error message above." "Red"
        }
    } else {
        Write-Host ""
        Write-ColorMessage "Deployment skipped. To deploy manually, run: railway up" "Yellow"
    }

    Write-Host ""
    Write-ColorMessage "=======================================" "Cyan"
    Write-ColorMessage "  RAILWAY DEPLOYMENT SCRIPT COMPLETE   " "Cyan"
    Write-ColorMessage "=======================================" "Cyan"
}
catch {
    Write-ColorMessage "ERROR: $_" "Red"    Write-ColorMessage "Stack trace: $($_.ScriptStackTrace)" "Red"
    exit 1
}
