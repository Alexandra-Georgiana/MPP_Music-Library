#!/bin/bash
# Clean pre-deploy script for Railway deployment
# Handles directory conflicts and prepares environment

set -e

echo "===== RAILWAY PRE-DEPLOYMENT SETUP ====="

# Function to handle path conflicts
handle_path_conflict() {
  local path="$1"
  echo "Checking path: $path"
  
  # If path exists as a file but we need a directory
  if [ -e "$path" ] && [ ! -d "$path" ]; then
    echo "WARNING: Path $path exists but is not a directory!"
    echo "Backing up conflicting file..."
    mv "$path" "${path}_file_bak_$(date +%s)"
    echo "[OK] Renamed conflicting file"
  fi
  
  # If path exists as a directory but we need a file
  if [ -d "$path" ]; then
    echo "WARNING: Path $path exists as a directory but we need a file!"
    echo "Backing up conflicting directory..."
    mv "$path" "${path}_dir_bak_$(date +%s)"
    echo "[OK] Renamed conflicting directory"
    mkdir -p "$(dirname "$path")"
  fi
}

# Check and fix the 'app' directory issue
echo "Checking for potential 'app' directory conflicts..."
if [ -d "app" ]; then
  echo "WARNING: Found 'app' directory which conflicts with Nixpacks output!"
  timestamp=$(date +%s)
  mv "app" "app_backup_${timestamp}"
  echo "[OK] Renamed 'app' directory to app_backup_${timestamp}"
fi

# Check key paths for conflicts
handle_path_conflict "frontend/backend/Repository.py"
handle_path_conflict "frontend/backend/server.js"

# Create necessary directories
echo "Creating required directories..."
mkdir -p frontend/backend/uploads

# Copy Railway-specific configuration files
echo "Setting up Railway-specific files..."

# Copy Repository.py for Railway
if [ -f frontend/backend/Repository.py.railway ]; then
  echo "[OK] Found Repository.py.railway"
  cp -f frontend/backend/Repository.py.railway frontend/backend/Repository.py
  echo "[OK] Copied Repository.py.railway to Repository.py"
else
  echo "WARNING: Repository.py.railway not found"
fi

# Copy server.js for Railway
if [ -f frontend/backend/server.js.railway ]; then
  echo "[OK] Found server.js.railway"
  cp -f frontend/backend/server.js.railway frontend/backend/server.js
  echo "[OK] Copied server.js.railway to server.js"
else
  echo "WARNING: server.js.railway not found"
fi

echo "[OK] Pre-deployment setup completed successfully"
