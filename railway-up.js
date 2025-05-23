// Simple railway-up.js script for Music Player Project
// This resolves the "Is a directory (os error 21)" error
import { spawn } from 'child_process';
import path from 'path';
import fs from 'fs';
import os from 'os';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

console.log('===========================================');
console.log('Starting Music Player Project on Railway...');
console.log('Environment:', process.env.NODE_ENV);
console.log('Current Directory:', __dirname);

// Handle uncaught errors
process.on('uncaughtException', (err) => {
  console.error('ERROR:', err);
  console.error('Stack trace:', err.stack);
  process.exit(1);
});

// Define paths
const backendDir = path.join(__dirname, 'frontend', 'backend');
const repositoryPath = path.join(backendDir, 'Repository.py');
const serverJsPath = path.join(backendDir, 'server.js');
const uploadsDir = path.join(backendDir, 'uploads');

// Create uploads directory with conflict handling
if (!fs.existsSync(uploadsDir)) {
  try {
    if (fs.existsSync(uploadsDir) && !fs.statSync(uploadsDir).isDirectory()) {
      console.error('Error: uploads path exists but is not a directory');
      fs.renameSync(uploadsDir, `${uploadsDir}_file_bak_${Date.now()}`);
    }
    fs.mkdirSync(uploadsDir, { recursive: true });
    console.log(`Created uploads directory at: ${uploadsDir}`);
  } catch (error) {
    console.error(`Failed to create uploads directory: ${error.message}`);
  }
}

// Helper function to execute a command
function executeCommand(command, args, options = {}) {
  console.log(`Executing command: ${command} ${args.join(' ')}`);
  
  // Use correct working directory
  if (!options.cwd) {
    options.cwd = process.cwd();
  }
  
  // Handle directory conflicts
  if (!fs.existsSync(options.cwd)) {
    console.log(`Creating directory: ${options.cwd}`);
    fs.mkdirSync(options.cwd, { recursive: true });
  } else if (!fs.statSync(options.cwd).isDirectory()) {
    console.error(`ERROR: Path exists but is not a directory: ${options.cwd}`);
    const backupPath = `${options.cwd}_file_bak_${Date.now()}`;
    fs.renameSync(options.cwd, backupPath);
    console.log(`Renamed conflicting file to: ${backupPath}`);
    fs.mkdirSync(options.cwd, { recursive: true });
  }

  // Start the process
  const proc = spawn(
    command,
    args,
    { ...options, stdio: 'inherit' }
  );
  
  proc.on('error', (err) => {
    console.error(`Failed to execute command: ${err.message}`);
    process.exit(1);
  });
  
  return proc;
}

// Check if this is for the worker service
const isWorker = process.env.RAILWAY_SERVICE_NAME === 'worker' || 
                 process.argv.includes('worker');

// Start the appropriate service
console.log('Starting service...');
if (isWorker) {
  console.log('Starting Node.js backend worker service...');
  executeCommand('node', [serverJsPath], { cwd: backendDir });
} else {
  console.log('Starting Flask backend service...');
  executeCommand('python', [repositoryPath], { cwd: backendDir });
}

console.log('Service startup complete');
