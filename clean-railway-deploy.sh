#!/bin/bash
# Railway clean deployment script
# Use this script to clean up unnecessary deployment files and fix the directory conflict

echo "========================================="
echo "  RAILWAY DEPLOYMENT CLEANUP             "
echo "========================================="

# Step 1: Remove redundant deployment files
echo "Removing redundant deployment files..."

# List of deployment scripts to keep
keep_files=(
  "railway-up.js"
  "deploy-nixpacks.toml"
  "railway.json"
  "pre-deploy-clean.sh"
  ".railwayignore-clean"
)

# Make backup directory for moved files
mkdir -p deployment_backups

# Move redundant deployment scripts to backup folder
for file in *.ps1 *.bat deploy-*.sh *-deploy.sh Fixed-*.ps1 Run-*.ps1 Check-*.ps1; do
  if [ -f "$file" ] && [[ ! " ${keep_files[@]} " =~ " ${file} " ]]; then
    echo "  Moving $file to deployment_backups/"
    mv "$file" "deployment_backups/" 2>/dev/null || true
  fi
done

# Step 2: Apply fixes for directory conflict
echo "Applying fixes for directory conflict..."

# Ensure we're using the clean pre-deploy script
if [ -f "pre-deploy-clean.sh" ]; then
  echo "  Setting up clean pre-deploy script..."
  cp pre-deploy-clean.sh pre-deploy.sh
  chmod +x pre-deploy.sh
fi

# Apply clean .railwayignore
if [ -f ".railwayignore-clean" ]; then
  echo "  Setting up clean .railwayignore..."
  cp .railwayignore-clean .railwayignore
fi

# Fix deploy-nixpacks.toml if needed
if [ -f "deploy-nixpacks.toml" ]; then
  echo "  Checking deploy-nixpacks.toml..."
  if ! grep -q "output = " deploy-nixpacks.toml; then
    echo '
# Added by cleanup script to avoid directory conflict
[phases.build]
output = "railway-app"' >> deploy-nixpacks.toml
    echo "  Added custom output name to deploy-nixpacks.toml"
  else
    echo "  deploy-nixpacks.toml already has output setting"
  fi
fi

# Step 3: Check for remaining app directory
echo "Checking for 'app' directory..."
if [ -d "app" ]; then
  echo "WARNING: 'app' directory still exists and will conflict with deployment!"
  read -p "Would you like to rename it? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    timestamp=$(date +%s)
    mv "app" "app_backup_${timestamp}"
    echo "  Renamed 'app' directory to app_backup_${timestamp}"
  fi
else
  echo "  No 'app' directory found, good!"
fi

echo "========================================="
echo "  CLEANUP COMPLETED                      "
echo "========================================="
echo "You can now deploy to Railway with:"
echo "  railway up"
echo "========================================="
