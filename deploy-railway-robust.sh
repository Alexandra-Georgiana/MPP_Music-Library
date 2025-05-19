#!/bin/bash
# Robust Railway deployment script with comprehensive fixes

set -e

echo "======================================="
echo "  COMPREHENSIVE RAILWAY DEPLOYMENT FIX "
echo "======================================="
echo ""

# STEP 1: Ensure we have no directory conflicts
echo "STEP 1: Checking for directory conflicts..."

# Check for top-level app directory (Nixpacks default output)
if [ -e "app" ]; then
  if [ -d "app" ]; then
    timestamp=$(date +%s)
    new_name="app_folder_$timestamp"
    echo "Found 'app' directory at project root!"
    echo "Renaming to '$new_name'..."
    mv "app" "$new_name"
    echo "[OK] Directory renamed successfully"
  else
    echo "WARNING: 'app' is a file, not a directory"
    mv "app" "app.bak$(date +%s)"
    echo "[OK] File renamed"
  fi
else
  echo "No top-level 'app' directory found."
fi

# STEP 2: Create proper Railway configuration
echo ""
echo "STEP 2: Creating proper Railway configuration..."

# Create clean railway.json
cat > railway.json << 'EOF'
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "NIXPACKS",
    "nixpacksConfigPath": "deploy-nixpacks.toml",
    "buildCommand": "bash ./pre-deploy-clean2.sh"
  },
  "deploy": {
    "numReplicas": 1,
    "startCommand": "cd $PROJECT_DIR && node railway-up-clean2.js",
    "healthcheckPath": "/",
    "healthcheckTimeout": 100,
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 5,
    "sleepApplication": false
  }
}
EOF
echo "[OK] Created clean railway.json"

# Create better .railwayignore
cat > .railwayignore << 'EOF'
# Comprehensive .railwayignore file
# Prevents conflicts with 'app' directories during deployment

# Ignore node_modules to prevent app directory conflicts
node_modules/

# Explicitly ignore all backup directories and files
**/*_backup_*
**/*_bak_*
**/*.bak

# Ignore any app directories that might cause conflicts
**/app/
app/

# Ignore dev files not needed in production
**/.git/
**/.vscode/
**/__pycache__/
**/.pytest_cache/
**/.DS_Store
**/*.log
**/*.md
**/*.ps1
**/*.bat

# Ignore old deployment scripts
deploy-*.sh
*-deploy.sh
*-deploy.ps1
Fixed-*.ps1
Run-*.ps1
Check-*.ps1
EOF
echo "[OK] Created comprehensive .railwayignore"

# Make scripts executable
chmod +x pre-deploy-clean2.sh
echo "[OK] Made pre-deploy-clean2.sh executable"

# STEP 3: Deploy to Railway
echo ""
echo "STEP 3: Ready to deploy"
echo "All files have been prepared. Ready to deploy to Railway."
echo ""
read -p "Do you want to deploy to Railway now? (y/n) " deploy_now

if [ "$deploy_now" == "y" ]; then
  echo "Deploying to Railway..."
  railway up
  
  if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Deployment succeeded! Your app should now be available on Railway."
  else
    echo ""
    echo "× Deployment failed. Please check the error message above."
  fi
else
  echo ""
  echo "Deployment skipped. To deploy manually, run: railway up"
fi

echo ""
echo "======================================="
echo "  RAILWAY DEPLOYMENT SCRIPT COMPLETE   "
echo "======================================="
