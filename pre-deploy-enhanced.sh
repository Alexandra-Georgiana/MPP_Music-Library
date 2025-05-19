#!/bin/bash
# pre-deploy.sh - Run before deployment starts in Railway
set -euo pipefail  # More strict error handling

# Set up environment
echo "===== RAILWAY DEPLOYMENT SETUP ====="
echo "Setting up environment for Railway deployment..."

# Debug info
echo "Current directory: $(pwd)"
echo "Directory listing:"
ls -la

# Handle directory conflicts for paths that might be targeted by deployments
handle_path_conflict() {
  local path="$1"
  echo "Checking path: $path"
  
  # If path exists but isn't a directory and we need a directory
  if [ -e "$path" ] && [ ! -d "$path" ]; then
    echo "⚠️ WARNING: Path $path exists but is not a directory!"
    echo "Backing up conflicting file..."
    mv "$path" "${path}_file_bak_$(date +%s)"
    echo "✅ Renamed conflicting file"
  fi
  
  # If path exists but is a directory and we need a file (parent directory must exist)
  if [ ! -e "$path" ] && [ -d "$path" ]; then
    echo "⚠️ WARNING: Path $path exists as a directory but we need a file!"
    echo "Backing up conflicting directory..."
    mv "$path" "${path}_dir_bak_$(date +%s)"
    echo "✅ Renamed conflicting directory"
    # Ensure parent directory exists
    mkdir -p "$(dirname "$path")"
  fi
}

# Make sure all needed directories exist with conflict resolution
echo "Creating required directories..."
for dir in "frontend/backend/uploads" "app"; do
  handle_path_conflict "$dir"
  mkdir -p "$dir"
  echo "✅ Created directory: $dir"
done

# Check for required files
echo "Checking for required deployment files..."
if [ ! -d "frontend" ]; then
  echo "❌ ERROR: frontend directory does not exist! Current directory:"
  pwd
  ls -la
  exit 1
fi

if [ ! -d "frontend/backend" ]; then
  echo "❌ ERROR: frontend/backend directory does not exist!"
  ls -la frontend/
  exit 1
fi

# Check if Railway-specific files exist
echo "Checking for Railway-specific files..."

# Handle Repository.py file - check if the target might be a directory
handle_path_conflict "frontend/backend/Repository.py"

if [ -f frontend/backend/Repository.py.railway ]; then
  echo "✅ Found Repository.py.railway"
  echo "Copying Railway-specific Repository.py..."
  cp -f frontend/backend/Repository.py.railway frontend/backend/Repository.py
  if [ $? -eq 0 ]; then
    echo "✅ Successfully copied Repository.py.railway to Repository.py"
  else
    echo "❌ Error copying Repository.py.railway"
    # Create an emergency backup
    echo "Creating emergency Repository.py..."
    echo 'from flask import Flask, jsonify
import os
app = Flask(__name__)
@app.route("/")
def hello():
    return jsonify({"status": "OK", "message": "Emergency Flask server is running"})
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 5000)))' > frontend/backend/Repository.py
  fi
else
  echo "⚠️ Warning: Repository.py.railway not found"
  echo "Contents of frontend/backend:"
  ls -la frontend/backend/ || echo "Could not list directory"
  # Create an emergency file
  echo "Creating emergency Repository.py..."
  echo 'from flask import Flask, jsonify
import os
app = Flask(__name__)
@app.route("/")
def hello():
    return jsonify({"status": "OK", "message": "Emergency Flask server is running"})
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 5000)))' > frontend/backend/Repository.py
fi

# Handle server.js file - check if the target might be a directory
handle_path_conflict "frontend/backend/server.js"

if [ -f frontend/backend/server.js.railway ]; then
  echo "✅ Found server.js.railway"
  echo "Copying Railway-specific server.js..."
  cp -f frontend/backend/server.js.railway frontend/backend/server.js
  if [ $? -eq 0 ]; then
    echo "✅ Successfully copied server.js.railway to server.js"
  else
    echo "❌ Error copying server.js.railway"
    # Create an emergency backup
    echo "Creating emergency server.js..."
    echo 'const express = require("express");
const app = express();
const PORT = process.env.PORT || 3000;
app.get("/", (req, res) => {
  res.json({ status: "OK", message: "Emergency Node.js server is running" });
});
app.listen(PORT, () => console.log(`Emergency server listening on port ${PORT}`));' > frontend/backend/server.js
  fi
else
  echo "⚠️ Warning: server.js.railway not found"
  echo "Contents of frontend/backend:"
  ls -la frontend/backend/ || echo "Could not list directory"
  # Create an emergency file
  echo "Creating emergency server.js..."
  echo 'const express = require("express");
const app = express();
const PORT = process.env.PORT || 3000;
app.get("/", (req, res) => {
  res.json({ status: "OK", message: "Emergency Node.js server is running" });
});
app.listen(PORT, () => console.log(`Emergency server listening on port ${PORT}`));' > frontend/backend/server.js
fi

# Create .railwayignore file for additional safety
echo "Creating .railwayignore file..."
cat > .railwayignore << EOL
# Created by pre-deploy.sh
# This helps prevent 'Is a directory' errors

# Ignore node_modules
node_modules/

# Ignore any conflicting app directories
**/app/
**/__pycache__/
**/.cache/
EOL

echo "✅ Created .railwayignore file"

# Final deployment preparation
echo "✅ Pre-deployment script completed successfully"
