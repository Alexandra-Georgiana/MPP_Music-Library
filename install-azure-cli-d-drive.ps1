# Install Azure CLI to D: drive
$installPath = "D:\Azure-CLI"
$downloadPath = "D:\Azure-CLI-temp"

# Create directories if they don't exist
New-Item -ItemType Directory -Force -Path $installPath | Out-Null
New-Item -ItemType Directory -Force -Path $downloadPath | Out-Null

Write-Host "Downloading Azure CLI installer..." -ForegroundColor Yellow
$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile "$downloadPath\AzureCLI.msi"

Write-Host "Installing Azure CLI to D: drive..." -ForegroundColor Yellow
Start-Process msiexec.exe -Wait -ArgumentList "/i `"$downloadPath\AzureCLI.msi`" INSTALLDIR=`"$installPath`" /quiet"

# Add Azure CLI to PATH
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if (-not $currentPath.Contains($installPath)) {
    [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$installPath", "User")
}

# Clean up
Remove-Item -Path $downloadPath -Recurse -Force

Write-Host "Azure CLI installation complete!" -ForegroundColor Green
Write-Host "Please close and reopen PowerShell for the PATH changes to take effect." -ForegroundColor Yellow

# Test the installation
Write-Host "Testing Azure CLI installation..." -ForegroundColor Yellow
& "$installPath\wbin\az.cmd" --version
