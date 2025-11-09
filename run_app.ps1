# Zencrow Website - Quick Run Script
# This script activates the virtual environment and runs the application

Write-Host "Activating virtual environment..." -ForegroundColor Green
& .\venv\Scripts\Activate.ps1

Write-Host "Starting Zencrow Website..." -ForegroundColor Green
Write-Host "Application will be available at: http://localhost:5000" -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

python run.py

