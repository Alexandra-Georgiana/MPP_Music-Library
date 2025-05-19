# Railway-Fix-Deploy.ps1
# Comprehensive fix for the "Is a directory (os error 21)" error in Railway deployment

$ErrorActionPreference = "Stop"

function Write-ColorMessage {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Backup-File {
    param(
        [string]$FilePath
    )
    if (Test-Path -Path $FilePath) {
        $timestamp = Get-Date -Format "yyyyMMddHHmmss"
        $backupPath = "$FilePath.bak$timestamp"
        Copy-Item -Path $FilePath -Destination $backupPath -Force
        Write-ColorMessage "✓ Created backup: $backupPath" "Green"
    }
}

Write-ColorMessage "=======================================" "Cyan"
Write-ColorMessage "  RAILWAY DEPLOYMENT WITH ERROR FIX    " "Cyan"
Write-ColorMessage "=======================================" "Cyan"
Write-Host ""

# STEP 1: Fix directory conflicts
Write-ColorMessage "STEP 1: Fixing directory conflicts..." "Green"

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

# Create .railwayignore file to exclude problematic directories
$railwayIgnoreContent = @"
# Created by Railway deployment script
# This prevents conflicts with 'app' directories during deployment

# Ignore node_modules
node_modules/

# Ignore any app directories
**/app/

# Ignore cache directories that might cause issues
**/.cache/
**/__pycache__/
"@

$railwayIgnoreContent | Out-File -FilePath ".railwayignore" -Encoding utf8 -Force
Write-ColorMessage "✓ Created .railwayignore file" "Green"

# STEP 2: Update railway-up.js to better handle directory conflicts
Write-ColorMessage "`nSTEP 2: Enhancing railway-up.js to handle path conflicts..." "Green"

# Backup the original file
Backup-File -FilePath "railway-up.js"

# Read the content of railway-up.js
if (Test-Path -Path "railway-up.js") {
    $content = Get-Content -Path "railway-up.js" -Raw
    
    # Enhance the directory creation logic - we don't need to modify if our checks are already there
    if ($content -notmatch "fs\.statSync\(options\.cwd\)\.isDirectory\(\)") {
        Write-ColorMessage "Enhancing directory validation in railway-up.js..." "Yellow"
        
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
        $newContent = $content -replace "if \(!fs\.existsSync\(options\.cwd\)\) \{[\s\S]*?console\.log\(`Created directory: \$\{options\.cwd\}`\);\s*\}", $improvedChecks
        $newContent | Out-File -Path "railway-up.js" -Encoding utf8 -Force
        Write-ColorMessage "✓ Enhanced directory validation in railway-up.js" "Green"
    } else {
        Write-ColorMessage "✓ railway-up.js already has robust directory validation" "Green"
    }
}

# STEP 3: Check and update the server.js.railway file
Write-ColorMessage "`nSTEP 3: Reviewing server.js.railway..." "Green"

# Backup the original file
Backup-File -FilePath "frontend/backend/server.js.railway"

# Ensure the server.js.railway has proper directory handling
if (Test-Path -Path "frontend/backend/server.js.railway") {
    $serverContent = Get-Content -Path "frontend/backend/server.js.railway" -Raw
    
    # Check if the uploads directory handling is already robust
    if ($serverContent -notmatch "uploadsDir.*=.*path\.join\(__dirname, 'uploads'\)") {
        Write-ColorMessage "Enhancing uploads directory handling in server.js.railway..." "Yellow"
        
        $improvedUploadsHandling = @'
// Create uploads directory using absolute path
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
  try {
    // Check if the path exists but is a file
    if (fs.existsSync(uploadsDir) && !fs.statSync(uploadsDir).isDirectory()) {
      console.error('Error: uploads path exists but is a file');
      fs.renameSync(uploadsDir, `${uploadsDir}_file_bak_${Date.now()}`);
    }
    fs.mkdirSync(uploadsDir, { recursive: true });
    console.log(`Created uploads directory at: ${uploadsDir}`);
  } catch (error) {
    console.error(`Failed to create uploads directory: ${error.message}`);
  }
}
'@
        
        # Replace the original uploads directory check with the improved version
        $newServerContent = $serverContent -replace "if \(!fs\.existsSync\(['\"](uploads|./uploads)['\"]?\)\) \{[\s\S]*?(?:\}\s*\}\s*catch[\s\S]*?\}\s*\}|\}\s*)\}", $improvedUploadsHandling
        $newServerContent | Out-File -Path "frontend/backend/server.js.railway" -Encoding utf8 -Force
        Write-ColorMessage "✓ Enhanced uploads directory handling in server.js.railway" "Green"
    } else {
        Write-ColorMessage "✓ server.js.railway already has robust uploads directory handling" "Green"
    }
}

# STEP 4: Update Nixpacks configuration
Write-ColorMessage "`nSTEP 4: Updating Nixpacks configuration..." "Green"

$nixpacksFile = "deploy-nixpacks.toml"
if (Test-Path -Path $nixpacksFile) {
    Backup-File -FilePath $nixpacksFile
    
    $nixpacksContent = Get-Content -Path $nixpacksFile -Raw
    
    # Add output name to avoid using 'app'
    if ($nixpacksContent -match "\[phases\.build\]") {
        if ($nixpacksContent -notmatch "output\s*=") {
            $newNixpacksContent = $nixpacksContent -replace "(\[phases\.build\][^\[]*)", "`$1`noutput = ""railway-app""`n"
            $newNixpacksContent | Out-File -FilePath $nixpacksFile -Encoding utf8 -Force
            Write-ColorMessage "✓ Added custom output name to $nixpacksFile" "Green"
        } else {
            Write-ColorMessage "✓ Custom output name already defined in $nixpacksFile" "Green"
        }
    } else {
        # If there's no build section, add one
        $build = @"

# Added by Railway deployment script
[phases.build]
output = "railway-app"
"@
        Add-Content -Path $nixpacksFile -Value $build
        Write-ColorMessage "✓ Added build section with custom output name to $nixpacksFile" "Green"
    }
} else {
    # Create the file if it doesn't exist
    $minimalNixpacks = @"
# Created by Railway deployment script
# This configures Nixpacks to avoid 'Is a directory' errors

[phases.setup]
nixPkgs = [
  "nodejs_18",
  "python39",
  "python39Packages.pip", 
  "python39Packages.setuptools",
  "python39Packages.wheel",
  "unixODBC",
  "unixODBCDrivers.msodbcsql17",
  "curl",
  "gnused",
  "gcc"
]

[phases.install]
cmds = [
  "npm install",
  "cd frontend && npm install && cd ..",
  "cd frontend/backend && npm install && cd ../..",
  "pip install --upgrade pip",
  "pip install -r frontend/backend/requirements.txt"
]

[phases.build]
cmds = [
  "cd frontend && npm run build && cd .."
]
output = "railway-app"
"@
    $minimalNixpacks | Out-File -FilePath $nixpacksFile -Encoding utf8 -Force
    Write-ColorMessage "✓ Created $nixpacksFile with custom output name" "Green"
}

# STEP 5: Update pre-deploy.sh to handle directory conflicts
Write-ColorMessage "`nSTEP 5: Enhancing pre-deploy.sh..." "Green"

Backup-File -FilePath "pre-deploy.sh"

if (Test-Path -Path "pre-deploy.sh") {
    $preDeployContent = Get-Content -Path "pre-deploy.sh" -Raw
    
    # Enhance the mkdir command to handle potential conflicts better
    $improvedMkdirCmd = @'
# Make sure all needed directories exist with conflict resolution
echo "Creating required directories..."
for dir in "frontend/backend/uploads"; do
  if [ -e "$dir" ] && [ ! -d "$dir" ]; then
    echo "⚠️ Path $dir exists but is not a directory!"
    echo "Renaming conflicting file..."
    mv "$dir" "${dir}_file_bak_$(date +%s)"
  fi
  mkdir -p "$dir"
  echo "✅ Created directory: $dir"
done
'@

    # Replace the original mkdir command with the improved version
    $newPreDeployContent = $preDeployContent -replace "# Make sure all needed directories exist\s*mkdir -p frontend/backend/uploads\s*echo.*Created uploads directory", $improvedMkdirCmd
    $newPreDeployContent | Out-File -Path "pre-deploy.sh" -Encoding utf8 -Force -NoNewline
    Write-ColorMessage "✓ Enhanced directory handling in pre-deploy.sh" "Green"
}

# STEP 6: Deploy to Railway
Write-ColorMessage "`nSTEP 6: Preparing for deployment..." "Green"
Write-ColorMessage "All fixes have been applied. The project is now ready for deployment." "Green"

$deployNow = Read-Host "Do you want to deploy to Railway now? (y/n)"
if ($deployNow -eq "y") {
    Write-ColorMessage "`nDeploying to Railway..." "Yellow"
    & railway up
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorMessage "`nDeployment succeeded! Check Railway dashboard for details." "Green"
    } else {
        Write-ColorMessage "`nDeployment failed. Please check the error message above." "Red"
    }
} else {
    Write-ColorMessage "`nDeployment skipped. To deploy manually, run:" "Yellow" 
    Write-ColorMessage "railway up" "White"
}

Write-Host ""
Write-ColorMessage "=======================================" "Cyan"
Write-ColorMessage "  RAILWAY DEPLOYMENT SCRIPT COMPLETE   " "Cyan"
Write-ColorMessage "=======================================" "Cyan"
