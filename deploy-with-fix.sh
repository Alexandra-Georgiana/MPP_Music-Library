#!/bin/bash
# deploy-with-fix.sh - Script to deploy with fix for "Is a directory" error

echo "===== Railway Deployment with Directory Fix ====="
echo "This script will deploy your app to Railway with fixes for the 'Is a directory' error"

# Verify files exist
if [ ! -f railway.json ]; then
  echo "ERROR: railway.json not found in current directory"
  exit 1
fi

if [ ! -f deploy-nixpacks.toml ]; then
  echo "ERROR: deploy-nixpacks.toml not found in current directory"
  exit 1
fi

# Make pre-deploy.sh executable
chmod +x pre-deploy.sh

# Check if Railway CLI is installed
if ! command -v railway &> /dev/null; then
  echo "Railway CLI not found. Installing..."
  npm install -g @railway/cli
fi

# Check if logged in
if ! railway whoami &> /dev/null; then
  echo "Please login to Railway:"
  railway login
fi

# Ensure requirements.txt is not empty
mkdir -p frontend/backend
if [ ! -s frontend/backend/requirements.txt ]; then
  echo "Creating/updating requirements.txt with necessary dependencies..."
  cat > frontend/backend/requirements.txt << EOF
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
EOF
  echo "requirements.txt created/updated"
fi

# Create minimal server files if they don't exist
if [ ! -f frontend/backend/Repository.py.railway ]; then
  echo "Creating minimal Repository.py.railway..."
  cat > frontend/backend/Repository.py.railway << EOF
from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route('/')
def home():
    return jsonify({"status": "OK", "message": "Flask server running"})

if __name__ == '__main__':
    port = int(os.environ.get("PORT", 5000))
    app.run(host='0.0.0.0', port=port)
EOF
  echo "Repository.py.railway created"
fi

if [ ! -f frontend/backend/server.js.railway ]; then
  echo "Creating minimal server.js.railway..."
  cat > frontend/backend/server.js.railway << EOF
const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.json({ status: 'OK', message: 'Node.js server running' });
});

app.listen(PORT, () => console.log(\`Server running on port \${PORT}\`));
EOF
  echo "server.js.railway created"
fi

# Create package.json in backend if it doesn't exist
if [ ! -f frontend/backend/package.json ]; then
  echo "Creating minimal package.json in backend directory..."
  cat > frontend/backend/package.json << EOF
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
EOF
  echo "backend package.json created"
fi

echo "Deploying to Railway..."
railway up

if [ $? -eq 0 ]; then
  echo "✅ Deployment successful!"
  echo "You can run the database initialization with:"
  echo "railway run \"python frontend/backend/init_railway_db.py\""
else
  echo "❌ Deployment failed with error code $?"
fi
