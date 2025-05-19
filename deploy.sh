#!/bin/bash
# Railway deployment script

echo "Starting Music Player Project..."

# Check if we're running the web or worker process
if [ "$RAILWAY_SERVICE_NAME" == "worker" ]; then
    echo "Starting Node.js backend..."
    cd frontend/backend
    node server.js
else
    echo "Starting Flask backend..."
    cd frontend/backend
    python Repository.py
fi
