# Azure Deployment Troubleshooting Guide

This guide provides solutions for common issues that might occur during the Azure deployment of the Music Player Project.

## Table of Contents

1. [Frontend Issues](#frontend-issues)
2. [Backend API Issues](#backend-api-issues)
3. [Database Connection Issues](#database-connection-issues)
4. [HTTPS and SSL Issues](#https-and-ssl-issues)
5. [Docker/Container Issues](#dockercontainer-issues)
6. [SVG Display Issues](#svg-display-issues)
7. [Performance Issues](#performance-issues)

---

## Frontend Issues

### White Screen / Blank Page

**Symptoms:**
- Frontend loads but shows a blank white screen
- No visible elements appear on the page

**Possible Causes and Solutions:**

1. **JavaScript Error:**
   - Check browser console for errors
   - Fix JavaScript syntax or runtime errors in your code

2. **Build Issues:**
   - Ensure the build process completed successfully
   - Check frontend Docker logs: `az webapp log tail --name <frontend-app-name> --resource-group <resource-group-name>`

3. **Environment Variables Missing:**
   - Verify API URL environment variable is correctly set
   - Check `.env.production` or build-time variables

4. **CORS Issues:**
   - Add proper CORS headers in API responses
   - Configure allowed origins in backend

### Assets Not Loading

**Symptoms:**
- Page structure loads but images, fonts, or other assets are missing
- 404 errors in browser console for asset URLs

**Possible Causes and Solutions:**

1. **Path Issues:**
   - Make sure assets are included in the Docker image
   - Check paths and URL structure are correct

2. **Content Type Headers:**
   - Add appropriate MIME type mappings in nginx.conf
   - Set content type headers for SVG and other special file types

### App Loads But Can't Connect to API

**Symptoms:**
- UI loads but no data appears
- Network errors in console when trying to fetch data

**Possible Causes and Solutions:**

1. **API URL Incorrect:**
   - Check API base URL environment variable is correct
   - Make sure the API hostname resolves properly

2. **CORS Blocking Requests:**
   - Add proper CORS headers to API responses
   - Check browser console for specific CORS errors

---

## Backend API Issues

### API Returns 5xx Errors

**Symptoms:**
- Server returns 500, 502, or 504 errors
- Requests timeout or fail

**Possible Causes and Solutions:**

1. **Application Error:**
   - Check application logs: `az webapp log tail --name <api-app-name> --resource-group <resource-group-name>`
   - Look for exceptions in startup code

2. **Database Connection Issues:**
   - Verify connection string is correct
   - Check that database server is accessible from App Service

3. **Resource Limitations:**
   - Check if the App Service is hitting CPU/memory limits
   - Consider upgrading App Service plan tier

### API Returns 4xx Errors

**Symptoms:**
- Server returns 400, 401, 403, or 404 errors
- Specific API endpoints aren't found or accessible

**Possible Causes and Solutions:**

1. **Route Configuration:**
   - Check API route definitions
   - Ensure URL paths match between frontend and backend

2. **Authentication Issues:**
   - Verify credentials and tokens are correct
   - Check that auth middleware is properly configured

---

## Database Connection Issues

### Cannot Connect to Database

**Symptoms:**
- API logs show database connection errors
- "Cannot connect to server" or similar messages

**Possible Causes and Solutions:**

1. **Connection String Issues:**
   - Verify connection string format and credentials
   - Check for typos in server name, credentials, or database name

2. **Firewall Settings:**
   - Make sure Azure SQL firewall allows connections from App Service
   - Run this command to allow Azure services:
     ```powershell
     az sql server firewall-rule create --resource-group <resource-group> --server <server-name> --name AllowAzureServices --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0
     ```

3. **Network Security:**
   - Check VNet integration if being used
   - Verify subnet service endpoints are configured

### Missing Tables or Schema

**Symptoms:**
- "Table not found" errors
- API returns 500 errors when trying to query data

**Possible Causes and Solutions:**

1. **Database Not Initialized:**
   - Run the initialization script: `./init-database.ps1 -UseDeploymentOutput`
   - Check if schema scripts executed correctly

2. **Wrong Database:**
   - Verify you're connecting to the correct database name
   - Check if schema exists in the connected database

---

## HTTPS and SSL Issues

### SSL Certificate Errors

**Symptoms:**
- Browser shows "Your connection is not private" warning
- Certificate errors in browser console

**Possible Causes and Solutions:**

1. **Self-Signed Certificate in Production:**
   - Use Azure-provided certificates for production
   - Purchase a proper SSL certificate for custom domains

2. **Certificate Binding Issues:**
   - Check certificate is properly bound to hostname:
     ```powershell
     az webapp config ssl list --resource-group <resource-group-name>
     ```

3. **Certificate Mismatch:**
   - Make sure certificate is issued for the correct domain
   - Check certificate hasn't expired

### Mixed Content Warnings

**Symptoms:**
- Browser console shows mixed content warnings
- Some resources loaded over HTTP instead of HTTPS

**Possible Causes and Solutions:**

1. **Hardcoded HTTP URLs:**
   - Check for URLs that start with "http://" instead of "https://"
   - Use protocol-relative URLs (start with "//") or HTTPS

2. **External Resources:**
   - Make sure external services support HTTPS
   - Update CDN links to use HTTPS versions

---

## Docker/Container Issues

### Container Fails to Start

**Symptoms:**
- Container exits immediately after starting
- App Service shows container startup errors

**Possible Causes and Solutions:**

1. **Dockerfile Issues:**
   - Check that Dockerfile is correctly formatted
   - Ensure all dependencies are installed

2. **Environment Variables Missing:**
   - Make sure required environment variables are set in App Service configuration

3. **Startup Command Issues:**
   - Check the CMD or ENTRYPOINT directive in Dockerfile
   - Ensure startup script has execute permissions

### Container Starts But App Crashes

**Symptoms:**
- Container starts successfully but application crashes
- Error logs show runtime exceptions

**Possible Causes and Solutions:**

1. **Code Issues:**
   - Check application logs for exceptions
   - Fix any runtime errors in code

2. **Resource Limitations:**
   - Check if the container hits memory limits
   - Add appropriate memory/CPU allocations

---

## SVG Display Issues

### SVG Files Not Displaying

**Symptoms:**
- SVG images don't appear
- Placeholder or broken image icons show instead

**Possible Causes and Solutions:**

1. **Import Method:**
   - Use the `?url` suffix when importing SVGs in React:
     ```jsx
     import VinylSvg from "../../assets/Vinyl.svg?url";
     ```

2. **Vite Configuration:**
   - Check vite.config.js has proper SVG handling:
     ```js
     export default defineConfig({
       plugins: [react(), svgr()],
       assetsInclude: ['**/*.svg'],
     });
     ```

3. **Content Type Headers:**
   - Make sure server returns the correct MIME type for SVG files
   - Add to nginx.conf:
     ```
     types {
       image/svg+xml svg svgz;
     }
     ```

4. **Path Issues:**
   - Check file paths and URL structure
   - Make sure SVG files are included in the build

---

## Performance Issues

### Slow Initial Loading

**Symptoms:**
- First page load takes a long time
- Subsequent navigation is faster

**Possible Causes and Solutions:**

1. **Cold Start:**
   - Azure App Service may have cold starts
   - Consider using Always On setting for production apps

2. **Bundle Size:**
   - Check if JavaScript bundles are too large
   - Enable code splitting and lazy loading

3. **Image Optimization:**
   - Compress and optimize images
   - Consider using responsive images

### Slow API Responses

**Symptoms:**
- API calls take a long time to complete
- UI seems sluggish when fetching data

**Possible Causes and Solutions:**

1. **Database Performance:**
   - Check for missing indexes
   - Optimize SQL queries

2. **App Service Plan:**
   - Consider upgrading to a higher tier App Service Plan
   - Add more instances for high-traffic scenarios

3. **Caching:**
   - Implement API response caching
   - Use Azure Redis Cache for shared caching

---

## General Debugging Tips

### Viewing App Service Logs

To view logs from your deployed applications:

```powershell
# View real-time logs (tail)
az webapp log tail --name <app-name> --resource-group <resource-group-name>

# Download log files
az webapp log download --name <app-name> --resource-group <resource-group-name>
```

### Connecting to Container

For debugging within the container:

```powershell
# Use Azure CLI to get SSH connection to container
az webapp ssh --name <app-name> --resource-group <resource-group-name>
```

### Testing Database Connection

To test database connectivity:

```powershell
# Using sqlcmd
sqlcmd -S <server>.database.windows.net -d <database> -U <username> -P <password> -Q "SELECT @@VERSION"
```

---

## Getting More Help

If you continue experiencing issues:

1. Check Azure status page for service outages: https://status.azure.com/
2. Review Azure App Service documentation: https://docs.microsoft.com/en-us/azure/app-service/
3. Review SQL Server documentation: https://docs.microsoft.com/en-us/azure/azure-sql/
4. Reach out to Azure support if the issue persists
