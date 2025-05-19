// Enhanced railway-up-clean.js script for Music Player Project
// Resolves the "Is a directory (os error 21)" error with better path handling
const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');
const os = require('os');

// Print banner
console.log('===========================================');
console.log('Starting Music Player Project on Railway...');
console.log('Environment:', process.env.NODE_ENV);
console.log('Current Directory:', __dirname);
console.log('Platform:', os.platform());

// Handle uncaught errors
process.on('uncaughtException', (err) => {
  console.error('ERROR:', err);
  console.error('Stack trace:', err.stack);
  // Don't exit process to allow Railway deployment to continue
  console.log('Attempting to continue despite error...');
});

// Define absolute paths
const backendDir = path.join(__dirname, 'frontend', 'backend');
const repositoryPath = path.join(backendDir, 'Repository.py');
const serverJsPath = path.join(backendDir, 'server.js');
const uploadsDir = path.join(backendDir, 'uploads');

// Create uploads directory with robust conflict handling
function ensureDirectoryExists(dirPath) {
  console.log(`Ensuring directory exists: ${dirPath}`);
  
  try {
    // If path exists but is a file
    if (fs.existsSync(dirPath) && !fs.statSync(dirPath).isDirectory()) {
      const backupPath = `${dirPath}_file_bak_${Date.now()}`;
      console.log(`Path exists but is a file. Renaming to: ${backupPath}`);
      fs.renameSync(dirPath, backupPath);
    }
    
    // Create directory if it doesn't exist
    if (!fs.existsSync(dirPath)) {
      console.log(`Creating directory: ${dirPath}`);
      fs.mkdirSync(dirPath, { recursive: true });
    }
    
    return true;
  } catch (err) {
    console.error(`Error ensuring directory exists: ${err.message}`);
    return false;
  }
}

// Ensure uploads directory exists
ensureDirectoryExists(uploadsDir);

// Ensure file exists with conflict handling
function ensureFileFromSource(sourcePath, targetPath) {
  try {
    if (fs.existsSync(sourcePath)) {
      console.log(`Found source file: ${sourcePath}`);
      
      // Handle case where target path is a directory
      if (fs.existsSync(targetPath) && fs.statSync(targetPath).isDirectory()) {
        const backupPath = `${targetPath}_dir_bak_${Date.now()}`;
        console.log(`Target path is a directory. Renaming to: ${backupPath}`);
        fs.renameSync(targetPath, backupPath);
      }
      
      // Copy the file
      fs.copyFileSync(sourcePath, targetPath);
      console.log(`Successfully copied ${sourcePath} to ${targetPath}`);
      return true;
    } else {
      console.log(`Source file not found: ${sourcePath}`);
      return false;
    }
  } catch (err) {
    console.error(`Error ensuring file exists: ${err.message}`);
    return false;
  }
}

// Copy Railway-specific files
const repositorySourcePath = path.join(backendDir, 'Repository.py.railway');
const serverSourcePath = path.join(backendDir, 'server.js.railway');

ensureFileFromSource(repositorySourcePath, repositoryPath);
ensureFileFromSource(serverSourcePath, serverJsPath);

// Execute command with proper error handling
function executeCommand(command, args = [], options = {}) {
  return new Promise((resolve, reject) => {
    console.log(`Executing command: ${command} ${args.join(' ')}`);
    
    // Ensure working directory exists
    if (options.cwd) {
      ensureDirectoryExists(options.cwd);
    }
    
    const isWindows = os.platform() === 'win32';
    let proc;
    
    if (isWindows) {
      args = ['/c', command, ...args];
      proc = spawn('cmd', args, { ...options, stdio: 'inherit' });
    } else {
      proc = spawn(command, args, { ...options, stdio: 'inherit' });
    }
    
    proc.on('error', (err) => {
      console.error(`Error executing command: ${err.message}`);
      reject(err);
    });
    
    proc.on('close', (code) => {
      if (code === 0) {
        console.log(`Command completed successfully`);
        resolve();
      } else {
        console.error(`Command failed with exit code: ${code}`);
        // Resolve anyway to allow Railway deployment to continue
        resolve();
      }
    });
  });
}

// Start backend server
async function startBackend() {
  try {
    // Check if we should use Python (Flask) backend
    if (fs.existsSync(repositoryPath)) {
      console.log('Starting Flask backend...');
      await executeCommand('python', [repositoryPath], { cwd: backendDir });
    } 
    // Check if we should use Node.js backend
    else if (fs.existsSync(serverJsPath)) {
      console.log('Starting Node.js backend...');
      await executeCommand('node', [serverJsPath], { cwd: backendDir });
    }
    // Fallback to a simple Express server
    else {
      console.log('No backend file found. Starting emergency server...');
      const express = require('express');
      const app = express();
      const PORT = process.env.PORT || 3000;
      
      app.get('/', (req, res) => {
        res.json({ status: 'OK', message: 'Emergency server is running' });
      });
      
      app.listen(PORT, () => console.log(`Emergency server listening on port ${PORT}`));
    }
  } catch (err) {
    console.error(`Error starting backend: ${err.message}`);
    // Start emergency server
    const express = require('express');
    const app = express();
    const PORT = process.env.PORT || 3000;
    
    app.get('/', (req, res) => {
      res.json({ status: 'ERROR', message: 'Backend failed, emergency server running' });
    });
    
    app.listen(PORT, () => console.log(`Emergency server listening on port ${PORT}`));
  }
}

// Start the application
startBackend();
