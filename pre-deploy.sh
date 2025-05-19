#!/bin/bash
# pre-deploy.sh - Runs before the application starts in Railway

# Set up environment
echo "Setting up environment for Railway deployment..."

# Create required directories if they don't exist
mkdir -p frontend/backend/uploads

# Copy Railway-specific files
echo "Copying Railway-specific Repository.py..."
cp -f frontend/backend/Repository.py.railway frontend/backend/Repository.py
echo "Copying Railway-specific server.js..."
cp -f frontend/backend/server.js.railway frontend/backend/server.js

# Print debug info
echo "Deployment environment: SQL Server mode"
echo "Current directory: $(pwd)"
ls -la frontend/backend/

# Set permissions
chmod +x frontend/backend/init_railway_db.py
chmod +x frontend/backend/docker-entrypoint.sh

# Print environment information
echo "Railway environment: $RAILWAY_ENVIRONMENT"
echo "Railway service: $RAILWAY_SERVICE_NAME"
echo "Database host: $RAILWAY_DATABASE_HOST"

# Success message
echo "Pre-deployment setup completed successfully"
