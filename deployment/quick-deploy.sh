#!/bin/bash

# Quick deployment script for EC2
# Run this directly on your EC2 instance after transferring code

set -e

APP_DIR="/home/ec2-user/zencrow-website"

echo "🚀 Quick Deployment Script for Zencrow Website"
echo "=============================================="

# Check if we're in the right directory
if [ ! -f "requirements.txt" ]; then
    echo "❌ Error: requirements.txt not found!"
    echo "Please run this script from the zencrow-website directory"
    exit 1
fi

# Make sure we're in the app directory
cd "$APP_DIR" 2>/dev/null || cd "$(dirname "$0")/.."

# Stop services
echo "🛑 Stopping services..."
sudo systemctl stop zencrow 2>/dev/null || true
sudo systemctl stop nginx 2>/dev/null || true

# Setup Python environment
echo "🐍 Setting up Python environment..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

source venv/bin/activate
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt

# Create instance directory
mkdir -p instance
chmod 755 instance

# Create .env if it doesn't exist
if [ ! -f ".env" ]; then
    echo "⚙️ Creating .env file..."
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
fi

# Test application
echo "🧪 Testing application..."
python -c "from app import create_app; app = create_app()" || {
    echo "❌ Application test failed!"
    exit 1
}

# Fix permissions
echo "🔐 Fixing permissions..."
sudo chown -R ec2-user:ec2-user .

# Create log directories
sudo mkdir -p /var/log/gunicorn
sudo chown ec2-user:ec2-user /var/log/gunicorn

# Copy configuration files
echo "📋 Copying configuration files..."
if [ -f "deployment/gunicorn.conf.py" ]; then
    cp deployment/gunicorn.conf.py gunicorn.conf.py
fi

if [ -f "deployment/zencrow.service" ]; then
    sudo cp deployment/zencrow.service /etc/systemd/system/
    sudo sed -i "s|/home/ec2-user/zencrow-website|$(pwd)|g" /etc/systemd/system/zencrow.service
fi

if [ -f "deployment/nginx.conf" ]; then
    sudo cp deployment/nginx.conf /etc/nginx/conf.d/zencrow.conf
    sudo sed -i "s|/home/ec2-user/zencrow-website|$(pwd)|g" /etc/nginx/conf.d/zencrow.conf
    PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "_")
    sudo sed -i "s|your-domain.com|$PUBLIC_IP|g" /etc/nginx/conf.d/zencrow.conf
fi

# Test nginx config
sudo nginx -t

# Start services
echo "🚀 Starting services..."
sudo systemctl daemon-reload
sudo systemctl enable zencrow
sudo systemctl enable nginx
sudo systemctl start zencrow
sudo systemctl start nginx

# Wait a moment
sleep 3

# Check status
echo "📊 Service Status:"
sudo systemctl status zencrow --no-pager -l | head -15

echo ""
echo "✅ Deployment completed!"
echo "🌐 Your application should be accessible at:"
echo "   http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo 'your-ec2-ip')"

