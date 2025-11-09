# Run Zencrow Website Locally
# This script activates the virtual environment and runs the application

Write-Host "🚀 Starting Zencrow Website Locally" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green
Write-Host ""

# Check if venv exists
if (-not (Test-Path "venv")) {
    Write-Host "❌ Virtual environment not found!" -ForegroundColor Red
    Write-Host "Creating virtual environment..." -ForegroundColor Yellow
    
    # Create virtual environment
    python -m venv venv
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to create virtual environment" -ForegroundColor Red
        Write-Host "Make sure Python is installed and in PATH" -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "✅ Virtual environment created" -ForegroundColor Green
}

# Activate virtual environment
Write-Host "🔧 Activating virtual environment..." -ForegroundColor Cyan
& "venv\Scripts\Activate.ps1"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to activate virtual environment" -ForegroundColor Red
    exit 1
}

# Check if requirements are installed
Write-Host "📦 Checking dependencies..." -ForegroundColor Cyan
$flaskInstalled = python -c "import flask" 2>$null
if (-not $flaskInstalled) {
    Write-Host "📚 Installing dependencies..." -ForegroundColor Yellow
    pip install -r requirements.txt
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to install dependencies" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Dependencies installed" -ForegroundColor Green
} else {
    Write-Host "✅ Dependencies already installed" -ForegroundColor Green
}

# Check if .env file exists
if (-not (Test-Path ".env")) {
    Write-Host "⚙️  Creating .env file..." -ForegroundColor Yellow
    Copy-Item "env_template.txt" ".env"
    Write-Host "✅ .env file created (using template)" -ForegroundColor Green
    Write-Host "ℹ️  You may want to edit .env file with your settings" -ForegroundColor Cyan
}

# Create instance directory if it doesn't exist
if (-not (Test-Path "instance")) {
    New-Item -ItemType Directory -Path "instance" | Out-Null
    Write-Host "✅ Created instance directory" -ForegroundColor Green
}

# Test application
Write-Host ""
Write-Host "🧪 Testing application..." -ForegroundColor Cyan
python -c "from app import create_app; app = create_app()" 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Application test failed" -ForegroundColor Red
    Write-Host "Running test to see errors..." -ForegroundColor Yellow
    python -c "from app import create_app; app = create_app()"
    exit 1
}
Write-Host "✅ Application test passed" -ForegroundColor Green

# Run the application
Write-Host ""
Write-Host "🌐 Starting Flask development server..." -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""
Write-Host "📍 Application will be available at: http://127.0.0.1:5000" -ForegroundColor Cyan
Write-Host "🛑 Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

# Run Flask application
python run.py

