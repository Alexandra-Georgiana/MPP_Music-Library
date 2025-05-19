@echo off
echo Deploying to Railway with comprehensive fixes for "Is a directory" error...
powershell -ExecutionPolicy Bypass -File "deploy-railway-robust-fixed.ps1"
if %ERRORLEVEL% NEQ 0 (
  echo Deployment encountered an error. Please check the messages above.
  pause
  exit /b 1
)
pause
