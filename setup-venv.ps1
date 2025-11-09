# Setup Virtual Environment for Zencrow Website
# Run this script to set up the virtual environment

Write-Host "🔧 Setting Up Virtual Environment" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Green
Write-Host ""

# Check if Python is installed
Write-Host "🐍 Checking Python installation..." -ForegroundColor Cyan
$pythonVersion = python --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Python is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Python from https://www.python.org/" -ForegroundColor Yellow
    exit 1
}
Write-Host "✅ $pythonVersion" -ForegroundColor Green

# Remove existing venv if it exists
if (Test-Path "venv") {
    Write-Host ""
    Write-Host "⚠️  Virtual environment already exists" -ForegroundColor Yellow
    $response = Read-Host "Do you want to recreate it? (y/n)"
    if ($response -eq "y" -or $response -eq "Y") {
        Write-Host "🗑️  Removing existing virtual environment..." -ForegroundColor Yellow
        Remove-Item -Recurse -Force "venv"
        Write-Host "✅ Old virtual environment removed" -ForegroundColor Green
    } else {
        Write-Host "ℹ️  Using existing virtual environment" -ForegroundColor Cyan
    }
}

# Create virtual environment
if (-not (Test-Path "venv")) {
    Write-Host ""
    Write-Host "📦 Creating virtual environment..." -ForegroundColor Cyan
    python -m venv venv
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to create virtual environment" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Virtual environment created" -ForegroundColor Green
}

# Activate virtual environment
Write-Host ""
Write-Host "🔧 Activating virtual environment..." -ForegroundColor Cyan
& "venv\Scripts\Activate.ps1"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to activate virtual environment" -ForegroundColor Red
    Write-Host "Try running: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor Yellow
    exit 1
}

# Upgrade pip
Write-Host ""
Write-Host "⬆️  Upgrading pip..." -ForegroundColor Cyan
python -m pip install --upgrade pip
Write-Host "✅ pip upgraded" -ForegroundColor Green

# Install dependencies
Write-Host ""
Write-Host "📚 Installing dependencies..." -ForegroundColor Cyan
pip install -r requirements.txt
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to install dependencies" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Dependencies installed" -ForegroundColor Green

# Create .env file if it doesn't exist
Write-Host ""
Write-Host "⚙️  Setting up environment file..." -ForegroundColor Cyan
if (-not (Test-Path ".env")) {
    if (Test-Path "env_template.txt") {
        Copy-Item "env_template.txt" ".env"
        Write-Host "✅ .env file created from template" -ForegroundColor Green
    } else {
        # Create basic .env file
        $secretKey = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object {[char]$_})
        @"
FLASK_ENV=development
SECRET_KEY=$secretKey
DATABASE_URL=sqlite:///instance/zencrow.db
MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587
MAIL_USE_TLS=True
MAIL_USERNAME=
MAIL_PASSWORD=
"@ | Out-File -FilePath ".env" -Encoding utf8
        Write-Host "✅ .env file created" -ForegroundColor Green
    }
    Write-Host "ℹ️  Edit .env file to configure your settings" -ForegroundColor Cyan
} else {
    Write-Host "✅ .env file already exists" -ForegroundColor Green
}

# Create instance directory
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

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "✅ Setup Completed Successfully!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "🚀 To run the application:" -ForegroundColor Cyan
Write-Host "   .\run-local.ps1" -ForegroundColor White
Write-Host "   or" -ForegroundColor White
Write-Host "   python run.py" -ForegroundColor White
Write-Host ""

