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
            Rename-Item -Path "app" -NewName "app.bak" -Force
            Write-ColorMessage "[OK] File renamed" "Green"
        }
    } else {
        Write-ColorMessage "No top-level 'app' directory found." "Green"
    }

    # STEP 2: Deploy to Railway
    Write-ColorMessage "STEP 2: Deploying to Railway..." "Yellow"
    railway up

    if ($LASTEXITCODE -eq 0) {
        Write-ColorMessage "Deployment succeeded!" "Green"
    } else {
        Write-ColorMessage "Deployment failed with exit code $LASTEXITCODE" "Red"
    }

} catch {
    Write-ColorMessage "ERROR: $_" "Red"
    exit 1
}
