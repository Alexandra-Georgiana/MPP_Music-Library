# Simple Railway deployment script
# This script prepares the environment and deploys to Railway
# Includes comprehensive fixes for "Is a directory (os error 21)" error

# Set error action preference
$ErrorActionPreference = "Stop"

# Function to show colored messages
function Write-ColorMessage {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

try {
    # Display banner
    Write-ColorMessage "========================================" "Cyan"
    Write-ColorMessage "  RAILWAY DEPLOYMENT WITH ERROR FIXES   " "Cyan"  
    Write-ColorMessage "========================================" "Cyan"

    # Create uploads directory if needed
    Write-ColorMessage "Checking directory structure..." "Yellow"
    if (-not (Test-Path -Path "frontend/backend/uploads")) {
        Write-ColorMessage "Creating uploads directory..." "Yellow"
        New-Item -Path "frontend/backend/uploads" -ItemType Directory -Force | Out-Null
        Write-ColorMessage "[OK] Created uploads directory" "Green"
    }
    else {
        Write-ColorMessage "[OK] Uploads directory already exists" "Green"
    }
    
    # Check and fix directory conflicts
    Write-ColorMessage "Checking for directory/file conflicts..." "Yellow"
    $repoPath = "frontend/backend/Repository.py"
    if (Test-Path -Path $repoPath -PathType Container) {
        $timestamp = Get-Date -Format "yyyyMMddHHmmss"
        $newName = "$repoPath-dir-$timestamp"
        Write-ColorMessage "Warning: $repoPath is a directory! Renaming to $newName" "Yellow"
        Rename-Item -Path $repoPath -NewName $newName -Force
    }

    $serverPath = "frontend/backend/server.js"
    if (Test-Path -Path $serverPath -PathType Container) {
        $timestamp = Get-Date -Format "yyyyMMddHHmmss"
        $newName = "$serverPath-dir-$timestamp"
        Write-ColorMessage "Warning: $serverPath is a directory! Renaming to $newName" "Yellow"
        Rename-Item -Path $serverPath -NewName $newName -Force
    }
    
    # Check for the 'app' directory which causes the "Is a directory (os error 21)" error
    Write-ColorMessage "Checking for 'app' directory that conflicts with Railway build output..." "Yellow"
    
    # Check for top-level 'app' directory
    if (Test-Path -Path "app" -PathType Container) {
        $timestamp = Get-Date -Format "yyyyMMddHHmmss"
        $newName = "app_folder_$timestamp"
        Write-ColorMessage "Warning: Found 'app' directory which conflicts with Railway deployment!" "Red"
        Write-ColorMessage "Renaming 'app' to '$newName'..." "Yellow"
        Rename-Item -Path "app" -NewName $newName -Force
        Write-ColorMessage "[OK] Resolved 'app' directory conflict" "Green"
    }
    
    # Create a robust .railwayignore file
    Write-ColorMessage "Creating comprehensive .railwayignore file..." "Yellow"
    $railwayIgnoreContent = @"
# Created by Railway deployment script
# This prevents conflicts with 'app' directories during deployment

# Ignore node_modules to prevent conflicts
node_modules/

# Ignore any app directories
**/app/

# Ignore cache directories that might cause issues
**/.cache/
**/__pycache__/
"@
    $railwayIgnoreContent | Out-File -FilePath ".railwayignore" -Force
    Write-ColorMessage "[OK] Created comprehensive .railwayignore file" "Green"

    # Update Nixpacks configuration to use a custom output name
    Write-ColorMessage "Updating Nixpacks configuration to avoid 'app' conflicts..." "Yellow"
    
    $nixpacksFile = "deploy-nixpacks.toml"
    if (Test-Path -Path $nixpacksFile) {
        $nixpacksContent = Get-Content -Path $nixpacksFile -Raw
        
        # Backup the original file
        Copy-Item -Path $nixpacksFile -Destination "$nixpacksFile.bak" -Force
        Write-ColorMessage "[OK] Created backup: $nixpacksFile.bak" "Green"
        
        # Add output name to avoid using 'app'
        if ($nixpacksContent -match "\[phases\.build\]") {
            if ($nixpacksContent -notmatch "output\s*=") {
                $newNixpacksContent = $nixpacksContent -replace "(\[phases\.build\][^\[]*)", "`$1`noutput = ""railway-app""`n"
                $newNixpacksContent | Out-File -FilePath $nixpacksFile -Force
                Write-ColorMessage "[OK] Added custom output name to $nixpacksFile" "Green"
            } else {
                Write-ColorMessage "[OK] Custom output name already defined in $nixpacksFile" "Green"
            }
        } else {
            # If there's no build section, add one
            $build = @"

# Added by Railway deployment script
[phases.build]
output = "railway-app"
"@
            Add-Content -Path $nixpacksFile -Value $build
            Write-ColorMessage "[OK] Added build section with custom output name to $nixpacksFile" "Green"
        }
    } else {
        Write-ColorMessage "Warning: deploy-nixpacks.toml not found, creating minimal configuration..." "Yellow"
        
        # Create a minimal Nixpacks configuration file
        $minimalNixpacks = @"
# Created by Railway deployment script
# This configures Nixpacks to avoid 'Is a directory' errors

[phases.build]
output = "railway-app"
"@
        $minimalNixpacks | Out-File -FilePath $nixpacksFile -Force
        Write-ColorMessage "[OK] Created minimal $nixpacksFile with custom output name" "Green"
    }

    # Enhance railway-up.js to better handle directory conflicts
    Write-ColorMessage "Checking railway-up.js for robust directory handling..." "Yellow"
    
    if (Test-Path -Path "railway-up.js") {
        $content = Get-Content -Path "railway-up.js" -Raw
        
        # Backup the original file
        Copy-Item -Path "railway-up.js" -Destination "railway-up.js.bak" -Force
        Write-ColorMessage "[OK] Created backup: railway-up.js.bak" "Green"
        
        # Check if we need to enhance directory validation
        if ($content -notmatch "fs\.statSync\(options\.cwd\)\.isDirectory\(\)") {
            Write-ColorMessage "Enhancing directory validation in railway-up.js..." "Yellow"
            
            # Find the right section to replace
            if ($content -match "if \(!fs\.existsSync\(options\.cwd\)\) \{[\s\S]*?console\.log\(`Created directory: \$\{options\.cwd\}`\);[\s\S]*?\}") {
                $improvedChecks = @'
    // Verify the working directory exists and is actually a directory
    if (fs.existsSync(options.cwd)) {
        if (!fs.statSync(options.cwd).isDirectory()) {
            console.error(`ERROR: Working directory path exists but is a file: ${options.cwd}`);
            // Rename the file to resolve conflict
            const backupName = `${options.cwd}_file_bak_${Date.now()}`;
            fs.renameSync(options.cwd, backupName);
            console.log(`Renamed conflicting file to: ${backupName}`);
            // Create the directory
            fs.mkdirSync(options.cwd, { recursive: true });
            console.log(`Created directory: ${options.cwd}`);
        }
    } else {
        console.log(`Working directory doesn't exist, creating: ${options.cwd}`);
        fs.mkdirSync(options.cwd, { recursive: true });
        console.log(`Created directory: ${options.cwd}`);
    }
'@
                # Replace the original directory existence check with the improved version
                $newContent = $content -replace "if \(!fs\.existsSync\(options\.cwd\)\) \{[\s\S]*?console\.log\(`Created directory: \$\{options\.cwd\}`\);[\s\S]*?\}", $improvedChecks
                $newContent | Out-File -Path "railway-up.js" -Force -NoNewline
                Write-ColorMessage "[OK] Enhanced directory validation in railway-up.js" "Green"
            } else {
                Write-ColorMessage "Warning: Could not find the right section to enhance in railway-up.js" "Yellow"
            }
        } else {
            Write-ColorMessage "[OK] railway-up.js already has robust directory validation" "Green"
        }
    } else {
        Write-ColorMessage "Warning: railway-up.js not found, skipping enhancement" "Yellow"
    }

    # Update the pre-deploy.sh script if it exists
    if (Test-Path -Path "pre-deploy.sh") {
        Write-ColorMessage "Checking pre-deploy.sh for directory conflict handling..." "Yellow"
        
        # Backup the original file
        Copy-Item -Path "pre-deploy.sh" -Destination "pre-deploy.sh.bak" -Force
        Write-ColorMessage "[OK] Created backup: pre-deploy.sh.bak" "Green"
        
        # Add conflict handling function to the script if needed
        $preDeployContent = Get-Content -Path "pre-deploy.sh" -Raw
        
        if ($preDeployContent -notmatch "handle_path_conflict") {
            $conflictHandler = @'

# Handle directory conflicts
handle_path_conflict() {
  local path="$1"
  echo "Checking path: $path"
  
  if [ -e "$path" ] && [ ! -d "$path" ]; then
    echo "WARNING: Path $path exists but is not a directory!"
    echo "Backing up conflicting file..."
    mv "$path" "${path}_file_bak_$(date +%s)"
    echo "[OK] Renamed conflicting file"
  fi
  
  if [ ! -e "$path" ] && [ -d "$path" ]; then
    echo "WARNING: Path $path exists as a directory but we need a file!"
    echo "Backing up conflicting directory..."
    mv "$path" "${path}_dir_bak_$(date +%s)"
    echo "[OK] Renamed conflicting directory"
    mkdir -p "$(dirname "$path")"
  fi
}

# Check potential conflict paths
handle_path_conflict "frontend/backend/Repository.py"
handle_path_conflict "frontend/backend/server.js"
handle_path_conflict "app"

'@
            # Insert the conflict handler after the shebang line
            if ($preDeployContent -match "^#!/bin/bash") {
                $newPreDeployContent = $preDeployContent -replace "^#!/bin/bash", "#!/bin/bash$conflictHandler"
                $newPreDeployContent | Out-File -FilePath "pre-deploy.sh" -Force -NoNewline
                Write-ColorMessage "[OK] Enhanced pre-deploy.sh with directory conflict handling" "Green"
            } else {
                # Just add to the beginning if no shebang found
                $newPreDeployContent = "#!/bin/bash$conflictHandler`n$preDeployContent"
                $newPreDeployContent | Out-File -FilePath "pre-deploy.sh" -Force -NoNewline
                Write-ColorMessage "[OK] Added directory conflict handling to pre-deploy.sh" "Green"
            }
        } else {
            Write-ColorMessage "[OK] pre-deploy.sh already has directory conflict handling" "Green"
        }
    }

    # Deploy with Railway
    Write-ColorMessage "Deploying to Railway..." "Green"
    railway up    
    
    # Check deployment result
    if ($LASTEXITCODE -eq 0) {
        Write-ColorMessage "========================================" "Cyan"
        Write-ColorMessage "       DEPLOYMENT SUCCESSFUL!           " "Cyan"
        Write-ColorMessage "========================================" "Cyan"
        Write-ColorMessage "Your application has been deployed to Railway." "Green"
        Write-ColorMessage "Check the Railway dashboard for details." "Green"
    } else {
        Write-ColorMessage "========================================" "Yellow"
        Write-ColorMessage "       DEPLOYMENT FAILED!               " "Yellow"
        Write-ColorMessage "========================================" "Yellow"
        Write-ColorMessage "Check the error messages above for details." "Red"
    }
}
catch {
    Write-ColorMessage "========================================" "Red"
    Write-ColorMessage "       ERROR OCCURRED!                  " "Red"
    Write-ColorMessage "========================================" "Red"
    Write-ColorMessage "Error details: $_" "Red"
    Write-ColorMessage "Stack trace: $($_.ScriptStackTrace)" "Red"
    exit 1
}
