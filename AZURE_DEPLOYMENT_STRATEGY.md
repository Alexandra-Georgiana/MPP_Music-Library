# Complete Azure Deployment Strategy
# Music Player Project

## Overview

This document outlines the full deployment strategy for the Music Player Project to Azure without using GitHub Actions. It covers all the scripts and tools available for deployment and maintenance.

## Available Deployment Scripts

| Script | Description |
|--------|-------------|
| **deploy-azure-direct.ps1** | **[RECOMMENDED]** Master script that deploys the entire application stack to Azure directly from your machine |
| deploy-full-azure-fixed.ps1 | Original deployment script (requires GitHub Actions) |
| simple-deploy.ps1 | Simplified deployment script for basic setups |
| deploy-to-azure.ps1 | Individual component deployment to Azure |
| deploy-to-netlify.ps1 | Frontend-only deployment to Netlify |
| run-local-https.ps1 | Run the application locally with HTTPS |
| init-database.ps1 | Initialize database schema after deployment |
| test-deployment.ps1 | Test connectivity between deployed components |

## Deployment Methods

You have several options for deploying the Music Player Project:

### 1. Direct Azure Deployment (Recommended)

Complete deployment directly from your machine without GitHub Actions.

```powershell
# Run the direct deployment script
./deploy-azure-direct.ps1

# Test the deployment
./test-deployment.ps1

# Initialize the database if needed
./init-database.ps1 -UseDeploymentOutput
```

**Advantages:**
- No GitHub Actions required
- Complete control over the deployment process
- All components deployed and connected

### 2. Local Development with HTTPS

For testing and development purposes.

```powershell
# Start the application locally with HTTPS
./run-local-https.ps1
```

### 3. Frontend-Only Deployment to Netlify

Quick option for deploying just the frontend.

```powershell
# Deploy the frontend to Netlify
./deploy-to-netlify.ps1
```

## Deployment Process

The direct Azure deployment process includes:

1. **Checking prerequisites**
   - Azure CLI
   - Docker
   - Node.js and npm

2. **Setting up Azure resources**
   - Resource Group
   - Container Registry
   - SQL Server and Database
   - App Service Plan
   - Web Apps for frontend and backend

3. **Building and deploying components**
   - Building Docker images
   - Pushing to Azure Container Registry
   - Deploying to Azure App Service
   - Setting up environment variables and configuration

4. **Configuring HTTPS and connectivity**
   - Setting up SSL certificates
   - Configuring HTTPS endpoints
   - Connecting components

## Post-Deployment Steps

After deployment:

1. **Test the deployment**
   ```powershell
   ./test-deployment.ps1
   ```

2. **Initialize the database** (if needed)
   ```powershell
   ./init-database.ps1 -UseDeploymentOutput
   ```

3. **Monitor and troubleshoot** (see troubleshooting guide)

## Environment Variables

The following environment variables are used during deployment:

| Environment Variable | Description | Example Value |
|---------------------|-------------|---------------|
| SQL_SERVER_CONNECTION_STRING | Connection string for SQL Server | mssql+pyodbc://user:pass@server.database.windows.net:1433/MusicLibrary?driver=ODBC+Driver+17+for+SQL+Server |
| VITE_API_BASE_URL | URL of the backend API | https://api-app.azurewebsites.net |
| NODE_ENV | Node.js environment | production |
| FLASK_ENV | Flask environment | production |

## Documentation References

For more detailed information, refer to these guides:

- [DIRECT_DEPLOYMENT_GUIDE.md](./DIRECT_DEPLOYMENT_GUIDE.md) - Detailed guide for direct Azure deployment
- [AZURE_TROUBLESHOOTING.md](./AZURE_TROUBLESHOOTING.md) - Solutions for common deployment issues
- [DEPLOYMENT_GUIDE_ENHANCED.md](./DEPLOYMENT_GUIDE_ENHANCED.md) - Enhanced general deployment guide

## Azure Resources and Costs

The deployment creates the following Azure resources:

- **Azure App Service Plan** (B1 tier, ~$13.14/month)
- **Azure Web Apps** (2 instances, included in App Service Plan)
- **Azure SQL Server** (Basic tier, ~$4.90/month)
- **Azure Container Registry** (Basic tier, ~$5/month)

Estimated monthly cost: ~$23.04/month

## Security Considerations

- Database passwords are stored in Azure Web App settings (encrypted at rest)
- HTTPS is enabled for all endpoints
- Azure SQL Server firewall is configured to allow only Azure services
- SQL Server admin credentials should be stored securely

## Maintenance and Updates

To update the deployed application:

1. Make changes to your code
2. Run the deployment script again
3. Test your changes using the test-deployment script

## Removing the Deployment

To clean up all resources:

```powershell
# Delete the entire resource group
az group delete --name <resource-group-name> --yes
```

## Conclusion

This deployment strategy provides a complete solution for deploying the Music Player Project to Azure without requiring GitHub Actions. It includes all necessary components (frontend, backend API, database) with proper HTTPS support and connectivity.

For assistance with specific deployment issues, refer to the troubleshooting guide.
