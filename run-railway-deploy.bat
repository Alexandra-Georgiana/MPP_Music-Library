@echo off
echo Bypassing PowerShell execution policy and running the deployment script...
powershell -ExecutionPolicy Bypass -File simple-railway-deploy.ps1
pause
