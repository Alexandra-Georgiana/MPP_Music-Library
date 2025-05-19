// railway-up.js - Helper script for Railway deployment
const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');
const os = require('os');

console.log('Starting Music Player Project on Railway...');
console.log('Environment:', process.env.NODE_ENV);
console.log('Railway Environment:', process.env.RAILWAY_ENVIRONMENT);
console.log('Current Directory:', __dirname);

// Determine which service to start based on env vars or args
const args = process.argv.slice(2);
const isWorker = args.includes('worker') || process.env.RAILWAY_SERVICE_NAME === 'worker';

// Helper function to execute a command with proper shell handling
function executeCommand(command, args, options = {}) {
    console.log(`Executing command: ${command} ${args.join(' ')}`);
    
    // Use proper shell based on platform
    const isWindows = os.platform() === 'win32';
    let proc;
    
    if (isWindows) {
        args = ['/c', command, ...args];
        proc = spawn('cmd', args, { ...options, stdio: 'inherit' });
    } else {
        proc = spawn(command, args, { ...options, stdio: 'inherit' });
    }
    
    proc.on('error', (err) => {
        console.error(`Failed to execute command: ${err.message}`);
        process.exit(1);
    });
    
    return proc;
}

if (isWorker) {
    console.log('Starting Node.js backend...');
    
    // Change directory to the backend
    process.chdir(path.join(__dirname, 'frontend', 'backend'));
    
    // Start the Node.js server
    executeCommand('node', ['server.js']);
} else {
    console.log('Starting Flask backend...');
    
    // Change directory to the backend
    process.chdir(path.join(__dirname, 'frontend', 'backend'));
    
    // Start the Flask server
    executeCommand('python', ['Repository.py']);
}
