# Direct Azure Deployment Guide (No GitHub Actions)

This document explains the `deploy-azure-direct.ps1` script which allows you to deploy your Music Player Project to Azure without requiring GitHub Actions.

## Overview

The deployment script handles all aspects of deployment:

1. Creating all necessary Azure resources
2. Building and containerizing your frontend and backend applications
3. Deploying the containers to Azure App Service
4. Setting up HTTPS with SSL certificates
5. Configuring the SQL Server database
6. Connecting all components together

## Key Benefits

- **No GitHub Actions Required**: Deploys directly from your machine
- **Full HTTPS Support**: Secures your application with SSL
- **Complete Deployment**: Frontend, backend API, and SQL database
- **Interactive Setup**: Prompts for necessary configuration values
- **Resource Naming**: Automatically generates unique names for Azure resources
- **Comprehensive Output**: Creates a JSON file with all deployment details

## How It Differs from Previous Approach

| **Feature**                 | **Previous Approach**             | **New Direct Deployment**         |
|-----------------------------|-----------------------------------|-----------------------------------|
| **Deployment Method**       | GitHub Actions workflow           | Direct PowerShell script          |
| **Source Code Access**      | Requires GitHub repository        | Uses local code                   |
| **Container Deployment**    | Azure Container Apps              | Azure App Service                 |
| **Deployment Time**         | Depends on GitHub Actions runtime | Usually faster (local build)      |
| **Cost**                    | Uses GitHub Actions minutes       | No GitHub Actions costs           |
| **SSL Configuration**       | During container build            | Azure App Service SSL binding     |

## Prerequisites

Before running the deployment script, ensure you have:

- Azure CLI installed and updated
- Docker Desktop installed and running
- PowerShell 5.1 or higher
- Node.js and npm installed
- Active Azure subscription

## Running the Deployment Script

1. Open PowerShell as administrator
2. Navigate to your project directory
3. Run the script:

```powershell
./deploy-azure-direct.ps1
```

4. Follow the interactive prompts to configure your deployment
5. Wait for the deployment to complete (approximately 15-20 minutes)

## Post-Deployment Steps

After deployment completes:

1. Access your frontend at the URL provided in the output
2. Test the API endpoints to ensure the backend is working correctly
3. Verify that the database connection is working properly
4. Check the Azure Portal to see all created resources

## Troubleshooting

If you encounter issues:

- Check the `azure-deployment-output.json` file for resource details
- Look at the Azure App Service logs in the Azure Portal
- Review SQL Server connection strings if database connectivity fails
- Verify network rules if components cannot communicate

## Managing Deployed Resources

- To update your deployment, run the script again
- To clean up resources, delete the resource group in Azure Portal:
  ```powershell
  az group delete --name <your-resource-group-name> --yes --no-wait
  ```

## SSL Certificate Management

The script sets up HTTPS using:
1. Self-signed certificates for development, or
2. Azure App Service's managed certificates for production

For production use, you can later add a custom domain and certificate through the Azure Portal.

---

This deployment approach gives you full control over the deployment process without relying on GitHub Actions, while still achieving the same end result of a fully deployed application stack with HTTPS support.
