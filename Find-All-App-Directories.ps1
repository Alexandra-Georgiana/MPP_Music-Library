# Find-All-App-Directories.ps1
# Script to find all 'app' directories that might conflict with Railway deployment

Write-Host "Searching for all 'app' directories in your project..." -ForegroundColor Cyan
Write-Host "(This might take a moment for large projects)" -ForegroundColor Gray

try {
    $appDirs = Get-ChildItem -Path "D:\MPP" -Recurse -Directory -Force -ErrorAction SilentlyContinue | 
               Where-Object { $_.Name -eq "app" }

    if ($appDirs.Count -eq 0) {
        Write-Host "No directories named 'app' were found in your project." -ForegroundColor Green
        Write-Host "If you're still seeing the 'Is a directory (os error 21)' error, it might be created during build." -ForegroundColor Yellow
    } else {
        Write-Host "Found $($appDirs.Count) directories named 'app':" -ForegroundColor Yellow
        foreach ($dir in $appDirs) {
            Write-Host "  - $($dir.FullName)" -ForegroundColor Yellow
        }

        Write-Host "`nWould you like to rename all these directories? (y/n)" -ForegroundColor Cyan
        $response = Read-Host
        if ($response.ToLower() -eq 'y') {
            foreach ($dir in $appDirs) {
                $timestamp = Get-Date -Format "yyyyMMddHHmmss"
                $newName = "app_folder_$timestamp"
                $parentPath = $dir.Parent.FullName
                $newPath = Join-Path -Path $parentPath -ChildPath $newName
                
                Write-Host "Renaming $($dir.FullName) to $newPath..." -ForegroundColor Green
                Rename-Item -Path $dir.FullName -NewName $newName
            }
            Write-Host "All 'app' directories have been renamed." -ForegroundColor Green
        } else {
            Write-Host "No directories were renamed." -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "Error searching for 'app' directories: $_" -ForegroundColor Red
}

# Check nixpacks configuration
Write-Host "`nChecking nixpacks build configuration..." -ForegroundColor Cyan
$nixpacksFiles = @("nixpacks.toml", "deploy-nixpacks.toml")
$foundConfig = $false

foreach ($file in $nixpacksFiles) {
    if (Test-Path -Path "D:\MPP\$file") {
        $foundConfig = $true
        Write-Host "Found $file - checking build configuration..." -ForegroundColor Yellow
        $content = Get-Content -Path "D:\MPP\$file" -Raw
        
        if ($content -match "\[phases\.build\]") {
            Write-Host "Build configuration found in $file" -ForegroundColor Yellow
            Write-Host "Consider modifying the build output name to avoid using 'app'" -ForegroundColor Yellow
            
            Write-Host "`nExample fix for Go projects:" -ForegroundColor Green
            Write-Host @"
[phases.build]
cmds = ["go build -o my-app"]
"@ -ForegroundColor Green
            
            Write-Host "`nExample fix for Rust projects:" -ForegroundColor Green
            Write-Host @"
[phases.build]
cmds = ["cargo build --bin my-app --release"]
"@ -ForegroundColor Green
            
            Write-Host "`nExample fix for other projects:" -ForegroundColor Green
            Write-Host @"
[build]
output = "my-app"
"@ -ForegroundColor Green
        }
    }
}

if (-not $foundConfig) {
    Write-Host "No nixpacks configuration files found." -ForegroundColor Yellow
}

Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. After renaming the 'app' directories, try deploying again with 'railway up'" -ForegroundColor White
Write-Host "2. If the error persists, check your nixpacks configuration to customize the build output name" -ForegroundColor White
