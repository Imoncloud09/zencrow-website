#!/bin/bash

# Deployment script to run AFTER uploading files to EC2
# This script will set up and deploy the application

set -e

APP_DIR="/home/ec2-user/zencrow-website"
SERVICE_NAME="zencrow"

echo "🚀 Zencrow Website Deployment - After Upload"
echo "============================================="
echo ""

# Check if running as ec2-user
if [ "$USER" != "ec2-user" ]; then
    echo "❌ This script should be run as ec2-user"
    exit 1
fi

# Check if application directory exists
if [ ! -d "$APP_DIR" ]; then
    echo "❌ Application directory not found: $APP_DIR"
    echo "💡 Please upload your application files first"
    exit 1
fi

cd $APP_DIR

# Check if required files exist
if [ ! -f "requirements.txt" ]; then
    echo "❌ requirements.txt not found!"
    echo "💡 Please ensure all application files are uploaded"
    exit 1
fi

if [ ! -f "wsgi.py" ]; then
    echo "❌ wsgi.py not found!"
    echo "💡 Please ensure all application files are uploaded"
    exit 1
fi

echo "✅ Application files found"
echo ""

# Step 1: Update system and install dependencies
echo "📦 Step 1: Installing system dependencies..."
sudo yum update -y
sudo yum install -y python3 python3-pip python3-devel nginx git gcc

# Install development tools if needed
sudo yum groupinstall -y "Development Tools" 2>/dev/null || sudo yum install -y gcc gcc-c++ make

echo "✅ System dependencies installed"
echo ""

# Step 2: Setup Python virtual environment
echo "🐍 Step 2: Setting up Python virtual environment..."

# Remove old venv if exists
if [ -d "venv" ]; then
    echo "   Removing old virtual environment..."
    rm -rf venv
fi

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip setuptools wheel

echo "✅ Virtual environment created"
echo ""

# Step 3: Install Python dependencies
echo "📚 Step 3: Installing Python dependencies..."
pip install -r requirements.txt

echo "✅ Python dependencies installed"
echo ""

# Step 4: Test application
echo "🧪 Step 4: Testing application..."
if python -c "from app import create_app; app = create_app()" 2>/dev/null; then
    echo "✅ Application test passed"
else
    echo "❌ Application test failed"
    echo "Error:"
    python -c "from app import create_app; app = create_app()" 2>&1 | head -10
    exit 1
fi
echo ""

# Step 5: Create .env file
echo "⚙️  Step 5: Setting up environment configuration..."
if [ ! -f ".env" ]; then
    SECRET_KEY=$(python3 -c 'import secrets; print(secrets.token_hex(32))')
    cat > .env << EOF
FLASK_ENV=production
SECRET_KEY=$SECRET_KEY
DATABASE_URL=sqlite:///instance/zencrow.db
MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587
MAIL_USE_TLS=True
MAIL_USERNAME=
MAIL_PASSWORD=
EOF
    echo "✅ .env file created"
else
    echo "✅ .env file already exists"
fi

# Create instance directory
mkdir -p instance
chmod 755 instance

echo ""

# Step 6: Setup Gunicorn configuration
echo "⚙️  Step 6: Setting up Gunicorn configuration..."
if [ -f "deployment/gunicorn.conf.py" ]; then
    cp deployment/gunicorn.conf.py gunicorn.conf.py
else
    # Create gunicorn config
    cat > gunicorn.conf.py << 'EOF'
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
fi

# Update paths
sed -i "s|/home/ec2-user/zencrow-website|$APP_DIR|g" gunicorn.conf.py

echo "✅ Gunicorn configuration set up"
echo ""

# Step 7: Create log directories
echo "📝 Step 7: Creating log directories..."
sudo mkdir -p /var/log/gunicorn
sudo chown ec2-user:ec2-user /var/log/gunicorn
sudo chmod 755 /var/log/gunicorn

echo "✅ Log directories created"
echo ""

# Step 8: Setup systemd service
echo "🚀 Step 8: Setting up systemd service..."
if [ -f "deployment/zencrow.service" ]; then
    sudo cp deployment/zencrow.service /etc/systemd/system/$SERVICE_NAME.service
else
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
fi

# Update paths in service file
sudo sed -i "s|/home/ec2-user/zencrow-website|$APP_DIR|g" /etc/systemd/system/$SERVICE_NAME.service

# Reload systemd
sudo systemctl daemon-reload

echo "✅ Systemd service configured"
echo ""

# Step 9: Setup Nginx
echo "🌐 Step 9: Setting up Nginx..."

# Remove default nginx configuration
sudo rm -f /etc/nginx/conf.d/default.conf

# Create nginx configuration
if [ -f "deployment/nginx.conf" ]; then
    sudo cp deployment/nginx.conf /etc/nginx/conf.d/$SERVICE_NAME.conf
else
    # Create nginx config
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

# Update paths in nginx config
sudo sed -i "s|/home/ec2-user/zencrow-website|$APP_DIR|g" /etc/nginx/conf.d/$SERVICE_NAME.conf

# Update server_name with public IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "_")
sudo sed -i "s|your-domain.com|$PUBLIC_IP|g" /etc/nginx/conf.d/$SERVICE_NAME.conf

# Test nginx configuration
if sudo nginx -t 2>&1; then
    echo "✅ Nginx configuration is valid"
else
    echo "❌ Nginx configuration has errors"
    sudo nginx -t
    exit 1
fi

echo "✅ Nginx configured"
echo ""

# Step 10: Fix file permissions
echo "🔐 Step 10: Fixing file permissions..."
sudo chown -R ec2-user:ec2-user $APP_DIR
chmod +x deployment/*.sh 2>/dev/null || true

echo "✅ File permissions fixed"
echo ""

# Step 11: Enable and start services
echo "🚀 Step 11: Starting services..."

# Enable and start zencrow
sudo systemctl enable $SERVICE_NAME
sudo systemctl start $SERVICE_NAME

# Wait for service to start
sleep 3

# Check if service started
if sudo systemctl is-active --quiet $SERVICE_NAME; then
    echo "✅ zencrow service started"
else
    echo "❌ zencrow service failed to start"
    echo "Logs:"
    sudo journalctl -u $SERVICE_NAME -n 20 --no-pager
    exit 1
fi

# Enable and start nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Wait for nginx to start
sleep 2

# Check if nginx started
if sudo systemctl is-active --quiet nginx; then
    echo "✅ nginx service started"
else
    echo "❌ nginx service failed to start"
    echo "Logs:"
    sudo journalctl -u nginx -n 20 --no-pager
    exit 1
fi

echo ""

# Step 12: Verify deployment
echo "🔍 Step 12: Verifying deployment..."

# Check port 8000
if netstat -tlnp 2>/dev/null | grep :8000 > /dev/null || ss -tlnp 2>/dev/null | grep :8000 > /dev/null; then
    echo "✅ Port 8000 (Gunicorn) is listening"
else
    echo "⚠️  Port 8000 (Gunicorn) is NOT listening"
fi

# Check port 80
if netstat -tlnp 2>/dev/null | grep :80 > /dev/null || ss -tlnp 2>/dev/null | grep :80 > /dev/null; then
    echo "✅ Port 80 (HTTP) is listening"
else
    echo "⚠️  Port 80 (HTTP) is NOT listening"
fi

# Test health endpoint
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo "✅ Health endpoint is responding"
    curl -s http://localhost:8000/health | python3 -m json.tool 2>/dev/null || curl -s http://localhost:8000/health
else
    echo "⚠️  Health endpoint is NOT responding yet (may take a moment)"
fi

# Get public IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "Not available")

# Summary
echo ""
echo "=========================================="
echo "✅ Deployment Completed Successfully!"
echo "=========================================="
echo ""
echo "📊 Service Status:"
sudo systemctl status $SERVICE_NAME --no-pager -l | head -5
echo ""
echo "🌐 Public IP: $PUBLIC_IP"
echo "🔗 Application URL: http://$PUBLIC_IP"
echo ""
echo "📝 Useful Commands:"
echo "   View logs: sudo journalctl -u $SERVICE_NAME -f"
echo "   Restart service: sudo systemctl restart $SERVICE_NAME"
echo "   Check status: sudo systemctl status $SERVICE_NAME"
echo "   View Nginx logs: sudo tail -f /var/log/nginx/error.log"
echo ""
echo "⚠️  IMPORTANT: If you can't access from browser:"
echo "   1. Check AWS Security Group allows HTTP (port 80) from 0.0.0.0/0"
echo "   2. Go to: AWS Console → EC2 → Instances → Security Group"
echo "   3. Add inbound rule: HTTP, Port 80, Source: 0.0.0.0/0"
echo ""

