# Deploy the Music Player Project with HTTPS support

# Display banner
Write-Host "`n===============================================" -ForegroundColor Cyan
Write-Host "  Music Player Project - HTTPS Deployment" -ForegroundColor Cyan
Write-Host "===============================================`n" -ForegroundColor Cyan

# Step 1: Generate SSL certificates
Write-Host "Step 1: Generating SSL certificates..." -ForegroundColor Yellow
./generate-certs.ps1

# Step 2: Update hosts file to map mpp.local to 127.0.0.1
Write-Host "`nStep 2: Updating hosts file..." -ForegroundColor Yellow
$hostsPath = "$env:windir\System32\drivers\etc\hosts"
$hostsContent = Get-Content -Path $hostsPath
if (-not ($hostsContent -match "mpp.local")) {
    Write-Host "Adding mpp.local to hosts file. This will require admin privileges." -ForegroundColor Yellow
    # Use Start-Process to elevate privileges
    Start-Process -FilePath "powershell" -ArgumentList "-Command Add-Content -Path '$hostsPath' -Value '127.0.0.1 mpp.local' -Force" -Verb RunAs
} else {
    Write-Host "mpp.local is already in hosts file." -ForegroundColor Green
}

# Step 3: Prepare the HTTPS versions of the backend files
Write-Host "`nStep 3: Preparing HTTPS versions of backend files..." -ForegroundColor Yellow
Copy-Item -Path "./frontend/backend/Repository.py.https" -Destination "./frontend/backend/Repository.py" -Force
Copy-Item -Path "./frontend/backend/server.js.https" -Destination "./frontend/backend/server.js" -Force
Write-Host "Backend files updated for HTTPS." -ForegroundColor Green

# Step 4: Build and start the containers
Write-Host "`nStep 4: Building and starting the Docker containers..." -ForegroundColor Yellow
docker-compose down
docker-compose build
docker-compose up -d

# Wait for containers to be ready
Write-Host "`nWaiting for containers to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Step 5: Initialize the database
Write-Host "`nStep 5: Initializing the database..." -ForegroundColor Yellow
./init-database.ps1

# Done
Write-Host "`n===============================================" -ForegroundColor Green
Write-Host "  Deployment Complete!" -ForegroundColor Green
Write-Host "===============================================`n" -ForegroundColor Green
Write-Host "Your application is now available at:" -ForegroundColor Cyan
Write-Host "  Flask API: https://mpp.local:443" -ForegroundColor White
Write-Host "  Node.js API: https://mpp.local:3443" -ForegroundColor White
Write-Host "`nIMPORTANT: You may need to accept the self-signed certificate in your browser." -ForegroundColor Yellow
