#!/bin/bash
# deploy-fixed-railway.sh
# Script to deploy to Railway with the directory error fix

echo "===== RAILWAY DEPLOYMENT WITH DIRECTORY ERROR FIX ====="
echo "This script will deploy your app to Railway with fixes for the 'Is a directory (os error 21)' error"

# Verify required files exist
if [ ! -f "railway.json" ]; then
    echo "ERROR: railway.json not found in current directory"
    exit 1
fi

# Check if Railway CLI is installed
if ! command -v railway &> /dev/null; then
    echo "× Railway CLI not found"
    echo "Please install Railway CLI with: npm i -g @railway/cli"
    exit 1
else
    echo "✓ Railway CLI is installed"
fi

# Ensure all needed directories exist
echo "Ensuring proper directory structure..."
mkdir -p frontend/backend/uploads
echo "✓ Created/verified frontend/backend/uploads directory"

# Ensure file paths are not directories
echo "Checking for directory/file conflicts..."

# Check Repository.py
REPO_PATH="frontend/backend/Repository.py"
if [ -d "$REPO_PATH" ]; then
    TIMESTAMP=$(date +%Y%m%d%H%M%S)
    NEW_NAME="${REPO_PATH}_dir_${TIMESTAMP}"
    echo "⚠ $REPO_PATH is a directory! Renaming to $NEW_NAME"
    mv "$REPO_PATH" "$NEW_NAME"
fi

# Check server.js
SERVER_PATH="frontend/backend/server.js"
if [ -d "$SERVER_PATH" ]; then
    TIMESTAMP=$(date +%Y%m%d%H%M%S)
    NEW_NAME="${SERVER_PATH}_dir_${TIMESTAMP}"
    echo "⚠ $SERVER_PATH is a directory! Renaming to $NEW_NAME"
    mv "$SERVER_PATH" "$NEW_NAME"
fi

# Make pre-deploy.sh executable
chmod +x pre-deploy.sh 2>/dev/null || echo "Warning: Could not set execute permission on pre-deploy.sh"

# Deploy to Railway
echo -e "\nDeploying to Railway..."
railway up

# Check deployment status
if [ $? -eq 0 ]; then
    echo -e "\n✓ Deployment successful!"
    echo "Your app should now be running on Railway without the 'Is a directory' error"
else
    echo -e "\n× Deployment failed"
    echo "Check the error messages above for more details"
fi
