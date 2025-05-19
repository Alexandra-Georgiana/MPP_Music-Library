# Deployment Testing Script for the Music Player Project
# This script will test the connectivity between components after deployment

#########################################################
# Display banner
#########################################################
function Show-Banner {
    Clear-Host
    Write-Host "`n`n=================================================" -ForegroundColor Cyan
    Write-Host "     MUSIC PLAYER PROJECT - DEPLOYMENT TEST     " -ForegroundColor Cyan
    Write-Host "=================================================`n" -ForegroundColor Cyan
}

Show-Banner

#########################################################
# Check deployment output file
#########################################################
Write-Host "STEP 1: Checking deployment information..." -ForegroundColor Yellow

if (-not (Test-Path "./azure-deployment-output.json")) {
    Write-Host "❌ Deployment output file not found." -ForegroundColor Red
    Write-Host "Please run the deployment script first before testing." -ForegroundColor Red
    exit 1
}

$deploymentInfo = Get-Content -Raw -Path "./azure-deployment-output.json" | ConvertFrom-Json
Write-Host "✅ Found deployment information" -ForegroundColor Green

# Display basic deployment info
Write-Host "`nDeployment Details:" -ForegroundColor Cyan
Write-Host "- Frontend URL: $($deploymentInfo.frontendUrl)"
Write-Host "- API URL: $($deploymentInfo.apiUrl)"
Write-Host "- Database Server: $($deploymentInfo.dbServer)"
Write-Host "- Database Name: $($deploymentInfo.dbName)"
Write-Host "- Resource Group: $($deploymentInfo.resourceGroup)"
Write-Host "- Deployed on: $($deploymentInfo.timestamp)`n"

#########################################################
# Test frontend availability
#########################################################
Write-Host "STEP 2: Testing frontend availability..." -ForegroundColor Yellow

try {
    $frontendResponse = Invoke-WebRequest -Uri $deploymentInfo.frontendUrl -UseBasicParsing -SkipCertificateCheck
    Write-Host "✅ Frontend is accessible (Status: $($frontendResponse.StatusCode))" -ForegroundColor Green
    
    if ($frontendResponse.StatusCode -eq 200) {
        Write-Host "   The frontend is responding with HTTP 200 OK" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Cannot access frontend: $_" -ForegroundColor Red
    Write-Host "   Please check the Azure App Service logs in the Azure Portal." -ForegroundColor Yellow
}

#########################################################
# Test API availability
#########################################################
Write-Host "`nSTEP 3: Testing API availability..." -ForegroundColor Yellow

$apiEndpoints = @(
    "/api/health",
    "/api/songs",
    "/api/users"
)

foreach ($endpoint in $apiEndpoints) {
    $apiUrl = "$($deploymentInfo.apiUrl)$endpoint"
    Write-Host "Testing endpoint: $apiUrl" -NoNewline
    
    try {
        $apiResponse = Invoke-WebRequest -Uri $apiUrl -UseBasicParsing -SkipCertificateCheck -TimeoutSec 10
        Write-Host " ✅ (Status: $($apiResponse.StatusCode))" -ForegroundColor Green
    } catch {
        Write-Host " ❌ Error: $_" -ForegroundColor Red
    }
}

#########################################################
# Test database connectivity
#########################################################
Write-Host "`nSTEP 4: Testing database connectivity..." -ForegroundColor Yellow

Write-Host "The script will now check database connectivity through the API..."
$dbHealthUrl = "$($deploymentInfo.apiUrl)/api/db-health"

try {
    $dbResponse = Invoke-WebRequest -Uri $dbHealthUrl -UseBasicParsing -SkipCertificateCheck -TimeoutSec 10
    Write-Host "✅ API reports database connection is working (Status: $($dbResponse.StatusCode))" -ForegroundColor Green
    Write-Host "   Response: $($dbResponse.Content)" -ForegroundColor Green
} catch {
    Write-Host "❌ Database connectivity test failed: $_" -ForegroundColor Red
    Write-Host "`nTroubleshooting tips:" -ForegroundColor Yellow
    Write-Host "1. Check the connection string in the API app settings."
    Write-Host "2. Verify that the SQL Server firewall allows connections from Azure services."
    Write-Host "3. Check if the database was properly initialized with schema."
}

#########################################################
# Test SSL configuration
#########################################################
Write-Host "`nSTEP 5: Testing SSL configuration..." -ForegroundColor Yellow

function Test-SSLCertificate {
    param (
        [string]$Url
    )
    
    $domain = ($Url -replace "https://", "") -replace "/.*", ""
    
    try {
        $webRequest = [Net.WebRequest]::Create($Url)
        $webRequest.AllowAutoRedirect = $true
        $webRequest.Timeout = 10000
        
        $response = $webRequest.GetResponse()
        $cert = $response.Certificate
        
        Write-Host "✅ SSL certificate is valid for $domain" -ForegroundColor Green
        Write-Host "   - Issued by: $($cert.Issuer)"
        Write-Host "   - Valid from: $($cert.GetEffectiveDateString())"
        Write-Host "   - Valid until: $($cert.GetExpirationDateString())"
        
        $response.Close()
    }
    catch {
        Write-Host "❌ SSL certificate check failed for $domain" -ForegroundColor Red
        Write-Host "   Error: $_"
    }
}

Test-SSLCertificate -Url $deploymentInfo.frontendUrl
Test-SSLCertificate -Url $deploymentInfo.apiUrl

#########################################################
# Check CORS configuration
#########################################################
Write-Host "`nSTEP 6: Testing CORS configuration..." -ForegroundColor Yellow

$corsTestUrl = "$($deploymentInfo.apiUrl)/api/songs"

try {
    $headers = @{
        "Origin" = $deploymentInfo.frontendUrl
    }
    
    $corsResponse = Invoke-WebRequest -Uri $corsTestUrl -Headers $headers -Method Options -UseBasicParsing -SkipCertificateCheck
    
    if ($corsResponse.Headers["Access-Control-Allow-Origin"]) {
        Write-Host "✅ CORS headers are properly configured:" -ForegroundColor Green
        Write-Host "   - Access-Control-Allow-Origin: $($corsResponse.Headers["Access-Control-Allow-Origin"])"
    } else {
        Write-Host "⚠️ CORS headers might not be properly configured. Check for potential cross-origin issues." -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ CORS check failed: $_" -ForegroundColor Red
}

#########################################################
# Display summary
#########################################################
Write-Host "`n`n=================================================" -ForegroundColor Cyan
Write-Host "             DEPLOYMENT TEST SUMMARY             " -ForegroundColor Cyan
Write-Host "=================================================`n" -ForegroundColor Cyan

Write-Host "To access your application:" -ForegroundColor White
Write-Host "🌐 Frontend: $($deploymentInfo.frontendUrl)" -ForegroundColor Cyan
Write-Host "🔌 API Base: $($deploymentInfo.apiUrl)" -ForegroundColor Cyan

Write-Host "`nIf you encountered any issues during testing:" -ForegroundColor White
Write-Host "1. Check Azure App Service logs in the Azure Portal"
Write-Host "2. Review SQL Server connection settings"
Write-Host "3. Verify network security rules"
Write-Host "4. Check the application configuration"

Write-Host "`nTo monitor your deployment in the Azure portal:" -ForegroundColor White
Write-Host "https://portal.azure.com/#@/resource/subscriptions/your-subscription-id/resourceGroups/$($deploymentInfo.resourceGroup)/overview"

Write-Host "`nDon't forget to set up proper monitoring and alerts for your production environment!" -ForegroundColor Yellow
