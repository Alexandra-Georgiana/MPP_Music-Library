#!/bin/bash
# Robust pre-deploy script to handle directory conflicts during Railway deployment

set -e

echo "===== RAILWAY PRE-DEPLOYMENT SETUP ====="

# Function to handle path conflicts more aggressively
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

# Check for app directory at various levels - Railway's Nixpacks uses these paths
echo "Checking for Nixpacks output directory conflicts..."

# Handle conflicting app directories at all potential paths
APP_PATHS=(
  "app"
  "./app"
  "/app"
  "dist/app"
  "./dist/app"
  "dist"
  "./dist"
  "dist_railway"
  "./dist_railway"
  "/tmp/nixpacks/app"
  "/opt/build/repo/app"
)

for app_path in "${APP_PATHS[@]}"; do
  if [ -d "$app_path" ]; then
    timestamp=$(date +%s)
    echo "WARNING: Found directory at $app_path which may conflict with Nixpacks output!"
    mv "$app_path" "${app_path}_backup_${timestamp}"
    echo "[OK] Renamed $app_path to ${app_path}_backup_${timestamp}"
  fi
done

# Create necessary directories
echo "Creating required directories..."
mkdir -p frontend/backend/uploads

# Check key paths for conflicts
handle_path_conflict "frontend/backend/Repository.py"
handle_path_conflict "frontend/backend/server.js"
handle_path_conflict "railway-up-clean.js"

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
