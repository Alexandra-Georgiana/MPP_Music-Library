# Railway Deployment Instructions

This document provides instructions for deploying the Music Player Project (MPP) to Railway.

## Pre-Deployment Setup

1. Install the Railway CLI:
```bash
npm install -g @railway/cli
```

2. Login to Railway:
```bash
railway login
```

## Deployment Process

1. Initialize Railway project (if not already done):
```bash
railway init
```

2. Link to existing project (if already created on Railway):
```bash
railway link
```

3. Deploy the application:
```bash
railway up
```

4. Initialize the database (after deployment):
```bash
railway run python frontend/backend/init_railway_db.py
```

## Configuration Files

The project includes the following Railway configuration files:

- `railway.json`: Main Railway configuration
- `railway.toml`: Service definitions
- `nixpacks.toml`: Build configuration
- `Procfile`: Process definitions
- `.nixpacks`: Simple Nixpacks configuration

## Environment Variables

Railway will automatically set these environment variables:

- `RAILWAY_ENVIRONMENT`: The environment name (e.g., production)
- `DATABASE_URL`: Connection string for PostgreSQL (if provisioned)
- `RAILWAY_SERVICE_*_URL`: URLs for each service

## Troubleshooting

If you encounter the "No start command could be found" error:
1. Ensure `package.json` has a valid `start` script
2. Check that `railway.json` has a valid `startCommand`
3. Verify the `nixpacks.toml` file has a proper `[start]` section

## Services

The application uses three main services:
1. Flask backend (web)
2. Node.js backend (worker)
3. SQL Server database (available as both SQL Server and PostgreSQL options)

Each service is defined in `railway.toml` with appropriate configuration.
