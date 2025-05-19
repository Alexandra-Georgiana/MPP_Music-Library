# SQL Server on Railway - Deployment Guide

This document explains how to deploy the Music Player Project with SQL Server on Railway.

## Database Connection Strategy

The project uses SQL Server for database storage with these connection configurations:

1. **Local Development**: Uses Windows Authentication
   ```
   DRIVER={ODBC Driver 17 for SQL Server};SERVER=USER\\MSSQLSERVER03;DATABASE=MusicLibrary;Trusted_Connection=yes;
   ```

2. **Railway Deployment**: Uses SQL Server Authentication
   ```
   mssql+pyodbc://sa:StrongPassword123!@sqlserver:1433/MusicLibrary?driver=ODBC+Driver+17+for+SQL+Server
   ```

## Railway Service Configuration

Railway is configured with these services:

1. **flask-backend**: Python Flask API
   - Handles user authentication, song management, and more
   - Connected to SQL Server

2. **node-backend**: Node.js API 
   - Handles additional functionality and file uploads
   - Connected to SQL Server

3. **frontend**: React.js static site
   - User interface
   - Connects to both backends

4. **sqlserver**: SQL Server 2019 Express
   - Uses Docker image: mcr.microsoft.com/mssql/server:2019-latest
   - Requires these environment variables:
     - ACCEPT_EULA=Y
     - SA_PASSWORD=StrongPassword123!
     - MSSQL_PID=Express

## Deployment Process

1. The build process copies the Railway-specific versions of files:
   - `Repository.py.railway` → `Repository.py`
   - `server.js.railway` → `server.js`

2. The Railway-specific files are configured to:
   - Use SQL Server authentication instead of Windows authentication
   - Detect the Railway environment and adapt accordingly
   - Connect to the SQL Server service by hostname

3. Database initialization:
   - The `init_railway_db.py` script creates and populates the database
   - It waits for SQL Server to be ready before proceeding

## Environment Variables

Railway provides these environment variables:
- `RAILWAY_ENVIRONMENT` - Indicates we're on Railway
- `RAILWAY_DATABASE_HOST` - SQL Server hostname
- `RAILWAY_DATABASE_USER` - User (sa)
- `RAILWAY_DATABASE_PASSWORD` - Password
- `RAILWAY_DATABASE_PORT` - Port (1433)

## Troubleshooting

If you encounter "No start command could be found", check:
1. The `railway.json` file has the proper `startCommand`
2. The `deploy-nixpacks.toml` file has correct `[start]` and `[processes]` sections
3. The `package.json` file has a valid `start` script
