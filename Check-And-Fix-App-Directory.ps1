# Check-And-Fix-App-Directory.ps1
# Script to find and rename any 'app' directory that would conflict with Railway deployment

$ErrorActionPreference = "Stop"
Write-Host "Checking for 'app' directory conflicts for Railway deployment..." -ForegroundColor Cyan

# Check for top-level 'app' directory
if (Test-Path -Path "app" -PathType Container) {
    Write-Host "Found top-level 'app' directory!" -ForegroundColor Yellow
    Write-Host "This conflicts with Railway's build output and causes the 'Is a directory (os error 21)' error" -ForegroundColor Yellow
    
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    $newName = "app_folder_$timestamp"
    
    Write-Host "Renaming 'app' directory to '$newName'..." -ForegroundColor Green
    Rename-Item -Path "app" -NewName $newName -Force
    
    Write-Host "Directory successfully renamed. You can now redeploy with 'railway up'" -ForegroundColor Green
    exit 0
}

# Check for frontend/app directory
if (Test-Path -Path "frontend/app" -PathType Container) {
    Write-Host "Found 'frontend/app' directory!" -ForegroundColor Yellow
    Write-Host "This might conflict with Railway's build output" -ForegroundColor Yellow
    
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    $newName = "app_folder_$timestamp"
    
    Write-Host "Renaming 'frontend/app' directory to 'frontend/$newName'..." -ForegroundColor Green
    Rename-Item -Path "frontend/app" -NewName $newName -Force
    
    Write-Host "Directory successfully renamed. You can now redeploy with 'railway up'" -ForegroundColor Green
    exit 0
}

# Check for other app directories in root subdirectories
$foundAppDirs = Get-ChildItem -Path "." -Directory | Where-Object { 
    Test-Path -Path (Join-Path -Path $_.FullName -ChildPath "app") -PathType Container 
}

if ($foundAppDirs.Count -gt 0) {
    Write-Host "Found app directories in the following locations:" -ForegroundColor Yellow
    foreach ($dir in $foundAppDirs) {
        $appPath = Join-Path -Path $dir.FullName -ChildPath "app"
        Write-Host "  - $appPath" -ForegroundColor Yellow
        
        $timestamp = Get-Date -Format "yyyyMMddHHmmss"
        $newName = "app_folder_$timestamp"
        $parentPath = $dir.FullName
        
        Write-Host "  Renaming to '$newName'..." -ForegroundColor Green
        Rename-Item -Path $appPath -NewName $newName -Force
    }
    
    Write-Host "Directories successfully renamed. You can now redeploy with 'railway up'" -ForegroundColor Green
    exit 0
}

# Also check if there's an issue with nixpacks.toml or deploy-nixpacks.toml
$nixpacksFiles = @("nixpacks.toml", "deploy-nixpacks.toml")
foreach ($file in $nixpacksFiles) {
    if (Test-Path -Path $file) {
        Write-Host "Found $file - checking for build configuration..." -ForegroundColor Cyan
        $content = Get-Content -Path $file -Raw
        
        # Check for Go or Rust build commands that might be creating an 'app' binary
        if ($content -match "go build" -and $content -notmatch "-o\s+[^\s]+") {
            Write-Host "Found Go build command without custom output name in $file" -ForegroundColor Yellow
            Write-Host "This might be creating an 'app' binary which conflicts with a directory" -ForegroundColor Yellow
            Write-Host @"
Consider adding a custom output name to your build command in $file:

[phases.build]
cmds = ["go build -o my-app"]

"@ -ForegroundColor Green
        }
        
        if ($content -match "cargo build" -and $content -notmatch "--bin\s+[^\s]+") {
            Write-Host "Found Rust build command without custom binary name in $file" -ForegroundColor Yellow
            Write-Host "This might be creating an 'app' binary which conflicts with a directory" -ForegroundColor Yellow
            Write-Host @"
Consider adding a custom binary name to your build command in $file:

[phases.build]
cmds = ["cargo build --bin my-app --release"]

"@ -ForegroundColor Green
        }
    }
}

Write-Host "No 'app' directory found in common locations." -ForegroundColor Green
Write-Host "If you're still seeing the 'Is a directory (os error 21)' error, the conflict might be in a different location." -ForegroundColor Yellow
Write-Host "Try running: Get-ChildItem -Path D:\MPP -Recurse -Directory -Force -ErrorAction SilentlyContinue | Where-Object { `$_.Name -eq 'app' }" -ForegroundColor Yellow
