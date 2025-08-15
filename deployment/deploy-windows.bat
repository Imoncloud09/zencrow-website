@echo off
echo 🚀 Zencrow Website - Windows Deployment Setup
echo ==============================================

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Python is not installed or not in PATH
    echo Please install Python 3.8+ from https://python.org
    pause
    exit /b 1
)

echo ✅ Python found
python --version

REM Check if virtual environment exists
if exist "venv" (
    echo 🗑️ Removing old virtual environment...
    rmdir /s /q venv
)

REM Create virtual environment
echo 🔧 Creating virtual environment...
python -m venv venv
if errorlevel 1 (
    echo ❌ Failed to create virtual environment
    pause
    exit /b 1
)

REM Activate virtual environment
echo 🚀 Activating virtual environment...
call venv\Scripts\activate.bat

REM Upgrade pip
echo ⬆️ Upgrading pip...
python -m pip install --upgrade pip

REM Install requirements
echo 📚 Installing Python dependencies...
pip install -r requirements.txt
if errorlevel 1 (
    echo ❌ Failed to install requirements
    pause
    exit /b 1
)

REM Test the application
echo 🧪 Testing Flask application...
python deployment/test-app.py
if errorlevel 1 (
    echo ❌ Flask application test failed
    echo Please check the errors above
    pause
    exit /b 1
)

echo.
echo 🎉 Setup completed successfully!
echo.
echo 📋 Next steps:
echo 1. Your virtual environment is ready: venv\Scripts\activate
echo 2. Test locally: python run.py
echo 3. Deploy to server (see deployment guide)
echo.
echo 🌐 To activate virtual environment in new terminal:
echo    venv\Scripts\activate
echo.
echo 🚀 To run development server:
echo    python run.py
echo.
pause
