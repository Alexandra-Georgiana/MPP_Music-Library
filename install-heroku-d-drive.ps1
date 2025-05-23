# Self-elevate the script if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Write-Host "Requesting administrative privileges..." -ForegroundColor Yellow
    $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`""
    Start-Process -FilePath PowerShell.exe -Verb RunAs -ArgumentList $CommandLine
    exit
}

# Install Heroku CLI to D: drive
$herokuPath = "D:\Heroku-CLI"
$downloadPath = "D:\Heroku-temp"

# Create directories
New-Item -ItemType Directory -Force -Path $herokuPath | Out-Null
New-Item -ItemType Directory -Force -Path $downloadPath | Out-Null

Write-Host "Downloading Heroku CLI installer..." -ForegroundColor Yellow
$ProgressPreference = 'SilentlyContinue'

# Try to install using winget first
Write-Host "Installing Heroku CLI using winget..." -ForegroundColor Yellow
$wingetResult = winget install -e --id Heroku.HerokuCLI --location $herokuPath

if ($LASTEXITCODE -ne 0) {
    Write-Host "Winget installation failed, trying direct download..." -ForegroundColor Yellow
    try {
        # Download using direct HTTPS method
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri "https://cli-assets.heroku.com/heroku-x64.exe" -OutFile "$downloadPath\heroku-installer.exe"
    } catch {
        Write-Host "Both installation methods failed." -ForegroundColor Red
        Write-Host "Please try installing Heroku CLI manually from: https://devcenter.heroku.com/articles/heroku-cli" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "Heroku CLI installed successfully via winget!" -ForegroundColor Green
}

if (Test-Path "$downloadPath\heroku-installer.exe") {
    Write-Host "Installing Heroku CLI to D: drive..." -ForegroundColor Yellow
    Start-Process "$downloadPath\heroku-installer.exe" -ArgumentList "/VERYSILENT", "/DIR=$herokuPath" -Wait -NoNewWindow

    # Add Heroku to both User and Machine PATH
    $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    $machinePath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
    
    if (-not $userPath.Contains($herokuPath)) {
        [Environment]::SetEnvironmentVariable("PATH", "$userPath;$herokuPath\bin", "User")
    }
    if (-not $machinePath.Contains($herokuPath)) {
        [Environment]::SetEnvironmentVariable("PATH", "$machinePath;$herokuPath\bin", "Machine")
    }

    # Update current session PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

    # Clean up
    Remove-Item -Path $downloadPath -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "Verifying installation..." -ForegroundColor Yellow
$herokuExe = Get-Command heroku -ErrorAction SilentlyContinue
if ($herokuExe) {
    $version = & $herokuExe --version
    Write-Host "Heroku CLI installed successfully! Version: $version" -ForegroundColor Green
} else {
    Write-Host "Installation complete, but Heroku CLI not found in PATH" -ForegroundColor Yellow
    Write-Host "Please close and reopen PowerShell, then run 'heroku --version' to verify installation" -ForegroundColor Yellow
    
    # Show PATH for debugging
    Write-Host "`nCurrent PATH:" -ForegroundColor Cyan
    $env:Path -split ';' | Where-Object { $_ -like '*heroku*' } | ForEach-Object { Write-Host $_ }
}
