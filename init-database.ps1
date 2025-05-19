# Script to initialize SQL Server database for Music Player Project

# Wait for SQL Server to be ready
$maxRetries = 30
$retryCount = 0
$sqlServerReady = $false

Write-Host "Waiting for SQL Server to be ready..."
while (-not $sqlServerReady -and $retryCount -lt $maxRetries) {
    try {
        # Try to connect to SQL Server using sqlcmd
        $result = Invoke-Expression "sqlcmd -S localhost,1433 -U sa -P StrongPassword123! -Q 'SELECT 1'"
        if ($LASTEXITCODE -eq 0) {
            $sqlServerReady = $true
            Write-Host "SQL Server is ready!"
        } else {
            $retryCount++
            Write-Host "SQL Server not ready yet. Retrying in 5 seconds... (Attempt $retryCount of $maxRetries)"
            Start-Sleep -Seconds 5
        }
    } catch {
        $retryCount++
        Write-Host "SQL Server not ready yet. Retrying in 5 seconds... (Attempt $retryCount of $maxRetries)"
        Start-Sleep -Seconds 5
    }
}

if (-not $sqlServerReady) {
    Write-Host "Failed to connect to SQL Server after $maxRetries attempts. Exiting."
    exit 1
}

# Create the MusicLibrary database
Write-Host "Creating MusicLibrary database..."
Invoke-Expression "sqlcmd -S localhost,1433 -U sa -P StrongPassword123! -Q 'CREATE DATABASE MusicLibrary'"

# Apply schema from init.sql
Write-Host "Applying database schema..."
Invoke-Expression "sqlcmd -S localhost,1433 -U sa -P StrongPassword123! -d MusicLibrary -i ./frontend/backend/init.sql"

# Apply stored procedures
Write-Host "Applying stored procedures..."
Invoke-Expression "sqlcmd -S localhost,1433 -U sa -P StrongPassword123! -d MusicLibrary -i ./frontend/backend/data/ProceduresMusicLib.sql"

# Populate sample data if needed
Write-Host "Populating sample data..."
Invoke-Expression "python ./frontend/backend/populate_songs.py"

Write-Host "Database initialization completed!"
