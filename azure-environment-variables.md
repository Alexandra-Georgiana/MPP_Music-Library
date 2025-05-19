# Environment Variables for Azure Container Apps

# This file lists all the environment variables that should be set in Azure Container Apps
# These variables will be used by the application during runtime

# You can set these variables in the Azure Portal or using the Azure CLI
# To set using Azure CLI, use the following command:
# az containerapp update -n <app-name> -g <resource-group> --set-env-vars "KEY=VALUE"

# Database Connection
SQL_SERVER_CONNECTION_STRING="mssql+pyodbc://${sqlAdminUser}:${sqlAdminPassword}@${sqlServerName}.database.windows.net:1433/${sqlDbName}?driver=ODBC+Driver+17+for+SQL+Server"
NODE_DB_CONNECTION="mssql://${sqlAdminUser}:${sqlAdminPassword}@${sqlServerName}.database.windows.net:1433/${sqlDbName}"

# API Configuration
API_URL="https://your-api-domain.azurewebsites.net"
FRONTEND_URL="https://your-frontend-domain.azurewebsites.net"

# Authentication
JWT_SECRET="your-secure-jwt-secret-key"
TOKEN_EXPIRATION="24h"

# CORS Settings
CORS_ALLOWED_ORIGINS="https://your-frontend-domain.azurewebsites.net"

# File Storage
UPLOAD_DIR="/app/uploads"
MAX_FILE_SIZE="50000000"  # 50MB in bytes

# App Configuration
NODE_ENV="production"
PORT="3000"
FLASK_ENV="production"
FLASK_PORT="5000"

# Note: Replace placeholder values with actual values after deployment
# This file is just for reference and won't be directly used in deployment
# These variables need to be set in the Azure Container App configuration
