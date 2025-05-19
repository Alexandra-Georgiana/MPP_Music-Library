# Deploy-With-Fix.ps1 - Script to deploy with fix for "Is a directory" error

Write-Host "===== Railway Deployment with Directory Fix =====" -ForegroundColor Cyan
Write-Host "This script will deploy your app to Railway with fixes for the 'Is a directory' error" -ForegroundColor Yellow

# Verify files exist
if (-not (Test-Path -Path railway.json)) {
    Write-Host "ERROR: railway.json not found in current directory" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path -Path deploy-nixpacks.toml)) {
    Write-Host "ERROR: deploy-nixpacks.toml not found in current directory" -ForegroundColor Red
    exit 1
}

# Make pre-deploy.sh executable (mark in git for Linux environments)
Write-Host "Setting pre-deploy.sh as executable for Linux environments..." -ForegroundColor Yellow
git update-index --chmod=+x ./pre-deploy.sh

# Check if Railway CLI is installed
if (-not (Get-Command railway -ErrorAction SilentlyContinue)) {
    Write-Host "Railway CLI not found. Installing..." -ForegroundColor Yellow
    npm install -g @railway/cli
}

# Check if logged in
$loginCheck = railway whoami 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Please login to Railway:" -ForegroundColor Yellow
    railway login
}

# Ensure directories exist
if (-not (Test-Path -Path frontend/backend)) {
    New-Item -Path frontend/backend -ItemType Directory -Force | Out-Null
    Write-Host "Created backend directory structure" -ForegroundColor Green
}

# Ensure requirements.txt is not empty
if (-not (Test-Path -Path frontend/backend/requirements.txt) -or 
    (Get-Content -Path frontend/backend/requirements.txt -Raw).Trim().Length -eq 0) {
    
    Write-Host "Creating/updating requirements.txt with necessary dependencies..." -ForegroundColor Yellow
    @"
flask==2.2.3
pyodbc==4.0.39
sqlalchemy==2.0.7
psycopg2-binary==2.9.6
python-dotenv==1.0.0
jwt==1.3.1
pyjwt==2.6.0
cryptography==40.0.1
werkzeug==2.2.3
gunicorn==21.2.0
"@ | Out-File -FilePath frontend/backend/requirements.txt -Encoding utf8 -Force
    Write-Host "requirements.txt created/updated" -ForegroundColor Green
}

# Create minimal server files if they don't exist
if (-not (Test-Path -Path frontend/backend/Repository.py.railway)) {
    Write-Host "Creating minimal Repository.py.railway..." -ForegroundColor Yellow
    @"
from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route('/')
def home():
    return jsonify({"status": "OK", "message": "Flask server running"})

if __name__ == '__main__':
    port = int(os.environ.get("PORT", 5000))
    app.run(host='0.0.0.0', port=port)
"@ | Out-File -FilePath frontend/backend/Repository.py.railway -Encoding utf8 -Force
    Write-Host "Repository.py.railway created" -ForegroundColor Green
}

if (-not (Test-Path -Path frontend/backend/server.js.railway)) {
    Write-Host "Creating minimal server.js.railway..." -ForegroundColor Yellow
    @"
const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.json({ status: 'OK', message: 'Node.js server running' });
});

app.listen(PORT, () => console.log(`Server running on port \${PORT}`));
"@ | Out-File -FilePath frontend/backend/server.js.railway -Encoding utf8 -Force
    Write-Host "server.js.railway created" -ForegroundColor Green
}

# Create package.json in backend if it doesn't exist
if (-not (Test-Path -Path frontend/backend/package.json)) {
    Write-Host "Creating minimal package.json in backend directory..." -ForegroundColor Yellow
    @"
{
  "name": "mpp-backend",
  "version": "1.0.0",
  "description": "Backend for Music Player Project",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2"
  }
}
"@ | Out-File -FilePath frontend/backend/package.json -Encoding utf8 -Force
    Write-Host "backend package.json created" -ForegroundColor Green
}

Write-Host "Deploying to Railway..." -ForegroundColor Cyan
railway up

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Deployment successful!" -ForegroundColor Green
    Write-Host "You can run the database initialization with:" -ForegroundColor Yellow
    Write-Host "railway run `"python frontend/backend/init_railway_db.py`"" -ForegroundColor White
} else {
    Write-Host "❌ Deployment failed with error code $LASTEXITCODE" -ForegroundColor Red
}
