$ErrorActionPreference = 'Stop'
try {
  # Create required directories
  New-Item -Path "frontend/backend/uploads" -ItemType Directory -Force | Out-Null
  # Check for directory conflicts
  $repoPath = "frontend/backend/Repository.py"
  if (Test-Path -Path $repoPath -PathType Container) {
    Rename-Item -Path $repoPath -NewName "$repoPath-dir-backup" -Force
  }
  $serverPath = "frontend/backend/server.js"
  if (Test-Path -Path $serverPath -PathType Container) {
    Rename-Item -Path $serverPath -NewName "$serverPath-dir-backup" -Force
  }
  Write-Host "Ready to deploy" -ForegroundColor Green
} catch {
  Write-Host "Error: $_" -ForegroundColor Red
}
}
