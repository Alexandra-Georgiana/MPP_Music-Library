# Music Player Project - Railway Deployment

This document explains how to deploy the Music Player Project to Railway.

## Deployment Options

### Option 1: Using the Railway CLI (Recommended for Initial Setup)

1. Make sure you have the Railway CLI installed:
   ```
   npm i -g @railway/cli
   ```

2. Run the deployment script:
   ```
   .\railway-deploy.ps1
   ```

3. Initialize the database after deployment:
   ```
   railway run python frontend/backend/init_railway_db.py
   ```

### Option 2: Continuous Deployment with GitHub

1. Push your project to GitHub.
2. Connect your repository in the Railway dashboard.
3. Configure auto-deployments for your chosen branch.

## Files to Push to Git

The following files should be committed to your Git repository:

```
railway.json
railway.toml
nixpacks.toml
nixpkgs.json
Procfile
frontend/backend/init_railway_db.py
frontend/backend/Repository.py.railway
frontend/backend/server.js.railway
```

Make sure to rename the `.railway` versions of the files to their standard names:
- `Repository.py.railway` → `Repository.py`
- `server.js.railway` → `server.js`

## Environment Variables

The following environment variables are set automatically by Railway or can be set manually:

- `PORT` - The port to run the application on (set by Railway)
- `DATABASE_URL` - Connection string for SQL Server (set by Railway when using their DB)
- `FLASK_ENV` - Set to "production" for deployment
- `NODE_ENV` - Set to "production" for deployment
- `JWT_SECRET_KEY` - Secret key for JWT token generation
- `USE_HTTPS` - Set to "false" on Railway as they handle HTTPS automatically

## Database Migration

After deploying for the first time, run the database migration script:

```
railway run python frontend/backend/init_railway_db.py
```

## Testing the Deployment

After successful deployment, test the following endpoints:

- Flask API: `https://<your-railway-subdomain>.railway.app/`
- Node.js API: `https://<your-railway-subdomain>.railway.app/`

## Troubleshooting

- Check logs: `railway logs`
- SSH into service: `railway shell`
- Restart service: `railway service restart`
