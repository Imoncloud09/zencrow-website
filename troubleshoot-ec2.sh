#!/bin/bash

# Comprehensive Troubleshooting Script for Zencrow Website on EC2
# Run this script on your EC2 instance

set -e

APP_DIR="/home/ec2-user/zencrow-website"
SERVICE_NAME="zencrow"

echo "🔧 Zencrow Website Troubleshooting Script"
echo "=========================================="
echo ""
echo "📅 Date: $(date)"
echo "🖥️  Hostname: $(hostname)"
echo "👤 User: $(whoami)"
echo ""

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo "   ✅ $2"
    else
        echo "   ❌ $2"
    fi
}

# Check if application directory exists
echo "📁 Step 1: Checking Application Directory"
if [ -d "$APP_DIR" ]; then
    print_status 0 "Application directory exists: $APP_DIR"
    cd $APP_DIR
    echo "   📂 Contents:"
    ls -la | head -5 | sed 's/^/      /'
else
    print_status 1 "Application directory NOT found: $APP_DIR"
    echo "   💡 Solution: Deploy the application first"
    echo "   Run: bash deployment/deploy-aws.sh"
    exit 1
fi

# Check required files
echo ""
echo "📄 Step 2: Checking Required Files"
files=("wsgi.py" "requirements.txt" "config.py" "app/__init__.py")
missing_files=0
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        print_status 0 "$file exists"
    else
        print_status 1 "$file MISSING"
        missing_files=$((missing_files + 1))
    fi
done

if [ $missing_files -gt 0 ]; then
    echo "   💡 Solution: Deploy the application to get missing files"
    exit 1
fi

# Check Python
echo ""
echo "🐍 Step 3: Checking Python Environment"
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1)
    print_status 0 "Python 3 installed: $PYTHON_VERSION"
else
    print_status 1 "Python 3 not found"
    echo "   💡 Solution: Install Python 3"
    echo "   Run: sudo yum install -y python3 python3-pip"
    exit 1
fi

# Check virtual environment
echo ""
echo "🔧 Step 4: Checking Virtual Environment"
if [ -d "venv" ]; then
    print_status 0 "Virtual environment exists"
    if [ -f "venv/bin/activate" ]; then
        print_status 0 "venv/bin/activate exists"
        source venv/bin/activate
        echo "   📦 Python packages:"
        pip list 2>/dev/null | grep -E "Flask|gunicorn" | sed 's/^/      /' || echo "      (Checking packages...)"
    else
        print_status 1 "venv/bin/activate missing"
        echo "   💡 Solution: Recreate virtual environment"
        echo "   Run: python3 -m venv venv"
    fi
else
    print_status 1 "Virtual environment missing"
    echo "   💡 Solution: Create virtual environment"
    echo "   Run: python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt"
fi

# Check services
echo ""
echo "🚀 Step 5: Checking Services"
if systemctl is-active --quiet $SERVICE_NAME 2>/dev/null; then
    print_status 0 "zencrow service is RUNNING"
else
    print_status 1 "zencrow service is NOT running"
    echo "   📝 Recent logs:"
    sudo journalctl -u $SERVICE_NAME -n 10 --no-pager 2>/dev/null | tail -5 | sed 's/^/      /' || echo "      (No logs found)"
    echo "   💡 Solution: Start the service"
    echo "   Run: sudo systemctl start zencrow"
fi

if systemctl is-active --quiet nginx 2>/dev/null; then
    print_status 0 "nginx service is RUNNING"
else
    print_status 1 "nginx service is NOT running"
    echo "   💡 Solution: Start nginx"
    echo "   Run: sudo systemctl start nginx"
fi

# Check ports
echo ""
echo "🔌 Step 6: Checking Ports"
if netstat -tlnp 2>/dev/null | grep :8000 > /dev/null || ss -tlnp 2>/dev/null | grep :8000 > /dev/null; then
    print_status 0 "Port 8000 (Gunicorn) is LISTENING"
    netstat -tlnp 2>/dev/null | grep :8000 | sed 's/^/      /' || ss -tlnp 2>/dev/null | grep :8000 | sed 's/^/      /'
else
    print_status 1 "Port 8000 (Gunicorn) is NOT listening"
    echo "   💡 Solution: Start zencrow service"
    echo "   Run: sudo systemctl start zencrow"
fi

if netstat -tlnp 2>/dev/null | grep :80 > /dev/null || ss -tlnp 2>/dev/null | grep :80 > /dev/null; then
    print_status 0 "Port 80 (HTTP) is LISTENING"
    netstat -tlnp 2>/dev/null | grep :80 | sed 's/^/      /' || ss -tlnp 2>/dev/null | grep :80 | sed 's/^/      /'
else
    print_status 1 "Port 80 (HTTP) is NOT listening"
    echo "   💡 Solution: Start nginx"
    echo "   Run: sudo systemctl start nginx"
fi

# Test application
echo ""
echo "🧪 Step 7: Testing Application"
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
    if python -c "from app import create_app; app = create_app()" 2>/dev/null; then
        print_status 0 "Application can be created"
    else
        print_status 1 "Application creation failed"
        echo "   📝 Error:"
        python -c "from app import create_app; app = create_app()" 2>&1 | head -5 | sed 's/^/      /'
    fi
else
    echo "   ⚠️  Cannot test - virtual environment not set up"
fi

# Test endpoints
echo ""
echo "🌐 Step 8: Testing Endpoints"
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    print_status 0 "Gunicorn health endpoint responding"
    echo "   Response:"
    curl -s http://localhost:8000/health | python3 -m json.tool 2>/dev/null | sed 's/^/      /' || curl -s http://localhost:8000/health | sed 's/^/      /'
else
    print_status 1 "Gunicorn health endpoint NOT responding"
    echo "   💡 Solution: Check service logs and restart"
fi

if curl -s http://localhost/health > /dev/null 2>&1; then
    print_status 0 "Nginx proxy working"
else
    print_status 1 "Nginx proxy NOT working"
    echo "   💡 Solution: Check nginx configuration and restart"
    echo "   Run: sudo nginx -t && sudo systemctl restart nginx"
fi

# Check configuration files
echo ""
echo "⚙️  Step 9: Checking Configuration Files"
if [ -f "/etc/systemd/system/$SERVICE_NAME.service" ]; then
    print_status 0 "Systemd service file exists"
else
    print_status 1 "Systemd service file missing"
    echo "   💡 Solution: Copy service file"
    echo "   Run: sudo cp deployment/zencrow.service /etc/systemd/system/"
fi

if [ -f "/etc/nginx/conf.d/zencrow.conf" ]; then
    print_status 0 "Nginx configuration file exists"
    if sudo nginx -t 2>/dev/null; then
        print_status 0 "Nginx configuration is valid"
    else
        print_status 1 "Nginx configuration has errors"
        echo "   📝 Errors:"
        sudo nginx -t 2>&1 | sed 's/^/      /'
    fi
else
    print_status 1 "Nginx configuration file missing"
    echo "   💡 Solution: Copy nginx configuration"
    echo "   Run: sudo cp deployment/nginx.conf /etc/nginx/conf.d/zencrow.conf"
fi

# Get public IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "Not available")

# Summary and recommendations
echo ""
echo "=========================================="
echo "📊 Troubleshooting Summary"
echo "=========================================="
echo ""
echo "🌐 Public IP: $PUBLIC_IP"
echo "🔗 Application URL: http://$PUBLIC_IP"
echo ""

# Check what needs to be fixed
issues_found=0

if [ ! -d "$APP_DIR" ]; then
    echo "❌ Issue: Application not deployed"
    echo "   Fix: Deploy the application"
    issues_found=$((issues_found + 1))
fi

if ! systemctl is-active --quiet $SERVICE_NAME 2>/dev/null; then
    echo "❌ Issue: zencrow service not running"
    echo "   Fix: sudo systemctl start zencrow"
    issues_found=$((issues_found + 1))
fi

if ! systemctl is-active --quiet nginx 2>/dev/null; then
    echo "❌ Issue: nginx service not running"
    echo "   Fix: sudo systemctl start nginx"
    issues_found=$((issues_found + 1))
fi

if ! netstat -tlnp 2>/dev/null | grep :80 > /dev/null && ! ss -tlnp 2>/dev/null | grep :80 > /dev/null; then
    echo "❌ Issue: Port 80 not listening"
    echo "   Fix: Start nginx service"
    issues_found=$((issues_found + 1))
fi

if [ $issues_found -eq 0 ]; then
    echo "✅ All checks passed!"
    echo ""
    echo "If you still can't access from browser:"
    echo "   ⚠️  Check AWS Security Group allows HTTP (port 80) from 0.0.0.0/0"
    echo ""
    echo "To check Security Group:"
    echo "   1. Go to AWS Console → EC2 → Instances"
    echo "   2. Select your instance"
    echo "   3. Click Security tab → Security Group"
    echo "   4. Ensure HTTP (port 80) rule exists with source 0.0.0.0/0"
else
    echo "❌ Found $issues_found issue(s) that need to be fixed"
    echo ""
    echo "Run the following to fix common issues:"
    echo "   bash deployment/fix-connection-refused.sh"
fi

echo ""
echo "📝 Useful Commands:"
echo "   View logs: sudo journalctl -u zencrow -f"
echo "   Restart service: sudo systemctl restart zencrow"
echo "   Check status: sudo systemctl status zencrow"
echo ""

