# How to Run Zencrow Website Application

## Prerequisites
- Python 3.7 or higher installed on your system
- pip (Python package installer)

## Step-by-Step Setup Instructions

### 1. Navigate to Project Directory
```powershell
cd C:\Users\hp\OneDrive\Desktop\zencrow-website
```

### 2. Create Virtual Environment (if not already created)
```powershell
python -m venv venv
```

### 3. Activate Virtual Environment
```powershell
# For PowerShell
.\venv\Scripts\Activate.ps1

# If you get an execution policy error, run this first:
# Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 4. Install Dependencies
```powershell
pip install -r requirements.txt
```

### 5. Create Environment Variables File
Create a `.env` file in the project root directory (copy from `env_template.txt`):
```powershell
# Copy the template
Copy-Item env_template.txt .env
```

Then edit `.env` file and update the following (at minimum):
- `SECRET_KEY` - Change to a random secret key
- `MAIL_USERNAME` and `MAIL_PASSWORD` - If you want email functionality, or leave them empty to disable

### 6. Run the Application

#### Option A: Development Mode (Recommended for testing)
```powershell
python run.py
```

#### Option B: Using Flask CLI
```powershell
flask run
```

The application will start on `http://127.0.0.1:5000` (or `http://localhost:5000`)

### 7. Access the Application
Open your web browser and navigate to:
```
http://localhost:5000
```

## Production Mode (Using Gunicorn)

For production, you can use Gunicorn:
```powershell
gunicorn -c gunicorn.conf.py wsgi:application
```

## Troubleshooting

### Virtual Environment Activation Issues
If you get an execution policy error when activating venv:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Port Already in Use
If port 5000 is already in use, you can specify a different port:
```powershell
$env:FLASK_RUN_PORT=5001
python run.py
```

### Database Issues
The application will automatically create a SQLite database file (`zencrow.db`) on first run in the `instance/` directory.

### Email Configuration
Email is optional. If you don't configure email settings, the app will run but email functionality will be disabled (which is fine for development).

## Quick Start (All-in-One Commands)

```powershell
# Navigate to project
cd C:\Users\hp\OneDrive\Desktop\zencrow-website

# Activate venv
.\venv\Scripts\Activate.ps1

# Install dependencies (if not already installed)
pip install -r requirements.txt

# Create .env file if it doesn't exist
if (!(Test-Path .env)) { Copy-Item env_template.txt .env }

# Run the application
python run.py
```

