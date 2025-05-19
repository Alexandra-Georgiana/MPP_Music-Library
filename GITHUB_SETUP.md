# GitHub Repository Setup for Deployment

To deploy your application using the GitHub Actions workflow:

1. Create a GitHub repository and push your code:
   ```powershell
   git init
   git add .
   git commit -m "Initial commit"
   git branch -M main
   git remote add origin https://github.com/your-username/mpp.git
   git push -u origin main
   ```

2. Configure the necessary GitHub secrets:
   - AZURE_CREDENTIALS: JSON output from `az ad sp create-for-rbac`
   - SQL_ADMIN_PASSWORD: Secure password for your SQL Server
   - SSL_CERTIFICATE: Your SSL certificate content (from certificate.crt)
   - SSL_PRIVATE_KEY: Your SSL private key content (from private.key)

3. Update the placeholders in azure-deploy-sqlserver.yml:
   - Replace "mppregistryxxxx" with a unique name for your container registry
   - Replace "your-domain.com" with your actual domain (optional)

4. Push the changes to trigger deployment:
   ```powershell
   git add .
   git commit -m "Update deployment configuration"
   git push
   ```

5. Monitor the deployment in the "Actions" tab of your GitHub repository
