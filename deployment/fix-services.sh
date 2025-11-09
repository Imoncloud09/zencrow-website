#!/bin/bash

# Fix Services - Install service files and fix nginx
# Run this on your EC2 instance

set -e

APP_DIR="/home/ec2-user/zencrow-website"
SERVICE_NAME="zencrow"

echo "🔧 Fixing Services - zencrow and nginx"
echo "======================================"
echo ""

# Check if we're in the right directory
if [ ! -d "$APP_DIR" ]; then
    echo "❌ Application directory not found: $APP_DIR"
    echo "💡 Please deploy the application first"
    exit 1
fi

cd $APP_DIR

# Check if deployment directory exists
if [ ! -d "deployment" ]; then
    echo "❌ deployment directory not found"
    echo "💡 Please transfer your code to EC2 first"
    exit 1
fi

# Step 1: Install zencrow service
echo "📋 Step 1: Installing zencrow service"
if [ -f "deployment/zencrow.service" ]; then
    echo "   Copying service file..."
    sudo cp deployment/zencrow.service /etc/systemd/system/$SERVICE_NAME.service
    
    # Update paths in service file
    sudo sed -i "s|/home/ec2-user/zencrow-website|$APP_DIR|g" /etc/systemd/system/$SERVICE_NAME.service
    
    # Reload systemd
    sudo systemctl daemon-reload
    echo "   ✅ Service file installed"
    
    # Verify service file
    if [ -f "/etc/systemd/system/$SERVICE_NAME.service" ]; then
        echo "   ✅ Service file verified"
    else
        echo "   ❌ Service file not found after copy"
        exit 1
    fi
else
    echo "   ❌ deployment/zencrow.service not found"
    echo "   Creating service file..."
    
    # Create service file
    sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null <<EOF
[Unit]
Description=Zencrow Flask Application
After=network.target

[Service]
Type=exec
User=ec2-user
Group=ec2-user
WorkingDirectory=$APP_DIR
Environment="PATH=$APP_DIR/venv/bin:/usr/local/bin:/usr/bin:/bin"
Environment="FLASK_ENV=production"
ExecStart=$APP_DIR/venv/bin/gunicorn --config gunicorn.conf.py wsgi:application
ExecReload=/bin/kill -s HUP \$MAINPID
KillMode=mixed
TimeoutStopSec=5
PrivateTmp=true
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal
SyslogIdentifier=zencrow

[Install]
WantedBy=multi-user.target
EOF
    
    sudo systemctl daemon-reload
    echo "   ✅ Service file created"
fi

# Step 2: Setup Gunicorn configuration
echo ""
echo "⚙️  Step 2: Setting up Gunicorn configuration"
if [ -f "deployment/gunicorn.conf.py" ]; then
    cp deployment/gunicorn.conf.py gunicorn.conf.py
    # Update paths
    sed -i "s|/home/ec2-user/zencrow-website|$APP_DIR|g" gunicorn.conf.py
    echo "   ✅ Gunicorn configuration set up"
elif [ ! -f "gunicorn.conf.py" ]; then
    echo "   Creating gunicorn.conf.py..."
    cat > gunicorn.conf.py <<EOF
# Gunicorn configuration file
import os
import multiprocessing

# Server socket
bind = "127.0.0.1:8000"
backlog = 2048

# Worker processes
workers = multiprocessing.cpu_count() * 2 + 1
worker_class = "sync"
worker_connections = 1000
timeout = 30
keepalive = 2

# Restart workers after this many requests
max_requests = 1000
max_requests_jitter = 50

# Logging
accesslog = "/var/log/gunicorn/access.log"
errorlog = "/var/log/gunicorn/error.log"
loglevel = "info"
access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s"'

# Process naming
proc_name = "zencrow"

# Server mechanics
daemon = False
pidfile = None
umask = 0
user = None
group = None
tmp_upload_dir = None

# Preload app for better performance
preload_app = True

# Reload on code changes (disabled in production)
reload = False

# Ensure proper Python path
pythonpath = os.path.dirname(os.path.abspath(__file__))
EOF
    echo "   ✅ Gunicorn configuration created"
fi

# Step 3: Create log directories
echo ""
echo "📝 Step 3: Creating log directories"
sudo mkdir -p /var/log/gunicorn
sudo chown ec2-user:ec2-user /var/log/gunicorn
sudo chmod 755 /var/log/gunicorn
echo "   ✅ Log directories created"

# Step 4: Fix nginx configuration
echo ""
echo "🌐 Step 4: Fixing nginx configuration"

# Check if nginx is installed
if ! command -v nginx &> /dev/null; then
    echo "   Installing nginx..."
    sudo yum install -y nginx
    echo "   ✅ Nginx installed"
fi

# Remove default nginx configuration if it conflicts
if [ -f "/etc/nginx/conf.d/default.conf" ]; then
    echo "   Removing default nginx configuration..."
    sudo rm -f /etc/nginx/conf.d/default.conf
fi

# Create or update nginx configuration
if [ -f "deployment/nginx.conf" ]; then
    echo "   Copying nginx configuration..."
    sudo cp deployment/nginx.conf /etc/nginx/conf.d/$SERVICE_NAME.conf
else
    echo "   Creating nginx configuration..."
    PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "_")
    sudo tee /etc/nginx/conf.d/$SERVICE_NAME.conf > /dev/null <<EOF
server {
    listen 80;
    server_name $PUBLIC_IP _;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    location /static {
        alias $APP_DIR/app/static;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    location /public {
        alias $APP_DIR/public;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
EOF
fi

# Update paths in nginx configuration
sudo sed -i "s|/home/ec2-user/zencrow-website|$APP_DIR|g" /etc/nginx/conf.d/$SERVICE_NAME.conf

# Test nginx configuration
echo "   Testing nginx configuration..."
if sudo nginx -t 2>&1; then
    echo "   ✅ Nginx configuration is valid"
else
    echo "   ❌ Nginx configuration has errors:"
    sudo nginx -t 2>&1 | sed 's/^/      /'
    echo ""
    echo "   Trying to fix common issues..."
    
    # Check if there are syntax errors in main nginx.conf
    if sudo nginx -t 2>&1 | grep -q "nginx.conf"; then
        echo "   Checking main nginx configuration..."
        # Ensure main nginx.conf includes conf.d
        if ! grep -q "include /etc/nginx/conf.d/\*.conf;" /etc/nginx/nginx.conf; then
            echo "   Adding include directive to nginx.conf..."
            sudo sed -i '/http {/a\    include /etc/nginx/conf.d/*.conf;' /etc/nginx/nginx.conf
        fi
    fi
    
    # Test again
    if sudo nginx -t 2>&1; then
        echo "   ✅ Nginx configuration fixed"
    else
        echo "   ❌ Still has errors. Please check manually:"
        sudo nginx -t
        exit 1
    fi
fi

# Step 5: Verify virtual environment
echo ""
echo "🐍 Step 5: Verifying virtual environment"
if [ ! -d "venv" ]; then
    echo "   ❌ Virtual environment not found"
    echo "   Creating virtual environment..."
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    echo "   ✅ Virtual environment created"
else
    echo "   ✅ Virtual environment exists"
    source venv/bin/activate
    # Verify gunicorn is installed
    if ! python -c "import gunicorn" 2>/dev/null; then
        echo "   Installing gunicorn..."
        pip install gunicorn
    fi
fi

# Step 6: Test application
echo ""
echo "🧪 Step 6: Testing application"
if python -c "from app import create_app; app = create_app()" 2>/dev/null; then
    echo "   ✅ Application test passed"
else
    echo "   ❌ Application test failed"
    echo "   Error:"
    python -c "from app import create_app; app = create_app()" 2>&1 | head -5
    echo "   💡 Please fix application errors first"
    exit 1
fi

# Step 7: Fix file permissions
echo ""
echo "🔐 Step 7: Fixing file permissions"
sudo chown -R ec2-user:ec2-user $APP_DIR
sudo chmod +x $APP_DIR/venv/bin/gunicorn 2>/dev/null || true
echo "   ✅ File permissions fixed"

# Step 8: Start services
echo ""
echo "🚀 Step 8: Starting services"

# Enable and start zencrow service
echo "   Starting zencrow service..."
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
sudo systemctl start $SERVICE_NAME

# Wait a moment
sleep 3

# Check if service started
if sudo systemctl is-active --quiet $SERVICE_NAME; then
    echo "   ✅ zencrow service started successfully"
else
    echo "   ❌ zencrow service failed to start"
    echo "   Logs:"
    sudo journalctl -u $SERVICE_NAME -n 20 --no-pager | sed 's/^/      /'
    exit 1
fi

# Start nginx
echo "   Starting nginx service..."
sudo systemctl enable nginx
sudo systemctl start nginx

# Wait a moment
sleep 2

# Check if nginx started
if sudo systemctl is-active --quiet nginx; then
    echo "   ✅ nginx service started successfully"
else
    echo "   ❌ nginx service failed to start"
    echo "   Logs:"
    sudo journalctl -u nginx -n 20 --no-pager | sed 's/^/      /'
    echo "   Nginx error log:"
    sudo tail -10 /var/log/nginx/error.log 2>/dev/null | sed 's/^/      /' || echo "      (No error log found)"
    exit 1
fi

# Step 9: Verify services
echo ""
echo "🔍 Step 9: Verifying services"

# Check port 8000
if netstat -tlnp 2>/dev/null | grep :8000 > /dev/null || ss -tlnp 2>/dev/null | grep :8000 > /dev/null; then
    echo "   ✅ Port 8000 (Gunicorn) is listening"
else
    echo "   ⚠️  Port 8000 (Gunicorn) is NOT listening"
fi

# Check port 80
if netstat -tlnp 2>/dev/null | grep :80 > /dev/null || ss -tlnp 2>/dev/null | grep :80 > /dev/null; then
    echo "   ✅ Port 80 (HTTP) is listening"
else
    echo "   ⚠️  Port 80 (HTTP) is NOT listening"
fi

# Test health endpoint
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo "   ✅ Health endpoint is responding"
else
    echo "   ⚠️  Health endpoint is NOT responding yet (may take a moment)"
fi

# Get public IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "Not available")

# Summary
echo ""
echo "=========================================="
echo "✅ Services Fixed and Started!"
echo "=========================================="
echo ""
echo "📊 Service Status:"
sudo systemctl status $SERVICE_NAME --no-pager -l | head -5
echo ""
sudo systemctl status nginx --no-pager -l | head -5
echo ""
echo "🌐 Public IP: $PUBLIC_IP"
echo "🔗 Application URL: http://$PUBLIC_IP"
echo ""
echo "📝 Useful Commands:"
echo "   View zencrow logs: sudo journalctl -u zencrow -f"
echo "   View nginx logs: sudo journalctl -u nginx -f"
echo "   Restart services: sudo systemctl restart $SERVICE_NAME nginx"
echo "   Check status: sudo systemctl status $SERVICE_NAME nginx"
echo ""
echo "⚠️  IMPORTANT: If you still can't access from browser:"
echo "   Check AWS Security Group allows HTTP (port 80) from 0.0.0.0/0"
echo ""

