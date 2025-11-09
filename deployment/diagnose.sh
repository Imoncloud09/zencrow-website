#!/bin/bash

# Comprehensive diagnostic script for Zencrow deployment
# Run this on your EC2 instance to diagnose issues

APP_DIR="/home/ec2-user/zencrow-website"
SERVICE_NAME="zencrow"

echo "🔍 Zencrow Website Deployment Diagnostics"
echo "=========================================="
echo ""

# Check if we're on EC2
echo "📋 System Information:"
echo "  Hostname: $(hostname)"
echo "  User: $(whoami)"
echo "  OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "  Date: $(date)"
echo ""

# Check application directory
echo "📁 Application Directory:"
if [ -d "$APP_DIR" ]; then
    echo "  ✅ Directory exists: $APP_DIR"
    cd $APP_DIR
    echo "  Current directory: $(pwd)"
    echo "  Files:"
    ls -la | head -10
else
    echo "  ❌ Directory not found: $APP_DIR"
    exit 1
fi
echo ""

# Check required files
echo "📄 Required Files:"
files=("requirements.txt" "wsgi.py" "config.py" "app/__init__.py" "gunicorn.conf.py")
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file (MISSING)"
    fi
done
echo ""

# Check Python
echo "🐍 Python Environment:"
if command -v python3 &> /dev/null; then
    echo "  ✅ Python 3: $(python3 --version)"
    echo "  Path: $(which python3)"
else
    echo "  ❌ Python 3 not found"
fi

if command -v pip3 &> /dev/null; then
    echo "  ✅ pip3: $(pip3 --version)"
else
    echo "  ❌ pip3 not found"
fi
echo ""

# Check virtual environment
echo "🔧 Virtual Environment:"
if [ -d "venv" ]; then
    echo "  ✅ venv directory exists"
    if [ -f "venv/bin/activate" ]; then
        echo "  ✅ venv/bin/activate exists"
        source venv/bin/activate
        echo "  Python in venv: $(python --version 2>&1)"
        echo "  Pip in venv: $(pip --version 2>&1)"
        
        # Check if gunicorn is installed
        if python -c "import gunicorn" 2>/dev/null; then
            echo "  ✅ Gunicorn installed: $(pip show gunicorn | grep Version | cut -d' ' -f2)"
        else
            echo "  ❌ Gunicorn not installed in venv"
        fi
        
        # Check if flask is installed
        if python -c "import flask" 2>/dev/null; then
            echo "  ✅ Flask installed: $(pip show flask | grep Version | cut -d' ' -f2)"
        else
            echo "  ❌ Flask not installed in venv"
        fi
    else
        echo "  ❌ venv/bin/activate missing"
    fi
else
    echo "  ❌ venv directory missing"
fi
echo ""

# Test application
echo "🧪 Application Test:"
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
    if python -c "from app import create_app; app = create_app()" 2>&1; then
        echo "  ✅ Application can be created"
    else
        echo "  ❌ Application creation failed"
        echo "  Error:"
        python -c "from app import create_app; app = create_app()" 2>&1 | head -5
    fi
else
    echo "  ⚠️  Cannot test - venv not set up"
fi
echo ""

# Check environment file
echo "⚙️ Environment Configuration:"
if [ -f ".env" ]; then
    echo "  ✅ .env file exists"
    echo "  Variables:"
    grep -v PASSWORD .env | sed 's/^/    /'
else
    echo "  ❌ .env file missing"
fi
echo ""

# Check database directory
echo "💾 Database:"
if [ -d "instance" ]; then
    echo "  ✅ instance directory exists"
    if [ -f "instance/zencrow.db" ]; then
        echo "  ✅ Database file exists"
        echo "  Size: $(du -h instance/zencrow.db | cut -f1)"
    else
        echo "  ⚠️  Database file not found (will be created on first run)"
    fi
else
    echo "  ❌ instance directory missing"
fi
echo ""

# Check systemd service
echo "🚀 Systemd Service:"
if [ -f "/etc/systemd/system/$SERVICE_NAME.service" ]; then
    echo "  ✅ Service file exists"
    echo "  Status:"
    sudo systemctl status $SERVICE_NAME --no-pager -l | head -10 | sed 's/^/    /'
    
    if sudo systemctl is-active --quiet $SERVICE_NAME; then
        echo "  ✅ Service is running"
    else
        echo "  ❌ Service is not running"
    fi
    
    if sudo systemctl is-enabled --quiet $SERVICE_NAME; then
        echo "  ✅ Service is enabled"
    else
        echo "  ❌ Service is not enabled"
    fi
else
    echo "  ❌ Service file not found"
fi
echo ""

# Check service logs
echo "📝 Recent Service Logs:"
sudo journalctl -u $SERVICE_NAME -n 20 --no-pager | tail -15 | sed 's/^/  /'
echo ""

# Check ports
echo "🔌 Port Status:"
if command -v netstat &> /dev/null; then
    if netstat -tlnp 2>/dev/null | grep :8000 > /dev/null; then
        echo "  ✅ Port 8000 is listening"
        netstat -tlnp 2>/dev/null | grep :8000 | sed 's/^/    /'
    else
        echo "  ❌ Port 8000 is not listening"
    fi
    
    if netstat -tlnp 2>/dev/null | grep :80 > /dev/null; then
        echo "  ✅ Port 80 is listening"
        netstat -tlnp 2>/dev/null | grep :80 | sed 's/^/    /'
    else
        echo "  ❌ Port 80 is not listening"
    fi
elif command -v ss &> /dev/null; then
    if ss -tlnp 2>/dev/null | grep :8000 > /dev/null; then
        echo "  ✅ Port 8000 is listening"
        ss -tlnp 2>/dev/null | grep :8000 | sed 's/^/    /'
    else
        echo "  ❌ Port 8000 is not listening"
    fi
    
    if ss -tlnp 2>/dev/null | grep :80 > /dev/null; then
        echo "  ✅ Port 80 is listening"
        ss -tlnp 2>/dev/null | grep :80 | sed 's/^/    /'
    else
        echo "  ❌ Port 80 is not listening"
    fi
else
    echo "  ⚠️  Cannot check ports - netstat/ss not available"
fi
echo ""

# Check Nginx
echo "🌐 Nginx:"
if command -v nginx &> /dev/null; then
    echo "  ✅ Nginx installed: $(nginx -v 2>&1)"
    
    if sudo systemctl is-active --quiet nginx; then
        echo "  ✅ Nginx is running"
    else
        echo "  ❌ Nginx is not running"
    fi
    
    if sudo nginx -t 2>&1; then
        echo "  ✅ Nginx configuration is valid"
    else
        echo "  ❌ Nginx configuration has errors"
    fi
    
    if [ -f "/etc/nginx/conf.d/$SERVICE_NAME.conf" ]; then
        echo "  ✅ Nginx configuration file exists"
    else
        echo "  ❌ Nginx configuration file missing"
    fi
else
    echo "  ❌ Nginx not installed"
fi
echo ""

# Check firewall
echo "🔥 Firewall:"
if command -v firewall-cmd &> /dev/null; then
    if sudo systemctl is-active --quiet firewalld; then
        echo "  ✅ Firewalld is running"
        echo "  Rules:"
        sudo firewall-cmd --list-all 2>/dev/null | sed 's/^/    /'
    else
        echo "  ⚠️  Firewalld is not running"
    fi
else
    echo "  ⚠️  Firewalld not installed (AWS Security Groups handle firewall)"
fi
echo ""

# Check log directories
echo "📝 Log Directories:"
if [ -d "/var/log/gunicorn" ]; then
    echo "  ✅ Gunicorn log directory exists"
    echo "  Permissions: $(ls -ld /var/log/gunicorn | awk '{print $1, $3, $4}')"
    
    if [ -f "/var/log/gunicorn/error.log" ]; then
        echo "  Error log:"
        tail -5 /var/log/gunicorn/error.log 2>/dev/null | sed 's/^/    /' || echo "    (empty)"
    fi
    
    if [ -f "/var/log/gunicorn/access.log" ]; then
        echo "  Access log:"
        tail -5 /var/log/gunicorn/access.log 2>/dev/null | sed 's/^/    /' || echo "    (empty)"
    fi
else
    echo "  ❌ Gunicorn log directory missing"
fi
echo ""

# Check file permissions
echo "🔐 File Permissions:"
echo "  App directory owner: $(ls -ld $APP_DIR | awk '{print $3, $4}')"
echo "  Current user: $(whoami)"
echo ""

# Check disk space
echo "💿 Disk Space:"
df -h / | tail -1 | awk '{print "  Total: " $2 " | Used: " $3 " | Available: " $4 " | Use%: " $5}'
echo ""

# Check memory
echo "🧠 Memory:"
free -h | grep Mem | awk '{print "  Total: " $2 " | Used: " $3 " | Free: " $4 " | Available: " $7}'
echo ""

# Get public IP
echo "🌐 Network:"
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "Not available")
echo "  Public IP: $PUBLIC_IP"
echo ""

# Summary
echo "=========================================="
echo "📊 Diagnostic Summary:"
echo "=========================================="
echo ""
echo "If you see errors above, here are common fixes:"
echo ""
echo "1. Service not running:"
echo "   sudo systemctl restart $SERVICE_NAME"
echo "   sudo journalctl -u $SERVICE_NAME -f"
echo ""
echo "2. Python/venv issues:"
echo "   cd $APP_DIR"
echo "   rm -rf venv"
echo "   python3 -m venv venv"
echo "   source venv/bin/activate"
echo "   pip install -r requirements.txt"
echo ""
echo "3. Permission issues:"
echo "   sudo chown -R ec2-user:ec2-user $APP_DIR"
echo "   sudo chown -R ec2-user:ec2-user /var/log/gunicorn"
echo ""
echo "4. Nginx issues:"
echo "   sudo nginx -t"
echo "   sudo systemctl restart nginx"
echo ""
echo "5. Port issues:"
echo "   Check AWS Security Group allows HTTP (80) and HTTPS (443)"
echo ""

