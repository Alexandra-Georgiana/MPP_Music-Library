# Fix-Railway-Directory-Error.ps1
# Script to fix "Is a directory (os error 21)" error in Railway deployment

Write-Host "===== RAILWAY DIRECTORY ERROR FIX =====" -ForegroundColor Cyan
Write-Host "This script will fix the 'Is a directory (os error 21)' error in your Railway deployment" -ForegroundColor Yellow

# Check if we're in the project root
if (-not (Test-Path -Path "railway.json")) {
    Write-Host "ERROR: railway.json not found. Make sure you're in the project root directory." -ForegroundColor Red
    exit 1
}

# 1. Check for directory path conflicts
Write-Host "`nChecking for directory path conflicts..." -ForegroundColor Yellow

# Ensure the uploads directory exists with proper structure
Write-Host "Ensuring proper uploads directory structure..." -ForegroundColor Yellow
if (-not (Test-Path -Path "frontend/backend/uploads")) {
    New-Item -Path "frontend/backend/uploads" -ItemType Directory -Force | Out-Null
    Write-Host "✓ Created frontend/backend/uploads directory" -ForegroundColor Green
} else {
    Write-Host "✓ frontend/backend/uploads directory already exists" -ForegroundColor Green
}

# 2. Fix railway-up.js path handling
Write-Host "`nChecking railway-up.js for path handling issues..." -ForegroundColor Yellow
$railwayUpPath = Join-Path -Path (Get-Location) -ChildPath "railway-up.js"

if (Test-Path -Path $railwayUpPath) {
    # Read the file content
    $railwayUpContent = Get-Content -Path $railwayUpPath -Raw
    
    # Backup the original file
    Copy-Item -Path $railwayUpPath -Destination "$railwayUpPath.bak" -Force
    Write-Host "✓ Created backup of railway-up.js at railway-up.js.bak" -ForegroundColor Green
    
    # Fix path handling in executeCommand function
    if ($railwayUpContent -match "fs\.existsSync\(options\.cwd\)") {
        Write-Host "Fixing directory handling in railway-up.js..." -ForegroundColor Yellow
        
        $railwayUpContent = $railwayUpContent -replace "if \(!fs\.existsSync\(options\.cwd\)\) \{([^\}]+)\}", @'
if (!fs.existsSync(options.cwd)) {
        console.error(`ERROR: Working directory does not exist: ${options.cwd}`);
        console.log('Creating directory...');
        try {
            // Make sure we don't try to create a directory that's actually a file
            if (fs.existsSync(options.cwd.replace(/\/[^\/]+$/, ''))) {
                const parentDir = options.cwd.replace(/\/[^\/]+$/, '');
                if (fs.statSync(parentDir).isFile()) {
                    console.error(`ERROR: Parent path is a file, not a directory: ${parentDir}`);
                    process.exit(1);
                }
            }
            fs.mkdirSync(options.cwd, { recursive: true });
        } catch (err) {
            console.error(`Failed to create directory: ${err.message}`);
            process.exit(1);
        }
'@
        
        # Update file recovery logic to check for directory conflicts
        $railwayUpContent = $railwayUpContent -replace "if \(!fs\.existsSync\(repositoryPath\) && fs\.existsSync\(path\.join\(backendPath, 'Repository\.py\.railway'\)\)\) \{([^\}]+)\}", @'
if (!fs.existsSync(repositoryPath) && fs.existsSync(path.join(backendPath, 'Repository.py.railway'))) {
        console.log('Copying Repository.py.railway to Repository.py...');
        try {
            // Check if repositoryPath is a directory, which would cause "Is a directory" error
            if (fs.existsSync(repositoryPath) && fs.statSync(repositoryPath).isDirectory()) {
                console.error(`ERROR: Repository.py path exists but is a directory: ${repositoryPath}`);
                // Rename the directory to resolve conflict
                const backupDirName = `${repositoryPath}_directory_bak_${Date.now()}`;
                fs.renameSync(repositoryPath, backupDirName);
                console.log(`Renamed conflicting directory to: ${backupDirName}`);
            }
            fs.copyFileSync(path.join(backendPath, 'Repository.py.railway'), repositoryPath);
        }
'@
        
        # Update server.js recovery logic as well
        $railwayUpContent = $railwayUpContent -replace "if \(!fs\.existsSync\(serverJsPath\) && fs\.existsSync\(path\.join\(backendPath, 'server\.js\.railway'\)\)\) \{([^\}]+)\}", @'
if (!fs.existsSync(serverJsPath) && fs.existsSync(path.join(backendPath, 'server.js.railway'))) {
        console.log('Copying server.js.railway to server.js...');
        try {
            // Check if serverJsPath is a directory, which would cause "Is a directory" error
            if (fs.existsSync(serverJsPath) && fs.statSync(serverJsPath).isDirectory()) {
                console.error(`ERROR: server.js path exists but is a directory: ${serverJsPath}`);
                // Rename the directory to resolve conflict
                const backupDirName = `${serverJsPath}_directory_bak_${Date.now()}`;
                fs.renameSync(serverJsPath, backupDirName);
                console.log(`Renamed conflicting directory to: ${backupDirName}`);
            }
            fs.copyFileSync(path.join(backendPath, 'server.js.railway'), serverJsPath);
        }
'@
        
        # Write the modified content back to the file
        $railwayUpContent | Set-Content -Path $railwayUpPath
        Write-Host "✓ Fixed railway-up.js script" -ForegroundColor Green
    } else {
        Write-Host "No issues found in railway-up.js" -ForegroundColor Green
    }
} else {
    Write-Host "⚠️ railway-up.js not found" -ForegroundColor Yellow
}

# 3. Check the pre-deploy.sh script
Write-Host "`nChecking pre-deploy.sh script..." -ForegroundColor Yellow
$preDeployPath = Join-Path -Path (Get-Location) -ChildPath "pre-deploy.sh"

if (Test-Path -Path $preDeployPath) {
    # Read the file content
    $preDeployContent = Get-Content -Path $preDeployPath -Raw
    
    # Backup the original file
    Copy-Item -Path $preDeployPath -Destination "$preDeployPath.bak" -Force
    Write-Host "✓ Created backup of pre-deploy.sh at pre-deploy.sh.bak" -ForegroundColor Green
    
    # Add defensive checks before copying files
    if ($preDeployContent -match "cp -f frontend/backend/Repository\.py\.railway frontend/backend/Repository\.py") {
        Write-Host "Adding defensive checks to pre-deploy.sh..." -ForegroundColor Yellow
        
        $preDeployContent = $preDeployContent -replace "cp -f frontend/backend/Repository\.py\.railway frontend/backend/Repository\.py", @'
# Check if target is a directory, which would cause "Is a directory" error
if [ -d frontend/backend/Repository.py ]; then
  echo "⚠️ Repository.py exists as a directory - renaming it to avoid conflicts"
  mv frontend/backend/Repository.py frontend/backend/Repository.py_dir_backup
fi
cp -f frontend/backend/Repository.py.railway frontend/backend/Repository.py
'@
        
        $preDeployContent = $preDeployContent -replace "cp -f frontend/backend/server\.js\.railway frontend/backend/server\.js", @'
# Check if target is a directory, which would cause "Is a directory" error
if [ -d frontend/backend/server.js ]; then
  echo "⚠️ server.js exists as a directory - renaming it to avoid conflicts"
  mv frontend/backend/server.js frontend/backend/server.js_dir_backup
fi
cp -f frontend/backend/server.js.railway frontend/backend/server.js
'@
        
        # Write the modified content back to the file
        $preDeployContent | Set-Content -Path $preDeployPath -NoNewline
        Write-Host "✓ Fixed pre-deploy.sh script" -ForegroundColor Green
    } else {
        Write-Host "No issues found in pre-deploy.sh" -ForegroundColor Green
    }
} else {
    Write-Host "⚠️ pre-deploy.sh not found" -ForegroundColor Yellow
}

# 4. Update railway.json to ensure correct start command
Write-Host "`nChecking railway.json configuration..." -ForegroundColor Yellow
$railwayJsonPath = Join-Path -Path (Get-Location) -ChildPath "railway.json"

if (Test-Path -Path $railwayJsonPath) {
    # Read the file content
    $railwayJsonContent = Get-Content -Path $railwayJsonPath | ConvertFrom-Json
    
    # Backup the original file
    Copy-Item -Path $railwayJsonPath -Destination "$railwayJsonPath.bak" -Force
    Write-Host "✓ Created backup of railway.json at railway.json.bak" -ForegroundColor Green
    
    # Update the start command if needed
    if ($railwayJsonContent.deploy.startCommand -ne "node railway-up.js") {
        $railwayJsonContent.deploy.startCommand = "node railway-up.js"
        $railwayJsonContent | ConvertTo-Json -Depth 10 | Set-Content -Path $railwayJsonPath
        Write-Host "✓ Updated railway.json start command" -ForegroundColor Green
    } else {
        Write-Host "✓ railway.json configuration looks good" -ForegroundColor Green
    }
} else {
    Write-Host "⚠️ railway.json not found" -ForegroundColor Red
}

# 5. Fix uploads directory handling in server.js.railway
Write-Host "`nFixing uploads directory handling..." -ForegroundColor Yellow
$serverRailwayPath = Join-Path -Path (Get-Location) -ChildPath "frontend/backend/server.js.railway"

if (Test-Path -Path $serverRailwayPath) {
    # Read the file content
    $serverRailwayContent = Get-Content -Path $serverRailwayPath -Raw
    
    # Backup the original file
    Copy-Item -Path $serverRailwayPath -Destination "$serverRailwayPath.bak" -Force
    Write-Host "✓ Created backup of server.js.railway at server.js.railway.bak" -ForegroundColor Green
    
    # Update uploads directory handling
    if ($serverRailwayContent -match "if \(!fs\.existsSync\('uploads'\)\) \{") {
        Write-Host "Fixing uploads directory handling in server.js.railway..." -ForegroundColor Yellow
        
        $serverRailwayContent = $serverRailwayContent -replace "if \(!fs\.existsSync\('uploads'\)\) \{\s+fs\.mkdirSync\('uploads'\);\s+\}", @'
// Create uploads directory using absolute path
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
  try {
    // Check if the path exists but is a file
    if (fs.existsSync(uploadsDir) && fs.statSync(uploadsDir).isFile()) {
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
        
        # Fix the static directory serving
        $serverRailwayContent = $serverRailwayContent -replace "app\.use\('/uploads', express\.static\('uploads'\)\);", @'
// Serve uploads from absolute path
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));
'@
        
        # Write the modified content back to the file
        $serverRailwayContent | Set-Content -Path $serverRailwayPath -NoNewline
        Write-Host "✓ Fixed uploads directory handling in server.js.railway" -ForegroundColor Green
    } else {
        Write-Host "No issues found in server.js.railway" -ForegroundColor Green
    }
} else {
    Write-Host "⚠️ server.js.railway not found" -ForegroundColor Yellow
}

# Final summary
Write-Host "`n===== RAILWAY DIRECTORY ERROR FIX COMPLETE =====" -ForegroundColor Cyan
Write-Host "The 'Is a directory (os error 21)' error should now be fixed." -ForegroundColor Green
Write-Host "To deploy your app, run: railway up" -ForegroundColor Yellow
