# Comprehensive Deployment Guide for Music Player Application

This guide provides step-by-step instructions for deploying the Music Player Application to Azure with full HTTPS support.

## Table of Contents
1. [Deployment Options](#deployment-options)
2. [Prerequisites](#prerequisites)
3. [Full Azure Deployment](#full-azure-deployment)
4. [Quick Netlify Deployment (Frontend Only)](#quick-netlify-deployment-frontend-only)
5. [Testing Your Deployment](#testing-your-deployment)
6. [Troubleshooting](#troubleshooting)

## Deployment Options

You have several options for deploying this application:

1. **Full Azure Deployment**: Deploy frontend, backend, and SQL database to Azure (recommended for production)
2. **Netlify Deployment**: Deploy only the frontend to Netlify (quick option for testing)
3. **Local HTTPS Deployment**: Run the application locally with HTTPS for testing

## Prerequisites

Before proceeding with the deployment, ensure you have:

1. **Azure Account**: An active Azure subscription
2. **Azure CLI**: Installed and configured
3. **Docker**: Docker Desktop installed and running
4. **PowerShell**: PowerShell 5.1 or higher
5. **Node.js & NPM**: Latest stable version

## Full Azure Deployment

The simplest way to deploy the full application is to run the master deployment script:

```powershell
./deploy-full-azure.ps1
```

This script handles:
- SSL certificate generation
- Azure resource setup
- Application build and deployment
- Connection configuration

### Manual Step-by-Step Deployment

If you prefer to perform the deployment step by step:

1. **Generate SSL certificates**:
   ```powershell
   ./setup-ssl.ps1
   ```

2. **Set up Azure resources**:
   ```powershell
   ./setup-azure.ps1
   ```
   
3. **Deploy to Azure**:
   ```powershell
   ./deploy-to-azure.ps1
   ```

## Quick Netlify Deployment (Frontend Only)

For a quick frontend-only deployment to test the UI:

1. **Build the frontend**:
   ```powershell
   cd frontend
   npm install
   npm run build
   ```

2. **Deploy to Netlify**:
   ```powershell
   npm install -g netlify-cli
   netlify deploy --dir=dist
   ```

3. To deploy to production:
   ```powershell
   netlify deploy --dir=dist --prod
   ```

Note: With frontend-only deployment, you'll need to update the API endpoints to point to your backend services.

## Testing Your Deployment

After deployment:

1. **Access your frontend**: Use the URL provided in the deployment output
2. **Test the API endpoints**: Try accessing `https://your-app-url/api/songs`
3. **Verify HTTPS**: Ensure the connection is secure (look for the lock icon)

## Troubleshooting

### SVG Files Not Displaying

If SVG files are not displaying properly:
- Check that SVGs are imported with the `?url` suffix in React components
- Verify Vite is configured to handle SVGs correctly
- Check network requests in browser dev tools

### Database Connection Issues

If you're experiencing database connection problems:
- Verify the connection string in the environment variables
- Check that the SQL Server firewall allows connections
- Verify SQL Server credentials

### SSL Certificate Errors

If you encounter SSL certificate errors:
- For local development, add the self-signed certificate to your trusted roots
- For Azure, ensure you're using valid certificates
- Check SSL configuration in your nginx setup

### CORS Errors

If you see CORS-related errors in the browser console:
- Verify CORS headers are set correctly in your backend
- Check that frontend is making requests to the correct URLs
- Ensure your backend allows requests from your frontend domain

## Need Help?

If you encounter issues not covered in this guide, please:
1. Check the Azure Portal for service logs and diagnostics
2. Review the Docker logs for container-specific issues
3. Reach out to the development team for support
