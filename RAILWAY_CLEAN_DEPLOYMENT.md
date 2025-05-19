# Railway Deployment Fix for "Is a directory (os error 21)" Error

## Problem Description

The error "Is a directory (os error 21)" occurs during Railway deployment when Nixpacks tries to write to a path named 'app' that already exists as a directory. This conflict happens because Nixpacks uses 'app' as the default output directory name.

## Solution Files

The following clean files have been created to fix this issue:

1. **`pre-deploy-clean.sh`**: A clean pre-deploy script that:
   - Properly handles directory conflicts
   - Uses ASCII characters (no encoding issues)
   - Copies Railway-specific files correctly

2. **`railway-up-clean.js`**: A clean startup script that:
   - Handles directory path conflicts properly
   - Uses correct absolute paths
   - Has better error handling

3. **`.railwayignore-clean`**: An improved .railwayignore file that:
   - Properly ignores app directories
   - Ignores unnecessary deployment files
   - Uses ASCII characters only

4. **`railway-clean.json`**: A clean Railway configuration file that:
   - Uses the clean scripts
   - Has better startup commands

5. **`clean-railway-deploy.sh`**: A bash script that:
   - Cleans up unnecessary deployment files
   - Fixes the railway configuration
   - Checks for directory conflicts

6. **`deploy-railway-clean.ps1`**: A PowerShell script that:
   - Applies all fixes
   - Moves unused deployment files to a backup folder
   - Deploys to Railway

## How to Fix the Error

1. **Use one of these deployment methods:**

   **Option 1: PowerShell (Windows)**
   ```powershell
   # Run with execution policy bypass
   powershell -ExecutionPolicy Bypass -File deploy-railway-clean.ps1
   ```

   **Option 2: Bash (Linux/macOS)**
   ```bash
   # Make sure script is executable
   chmod +x clean-railway-deploy.sh
   ./clean-railway-deploy.sh
   
   # Then deploy
   railway up
   ```

2. **Manual Fix Steps:**

   1. Ensure no 'app' directory exists at the project root
   2. Update `deploy-nixpacks.toml` to set `output = "railway-app"`
   3. Use the clean pre-deployment script
   4. Use the clean .railwayignore file
   5. Deploy using `railway up`

## Why This Fixes the Issue

1. **Custom output name**: Setting `output = "railway-app"` in `deploy-nixpacks.toml` prevents Nixpacks from using the default 'app' directory.
2. **Directory conflict handling**: The clean scripts detect and fix conflicts between files and directories.
3. **Proper path handling**: The scripts use absolute paths to prevent directory navigation issues.
4. **Ignoring conflict paths**: The .railwayignore file prevents including any problematic app directories.

## Note on Cleanup

The clean deployment scripts will move unused deployment files to a `deployment_backups` directory. This keeps your project root clean while preserving all your deployment scripts.
