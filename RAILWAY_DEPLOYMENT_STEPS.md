# Music Player Project - Railway Deployment Steps

This document outlines the steps to successfully deploy the Music Player Project (MPP) to Railway with SQL Server.

## Pre-Deployment Checks

1. **Verify file existence**:
   - ✅ Repository.py.railway
   - ✅ server.js.railway
   - ✅ requirements.txt (populated with dependencies)
   - ✅ pre-deploy.sh (with proper permissions)

2. **Verify required files have the correct contents**:
   - ✅ railway.json has correct build and deploy configuration
   - ✅ deploy-nixpacks.toml has SQL Server dependencies
   - ✅ railway.toml has proper environment variables

## Deployment Steps

1. **Link to your Railway project**:
   ```powershell
   railway link
   ```

2. **Deploy your application**:
   ```powershell
   railway up
   ```

3. **Run the database initialization script** (after deployment completes):
   ```powershell
   railway run "python frontend/backend/init_railway_db.py"
   ```

## Troubleshooting

If you encounter the "No start command could be found" error:

1. Verify that railway.json has the proper startCommand:
   ```json
   "startCommand": "npm start"
   ```

2. Verify that package.json has a valid start script:
   ```json
   "start": "node railway-up.js"
   ```

3. Ensure railway-up.js correctly handles environment detection and service startup.

## Environment Variables

Make sure these environment variables are set correctly in Railway:

- RAILWAY_DATABASE_HOST - Set automatically by Railway to the SQL Server service hostname
- RAILWAY_DATABASE_USER - "sa" (SQL Server admin user)
- RAILWAY_DATABASE_PASSWORD - "StrongPassword123!"
- RAILWAY_DATABASE_PORT - "1433" (SQL Server default port)

## Verifying Deployment

After deployment, visit your Railway dashboard to:

1. Check that all services are running properly
2. Verify logs for any errors
3. Test that both Flask and Node.js backends are functioning
4. Test that the frontend is loading and connecting to the backends
