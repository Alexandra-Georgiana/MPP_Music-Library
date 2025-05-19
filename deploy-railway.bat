@echo off
echo Deploying to Railway with fixes for "Is a directory" error...
powershell -ExecutionPolicy Bypass -File "railway-deploy-fixed.ps1"
pause
