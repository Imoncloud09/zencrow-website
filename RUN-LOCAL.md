# Running Zencrow Website Locally

Guide to run the Zencrow website on your local machine using a virtual environment.

## Quick Start

### Option 1: Automated Setup and Run (Recommended)

1. **Setup virtual environment:**
   ```powershell
   .\setup-venv.ps1
   ```

2. **Run the application:**
   ```powershell
   .\run-local.ps1
   ```

   Or use the quick run script:
   ```powershell
   .\run_app.ps1
   ```

### Option 2: Manual Setup

1. **Create virtual environment:**
   ```powershell
   python -m venv venv
   ```

2. **Activate virtual environment:**
   ```powershell
   # PowerShell
   .\venv\Scripts\Activate.ps1
   
   # Command Prompt
   venv\Scripts\activate.bat
   ```

3. **Install dependencies:**
   ```powershell
   pip install -r requirements.txt
   ```

4. **Create .env file:**
   ```powershell
   Copy-Item env_template.txt .env
   # Edit .env with your settings if needed
   ```

5. **Run the application:**
   ```powershell
   python run.py
   ```

## Using Batch File (Windows CMD)

If you prefer using Command Prompt:

```cmd
.\run-local.bat
```

## Accessing the Application

After starting the server, access the application at:
- **URL:** http://127.0.0.1:5000
- **URL:** http://localhost:5000

## Scripts Available

### Setup Scripts

- **`setup-venv.ps1`** - Set up virtual environment and install dependencies
- **`run-local.ps1`** - Run application with checks and setup
- **`run-local.bat`** - Run application (Command Prompt version)
- **`run_app.ps1`** - Quick run script (assumes venv is set up)

### Application Files

- **`run.py`** - Main application entry point
- **`wsgi.py`** - WSGI entry point for production
- **`config.py`** - Configuration file
- **`requirements.txt`** - Python dependencies

## Troubleshooting

### Virtual Environment Not Activating

**PowerShell Execution Policy Error:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Then try again:
```powershell
.\venv\Scripts\Activate.ps1
```

### Python Not Found

Make sure Python is installed and in PATH:
```powershell
python --version
```

If not found, install Python from https://www.python.org/

### Dependencies Not Installing

```powershell
# Upgrade pip first
python -m pip install --upgrade pip

# Then install dependencies
pip install -r requirements.txt
```

### Application Won't Start

1. **Check if virtual environment is activated:**
   ```powershell
   # You should see (venv) in your prompt
   ```

2. **Test application:**
   ```powershell
   python -c "from app import create_app; app = create_app()"
   ```

3. **Check for errors:**
   - Look at the error message
   - Check if all dependencies are installed
   - Verify .env file exists

### Port Already in Use

If port 5000 is already in use:

1. **Change the port in run.py:**
   ```python
   app.run(debug=True, port=5001)
   ```

2. **Or kill the process using port 5000:**
   ```powershell
   netstat -ano | findstr :5000
   taskkill /PID <PID> /F
   ```

## Environment Variables

Create a `.env` file in the project root:

```env
FLASK_ENV=development
SECRET_KEY=your-secret-key-here
DATABASE_URL=sqlite:///instance/zencrow.db
MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587
MAIL_USE_TLS=True
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=your-app-password
```

You can use `env_template.txt` as a starting point.

## Database

The application uses SQLite by default. The database file will be created in the `instance/` directory on first run.

## Development Mode

The application runs in development mode by default with:
- Debug mode enabled
- Auto-reload on code changes
- Detailed error messages

## Stopping the Server

Press `Ctrl+C` in the terminal to stop the development server.

## Next Steps

1. ✅ Set up virtual environment
2. ✅ Install dependencies
3. ✅ Configure .env file
4. ✅ Run the application
5. ✅ Access at http://127.0.0.1:5000

## Useful Commands

### Activate Virtual Environment
```powershell
.\venv\Scripts\Activate.ps1
```

### Deactivate Virtual Environment
```powershell
deactivate
```

### Install New Dependencies
```powershell
pip install package-name
pip freeze > requirements.txt
```

### Update Dependencies
```powershell
pip install --upgrade -r requirements.txt
```

### Run Tests
```powershell
python deployment/test-app.py
```

---

**Ready to run?** Use `.\setup-venv.ps1` to set up, then `.\run-local.ps1` to run!

