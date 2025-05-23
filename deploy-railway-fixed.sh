#!/bin/bash
# Enhanced Railway deployment script with directory conflict handling

set -e  # Exit on error

echo "======================================="
echo "  RAILWAY DEPLOYMENT WITH ERROR FIX    "
echo "======================================="
echo ""

# STEP 1: Fix directory conflicts
echo "STEP 1: Fixing directory conflicts..."

# Check for top-level app directory
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

# Create .railwayignore file to exclude problematic directories
echo "# Created by Railway deployment script
# This prevents conflicts with 'app' directories during deployment

# Ignore node_modules
node_modules/

# Ignore any app directories
**/app/

# Ignore cache directories that might cause issues
**/.cache/
**/__pycache__/" > .railwayignore

echo "✓ Created .railwayignore file"

# STEP 2: Ensure deploy-nixpacks.toml has proper output setting
echo "STEP 2: Updating Nixpacks configuration..."

nixpacks_file="deploy-nixpacks.toml"
if [ -f "$nixpacks_file" ]; then
  # Create backup
  cp "$nixpacks_file" "${nixpacks_file}.bak"
  
  # Check if build section exists
  if grep -q "\[phases\.build\]" "$nixpacks_file"; then
    # Check if output is already defined
    if ! grep -q "output\s*=" "$nixpacks_file"; then
      # Add output setting to build section
      sed -i '/\[phases\.build\]/a output = "railway-app"' "$nixpacks_file"
      echo "✓ Added custom output name to $nixpacks_file"
    else
      echo "✓ Custom output name already defined in $nixpacks_file"
    fi
  else
    # Add build section with output
    echo '
# Added by Railway deployment script
[phases.build]
output = "railway-app"' >> "$nixpacks_file"
    echo "✓ Added build section with custom output name to $nixpacks_file"
  fi
else
  echo "Creating minimal nixpacks configuration..."
  echo '# Created by Railway deployment script
# This configures Nixpacks to avoid "Is a directory" errors

[phases.build]
output = "railway-app"' > "$nixpacks_file"
  echo "✓ Created $nixpacks_file with custom output name"
fi

# STEP 3: Set up pre-deploy.sh improvements
echo "STEP 3: Setting up enhanced pre-deploy script..."

if [ -f "pre-deploy.sh" ]; then
  cp "pre-deploy.sh" "pre-deploy.sh.bak"
  
  # Update pre-deploy.sh to handle directory conflicts
  if [ -f "pre-deploy-enhanced.sh" ]; then
    cp "pre-deploy-enhanced.sh" "pre-deploy.sh"
    chmod +x "pre-deploy.sh"
    echo "✓ Copied enhanced pre-deploy script"
  else
    echo "⚠️ Warning: pre-deploy-enhanced.sh not found, enhancing existing script..."
    
    # Add directory conflict handling to the existing script
    conflict_handler='
# Handle directory conflicts
handle_path_conflict() {
  local path="$1"
  echo "Checking path: $path"
  
  if [ -e "$path" ] && [ ! -d "$path" ]; then
    echo "⚠️ WARNING: Path $path exists but is not a directory!"
    echo "Backing up conflicting file..."
    mv "$path" "${path}_file_bak_$(date +%s)"
    echo "✅ Renamed conflicting file"
  fi
  
  if [ ! -e "$path" ] && [ -d "$path" ]; then
    echo "⚠️ WARNING: Path $path exists as a directory but we need a file!"
    echo "Backing up conflicting directory..."
    mv "$path" "${path}_dir_bak_$(date +%s)"
    echo "✅ Renamed conflicting directory"
    mkdir -p "$(dirname "$path")"
  fi
}

# Check potential conflict paths
handle_path_conflict "frontend/backend/Repository.py"
handle_path_conflict "frontend/backend/server.js"
handle_path_conflict "app"
'
    # Insert the conflict handler after the shebang
    sed -i '/^#!/a'"$conflict_handler" "pre-deploy.sh"
    echo "✓ Added directory conflict handling to pre-deploy.sh"
  fi
else
  echo "⚠️ Warning: pre-deploy.sh not found, creating simplified version..."
  echo '#!/bin/bash
# Simple pre-deploy script for Railway

echo "Creating required directories..."
mkdir -p frontend/backend/uploads

echo "✅ Pre-deployment script completed"' > "pre-deploy.sh"
  chmod +x "pre-deploy.sh"
  echo "✓ Created simplified pre-deploy.sh"
fi

# STEP 4: Deploy to Railway
echo ""
echo "STEP 4: Ready to deploy"
echo "All fixes have been applied. The project is now ready for deployment."
echo ""
read -p "Do you want to deploy to Railway now? (y/n) " deploy_now

if [ "$deploy_now" == "y" ]; then
  echo "Deploying to Railway..."
  railway up
  
  if [ $? -eq 0 ]; then
    echo ""
    echo "Deployment succeeded! Check Railway dashboard for details."
  else
    echo ""
    echo "Deployment failed. Please check the error message above."
  fi
else
  echo ""
  echo "Deployment skipped. To deploy manually, run:"
  echo "railway up"
fi

echo ""
echo "======================================="
echo "  RAILWAY DEPLOYMENT SCRIPT COMPLETE   "
echo "======================================="
