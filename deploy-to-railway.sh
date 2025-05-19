#!/bin/bash
# Railway deployment script

echo "Deploying to Railway..."

# Log in to Railway (if you're not already logged in)
# You'll need to have the Railway CLI installed
# npm install -g @railway/cli
# railway login

# Link to an existing project (if not already linked)
railway link

# Deploy to Railway
railway up

echo "Deployment completed!"
echo "Now initializing database..."

# Initialize the database
railway run python frontend/backend/init_railway_db.py

echo "Setup completed! Your application should be available on Railway."
