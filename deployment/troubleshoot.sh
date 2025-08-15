#!/bin/bash

# Zencrow Website Troubleshooting Script
# Run this script to diagnose deployment issues

echo "🔍 Zencrow Website Troubleshooting Script"
echo "=========================================="

# Check if we're in the right directory
echo ""
echo "📁 Current directory:"
pwd
echo ""

# Check if application files exist
echo "📋 Checking application files:"
if [ -f "wsgi.py" ]; then
    echo "✅ wsgi.py exists"
else
    echo "❌ wsgi.py missing"
fi

if [ -f "run.py" ]; then
    echo "✅ run.py exists"
else
    echo "❌ run.py missing"
fi

if [ -f "requirements.txt" ]; then
    echo "✅ requirements.txt exists"
else
    echo "❌ requirements.txt missing"
fi

# Check virtual environment
echo ""
echo "🐍 Checking virtual environment:"
if [ -d "venv" ]; then
    echo "✅ venv directory exists"
    if [ -f "venv/bin/activate" ]; then
        echo "✅ venv/bin/activate exists"
        source venv/bin/activate
        echo "✅ Virtual environment activated"
        echo "Python version: $(python --version)"
        echo "Pip version: $(pip --version)"
    else
        echo "❌ venv/bin/activate missing"
    fi
else
    echo "❌ venv directory missing"
fi

# Check if Gunicorn is installed
echo ""
echo "🔧 Checking Gunicorn:"
if command -v gunicorn &> /dev/null; then
    echo "✅ Gunicorn is installed"
    gunicorn --version
else
    echo "❌ Gunicorn not found in PATH"
    if [ -f "venv/bin/gunicorn" ]; then
        echo "✅ Gunicorn found in venv"
    else
        echo "❌ Gunicorn not found in venv"
    fi
fi

# Check systemd service status
echo ""
echo "🚀 Checking systemd service:"
if sudo systemctl is-active --quiet zencrow; then
    echo "✅ zencrow service is running"
else
    echo "❌ zencrow service is not running"
fi

if sudo systemctl is-enabled --quiet zencrow; then
    echo "✅ zencrow service is enabled"
else
    echo "❌ zencrow service is not enabled"
fi

# Check service logs
echo ""
echo "📝 Recent service logs:"
sudo journalctl -u zencrow -n 10 --no-pager

# Check if port 8000 is listening
echo ""
echo "🔌 Checking port 8000:"
if sudo netstat -tlnp | grep :8000; then
    echo "✅ Port 8000 is listening"
else
    echo "❌ Port 8000 is not listening"
fi

# Check if port 80 is listening
echo ""
echo "🌐 Checking port 80:"
if sudo netstat -tlnp | grep :80; then
    echo "✅ Port 80 is listening"
else
    echo "❌ Port 80 is not listening"
fi

# Check Nginx status
echo ""
echo "🌐 Checking Nginx:"
if sudo systemctl is-active --quiet nginx; then
    echo "✅ Nginx is running"
else
    echo "❌ Nginx is not running"
fi

# Check Nginx configuration
echo ""
echo "⚙️ Checking Nginx configuration:"
if sudo nginx -t; then
    echo "✅ Nginx configuration is valid"
else
    echo "❌ Nginx configuration has errors"
fi

# Check firewall status
echo ""
echo "🔥 Checking firewall:"
if sudo systemctl is-active --quiet firewalld; then
    echo "✅ Firewalld is running"
    echo "Firewall rules:"
    sudo firewall-cmd --list-all
else
    echo "❌ Firewalld is not running"
fi

# Check file permissions
echo ""
echo "🔐 Checking file permissions:"
ls -la | head -5
echo "..."

# Check if .env file exists
echo ""
echo "⚙️ Checking environment file:"
if [ -f ".env" ]; then
    echo "✅ .env file exists"
    echo "Environment variables:"
    cat .env | grep -v PASSWORD
else
    echo "❌ .env file missing"
fi

echo ""
echo "🔍 Troubleshooting complete!"
echo "If you see errors above, please fix them and restart the service:"
echo "sudo systemctl restart zencrow"
echo "sudo systemctl restart nginx"
