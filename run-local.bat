@echo off
REM Run Zencrow Website Locally
REM This script activates the virtual environment and runs the application

echo.
echo 🚀 Starting Zencrow Website Locally
echo ====================================
echo.

REM Check if venv exists
if not exist "venv" (
    echo ❌ Virtual environment not found!
    echo Creating virtual environment...
    python -m venv venv
    if errorlevel 1 (
        echo ❌ Failed to create virtual environment
        echo Make sure Python is installed and in PATH
        exit /b 1
    )
    echo ✅ Virtual environment created
)

REM Activate virtual environment
echo 🔧 Activating virtual environment...
call venv\Scripts\activate.bat

REM Check if requirements are installed
echo 📦 Checking dependencies...
python -c "import flask" 2>nul
if errorlevel 1 (
    echo 📚 Installing dependencies...
    pip install -r requirements.txt
    if errorlevel 1 (
        echo ❌ Failed to install dependencies
        exit /b 1
    )
    echo ✅ Dependencies installed
) else (
    echo ✅ Dependencies already installed
)

REM Check if .env file exists
if not exist ".env" (
    echo ⚙️  Creating .env file...
    copy env_template.txt .env >nul
    echo ✅ .env file created (using template)
    echo ℹ️  You may want to edit .env file with your settings
)

REM Create instance directory if it doesn't exist
if not exist "instance" (
    mkdir instance
    echo ✅ Created instance directory
)

REM Test application
echo.
echo 🧪 Testing application...
python -c "from app import create_app; app = create_app()" 2>nul
if errorlevel 1 (
    echo ❌ Application test failed
    echo Running test to see errors...
    python -c "from app import create_app; app = create_app()"
    exit /b 1
)
echo ✅ Application test passed

REM Run the application
echo.
echo 🌐 Starting Flask development server...
echo =========================================
echo.
echo 📍 Application will be available at: http://127.0.0.1:5000
echo 🛑 Press Ctrl+C to stop the server
echo.

REM Run Flask application
python run.py

