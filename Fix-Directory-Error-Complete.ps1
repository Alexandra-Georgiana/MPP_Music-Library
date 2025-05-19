# Fix-Railway-Directory-Error.ps1
# Script to fix the "Is a directory (os error 21)" error in Railway deployment

$ErrorActionPreference = "Stop"

function Write-ColorMessage {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

Write-ColorMessage "=======================================" "Cyan"
Write-ColorMessage "  RAILWAY 'IS A DIRECTORY' ERROR FIX   " "Cyan"
Write-ColorMessage "=======================================" "Cyan"
Write-Host ""

Write-ColorMessage "This script will fix the 'Is a directory (os error 21)' error" "Yellow"
Write-ColorMessage "by implementing the recommended fixes." "Yellow"
Write-Host ""

# Option 1: Rename the conflicting directory
Write-ColorMessage "OPTION 1: Renaming conflicting 'app' directories..." "Green"

# Check for top-level app directory
if (Test-Path -Path "app" -PathType Container) {
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    $newName = "app_folder_$timestamp"
    Write-ColorMessage "Found 'app' directory at project root!" "Yellow"
    Write-ColorMessage "Renaming to '$newName'..." "Yellow"
    Rename-Item -Path "app" -NewName $newName -Force
    Write-ColorMessage "[OK] Directory renamed successfully" "Green"
} else {
    Write-ColorMessage "No top-level 'app' directory found." "Green"
}

# Check for app directories in node_modules that might conflict
$appDirs = Get-ChildItem -Path "." -Recurse -Directory -Force -ErrorAction SilentlyContinue | 
           Where-Object { $_.Name -eq "app" -and $_.FullName -notlike "*node_modules*cache*" } | 
           Select-Object -First 5

if ($appDirs.Count -gt 0) {
    Write-ColorMessage "Found $($appDirs.Count) 'app' directories:" "Yellow"
    foreach ($dir in $appDirs) {
        Write-ColorMessage "  - $($dir.FullName)" "Yellow"
    }
    Write-ColorMessage "These are inside node_modules and should be ignored during deployment." "Yellow"
}

# Option 2: Modify nixpacks configuration
Write-ColorMessage "`nOPTION 2: Checking Nixpacks configuration..." "Green"

$nixpacksFiles = @("nixpacks.toml", "deploy-nixpacks.toml")
$modified = $false

foreach ($file in $nixpacksFiles) {
    if (Test-Path -Path $file) {
        Write-ColorMessage "Found $file - checking for build configuration..." "Yellow"
        $content = Get-Content -Path $file -Raw
        
        # Make a backup of the original file
        Copy-Item -Path $file -Destination "$file.bak" -Force
        Write-ColorMessage "✓ Created backup: $file.bak" "Green"
        
        # Add output name to avoid using 'app'
        if ($content -match "\[phases\.build\]") {
            if ($content -notmatch "output\s*=") {
                $newContent = $content -replace "(\[phases\.build\][^\[]*)", "`$1`noutput = ""railway-app""`n"
                $newContent | Out-File -FilePath $file -Encoding utf8 -Force
                Write-ColorMessage "✓ Added custom output name to $file" "Green"
                $modified = $true
            }
        } else {
            # If there's no build section, add one
            $build = @"

# Added by Railway fix script
[phases.build]
output = "railway-app"
"@
            Add-Content -Path $file -Value $build
            Write-ColorMessage "✓ Added build section with custom output name to $file" "Green"
            $modified = $true
        }
    }
}

if (-not $modified) {
    Write-ColorMessage "No nixpacks configuration files found or modified." "Yellow"
    
    # Create a minimal nixpacks.toml if none exists
    if (-not (Test-Path -Path "nixpacks.toml") -and -not (Test-Path -Path "deploy-nixpacks.toml")) {
        $minimalNixpacks = @"
# Created by Railway fix script
# This configures Nixpacks to avoid 'Is a directory' errors

[phases.build]
output = "railway-app"

[start]
cmd = "node railway-up.js"
"@
        $minimalNixpacks | Out-File -FilePath "nixpacks.toml" -Encoding utf8 -Force
        Write-ColorMessage "✓ Created minimal nixpacks.toml with custom output name" "Green"
    }
}

# Option 3: Create .railwayignore to exclude app directories
Write-ColorMessage "`nOPTION 3: Creating .railwayignore file..." "Green"

$railwayIgnoreContent = @"
# Created by Railway fix script
# This prevents conflicts with 'app' directories during deployment

# Ignore node_modules
node_modules/

# Ignore any app directories
**/app/
"@

$railwayIgnoreContent | Out-File -FilePath ".railwayignore" -Encoding utf8 -Force
Write-ColorMessage "✓ Created .railwayignore file to exclude potential conflicting directories" "Green"

# Summary
Write-Host ""
Write-ColorMessage "=======================================" "Cyan"
Write-ColorMessage "          FIX COMPLETE                " "Cyan"
Write-ColorMessage "=======================================" "Cyan"
Write-Host ""
Write-ColorMessage "All potential 'Is a directory (os error 21)' errors should now be fixed." "Green"
Write-ColorMessage "To deploy your application, run:" "Yellow"
Write-ColorMessage "railway up" "White"
Write-Host ""
Write-ColorMessage "If you still encounter issues, check Railway logs for more details." "Yellow"
