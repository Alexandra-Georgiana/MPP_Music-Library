#!/bin/bash
# fix-railway-directory-error.sh
# Script to fix "Is a directory (os error 21)" error in Railway deployment

echo "===== RAILWAY DIRECTORY ERROR FIX ====="
echo "This script will fix the 'Is a directory (os error 21)' error in your Railway deployment"

# Check if we're in the project root
if [ ! -f "railway.json" ]; then
    echo "ERROR: railway.json not found. Make sure you're in the project root directory."
    exit 1
fi

# 1. Check for directory path conflicts
echo -e "\nChecking for directory path conflicts..."

# Ensure the uploads directory exists with proper structure
echo "Ensuring proper uploads directory structure..."
mkdir -p frontend/backend/uploads
echo "✓ Created/verified frontend/backend/uploads directory"

# 2. Fix railway-up.js path handling
echo -e "\nChecking railway-up.js for path handling issues..."
RAILWAY_UP_PATH="./railway-up.js"

if [ -f "$RAILWAY_UP_PATH" ]; then
    # Backup the original file
    cp "$RAILWAY_UP_PATH" "${RAILWAY_UP_PATH}.bak"
    echo "✓ Created backup of railway-up.js at railway-up.js.bak"
    
    # Fix path handling in executeCommand function
    if grep -q "fs.existsSync(options.cwd)" "$RAILWAY_UP_PATH"; then
        echo "Fixing directory handling in railway-up.js..."
        
        # Replace the directory check with improved version
        sed -i -E 's/if \(!fs\.existsSync\(options\.cwd\)\) \{([^}]+)\}/if (!fs.existsSync(options.cwd)) {\n        console.error(`ERROR: Working directory does not exist: ${options.cwd}`);\n        console.log('\''Creating directory...'\'');\n        try {\n            \/\/ Make sure we don'\''t try to create a directory that'\''s actually a file\n            if (fs.existsSync(options.cwd.replace(\/\\\/[^\\\/]+$\/, '\'''\''))) {\n                const parentDir = options.cwd.replace(\/\\\/[^\\\/]+$\/, '\'''\'')\;\n                if (fs.statSync(parentDir).isFile()) {\n                    console.error(`ERROR: Parent path is a file, not a directory: ${parentDir}`);\n                    process.exit(1);\n                }\n            }\n            fs.mkdirSync(options.cwd, { recursive: true });\n        } catch (err) {\n            console.error(`Failed to create directory: ${err.message}`);\n            process.exit(1);\n        }\n/' "$RAILWAY_UP_PATH"
        
        # Update file recovery logic to check for directory conflicts
        sed -i -E 's/if \(!fs\.existsSync\(repositoryPath\) && fs\.existsSync\(path\.join\(backendPath, '\''Repository\.py\.railway'\''\)\)\) \{([^}]+)\}/if (!fs.existsSync(repositoryPath) \&\& fs.existsSync(path.join(backendPath, '\''Repository.py.railway'\''))) {\n        console.log('\''Copying Repository.py.railway to Repository.py...'\'');\n        try {\n            \/\/ Check if repositoryPath is a directory, which would cause "Is a directory" error\n            if (fs.existsSync(repositoryPath) \&\& fs.statSync(repositoryPath).isDirectory()) {\n                console.error(`ERROR: Repository.py path exists but is a directory: ${repositoryPath}`);\n                \/\/ Rename the directory to resolve conflict\n                const backupDirName = `${repositoryPath}_directory_bak_${Date.now()}`;\n                fs.renameSync(repositoryPath, backupDirName);\n                console.log(`Renamed conflicting directory to: ${backupDirName}`);\n            }\n            fs.copyFileSync(path.join(backendPath, '\''Repository.py.railway'\''), repositoryPath);/' "$RAILWAY_UP_PATH"
        
        # Update server.js recovery logic as well
        sed -i -E 's/if \(!fs\.existsSync\(serverJsPath\) && fs\.existsSync\(path\.join\(backendPath, '\''server\.js\.railway'\''\)\)\) \{([^}]+)\}/if (!fs.existsSync(serverJsPath) \&\& fs.existsSync(path.join(backendPath, '\''server.js.railway'\''))) {\n        console.log('\''Copying server.js.railway to server.js...'\'');\n        try {\n            \/\/ Check if serverJsPath is a directory, which would cause "Is a directory" error\n            if (fs.existsSync(serverJsPath) \&\& fs.statSync(serverJsPath).isDirectory()) {\n                console.error(`ERROR: server.js path exists but is a directory: ${serverJsPath}`);\n                \/\/ Rename the directory to resolve conflict\n                const backupDirName = `${serverJsPath}_directory_bak_${Date.now()}`;\n                fs.renameSync(serverJsPath, backupDirName);\n                console.log(`Renamed conflicting directory to: ${backupDirName}`);\n            }\n            fs.copyFileSync(path.join(backendPath, '\''server.js.railway'\''), serverJsPath);/' "$RAILWAY_UP_PATH"
        
        echo "✓ Fixed railway-up.js script"
    else
        echo "No issues found in railway-up.js"
    fi
else
    echo "⚠️ railway-up.js not found"
fi

# 3. Check the pre-deploy.sh script
echo -e "\nChecking pre-deploy.sh script..."
PRE_DEPLOY_PATH="./pre-deploy.sh"

if [ -f "$PRE_DEPLOY_PATH" ]; then
    # Backup the original file
    cp "$PRE_DEPLOY_PATH" "${PRE_DEPLOY_PATH}.bak"
    echo "✓ Created backup of pre-deploy.sh at pre-deploy.sh.bak"
    
    # Add defensive checks before copying files
    if grep -q "cp -f frontend/backend/Repository\.py\.railway frontend/backend/Repository\.py" "$PRE_DEPLOY_PATH"; then
        echo "Adding defensive checks to pre-deploy.sh..."
        
        # Replace the Repository.py copy command with a version that checks for directory conflicts
        sed -i 's|cp -f frontend/backend/Repository\.py\.railway frontend/backend/Repository\.py|# Check if target is a directory, which would cause "Is a directory" error\nif [ -d frontend/backend/Repository.py ]; then\n  echo "⚠️ Repository.py exists as a directory - renaming it to avoid conflicts"\n  mv frontend/backend/Repository.py frontend/backend/Repository.py_dir_backup\nfi\ncp -f frontend/backend/Repository.py.railway frontend/backend/Repository.py|' "$PRE_DEPLOY_PATH"
        
        # Replace the server.js copy command with a version that checks for directory conflicts
        sed -i 's|cp -f frontend/backend/server\.js\.railway frontend/backend/server\.js|# Check if target is a directory, which would cause "Is a directory" error\nif [ -d frontend/backend/server.js ]; then\n  echo "⚠️ server.js exists as a directory - renaming it to avoid conflicts"\n  mv frontend/backend/server.js frontend/backend/server.js_dir_backup\nfi\ncp -f frontend/backend/server.js.railway frontend/backend/server.js|' "$PRE_DEPLOY_PATH"
        
        echo "✓ Fixed pre-deploy.sh script"
    else
        echo "No issues found in pre-deploy.sh"
    fi
else
    echo "⚠️ pre-deploy.sh not found"
fi

# 4. Fix uploads directory handling in server.js.railway
echo -e "\nFixing uploads directory handling..."
SERVER_RAILWAY_PATH="./frontend/backend/server.js.railway"

if [ -f "$SERVER_RAILWAY_PATH" ]; then
    # Backup the original file
    cp "$SERVER_RAILWAY_PATH" "${SERVER_RAILWAY_PATH}.bak"
    echo "✓ Created backup of server.js.railway at server.js.railway.bak"
    
    # Update uploads directory handling
    if grep -q "if (!fs\.existsSync('uploads'))" "$SERVER_RAILWAY_PATH"; then
        echo "Fixing uploads directory handling in server.js.railway..."
        
        # Replace the uploads directory handling with a more robust version
        sed -i 's|if (!fs\.existsSync('\''uploads'\'')) {\s*fs\.mkdirSync('\''uploads'\'');\s*}|// Create uploads directory using absolute path\nconst uploadsDir = path.join(__dirname, '\''uploads'\'');\nif (!fs.existsSync(uploadsDir)) {\n  try {\n    // Check if the path exists but is a file\n    if (fs.existsSync(uploadsDir) && fs.statSync(uploadsDir).isFile()) {\n      console.error('\''Error: uploads path exists but is a file'\'');\n      fs.renameSync(uploadsDir, `${uploadsDir}_file_bak_${Date.now()}`);\n    }\n    fs.mkdirSync(uploadsDir, { recursive: true });\n    console.log(`Created uploads directory at: ${uploadsDir}`);\n  } catch (error) {\n    console.error(`Failed to create uploads directory: ${error.message}`);\n  }\n}|' "$SERVER_RAILWAY_PATH"
        
        # Fix the static directory serving
        sed -i 's|app\.use('\''/uploads'\'', express\.static('\''uploads'\''));|// Serve uploads from absolute path\napp.use('\''/uploads'\'', express.static(path.join(__dirname, '\''uploads'\'')));|' "$SERVER_RAILWAY_PATH"
        
        echo "✓ Fixed uploads directory handling in server.js.railway"
    else
        echo "No issues found in server.js.railway"
    fi
else
    echo "⚠️ server.js.railway not found"
fi

# Mark as executable
chmod +x ./pre-deploy.sh
chmod +x ./railway-up.js

# Final summary
echo -e "\n===== RAILWAY DIRECTORY ERROR FIX COMPLETE ====="
echo "The 'Is a directory (os error 21)' error should now be fixed."
echo "To deploy your app, run: railway up"
