#!/bin/bash

# Zencrow Website Deployment Script with Virtual Environment
# Run this on your Amazon Linux EC2 instance

set -e

echo "🚀 Starting Zencrow Website Deployment..."

# Check if running as ec2-user
if [ "$USER" != "ec2-user" ]; then
    echo "❌ Error: This script should be run as ec2-user"
    exit 1
fi

# Navigate to home directory
cd /home/ec2-user

# Check if directory exists
if [ -d "zencrow-website" ]; then
    echo "📁 Updating existing zencrow-website directory..."
    cd zencrow-website
    git pull origin main || echo "⚠️ Could not pull from git, continuing with existing code..."
else
    echo "❌ Error: zencrow-website directory not found"
    echo "Please clone your repository or transfer your code first"
    exit 1
fi

# Install Python if not available
if ! command -v python3 &> /dev/null; then
    echo "📦 Installing Python 3..."
    sudo yum update -y
    sudo yum install python3 python3-pip python3-devel -y
else
    echo "✅ Python 3 is already installed"
fi

# Check Python version
PYTHON_VERSION=$(python3 --version 2>&1)
echo "🐍 Python version: $PYTHON_VERSION"

# Remove old venv if it exists
if [ -d "venv" ]; then
    echo "🗑️ Removing old virtual environment..."
    rm -rf venv
fi

# Create new virtual environment
echo "🔧 Creating new virtual environment..."
python3 -m venv venv

# Activate virtual environment
echo "🚀 Activating virtual environment..."
source venv/bin/activate

# Upgrade pip
echo "⬆️ Upgrading pip..."
pip install --upgrade pip

# Install requirements
echo "📚 Installing Python dependencies..."
pip install -r requirements.txt

# Test the Flask application
echo "🧪 Testing Flask application..."
python deployment/test-app.py
if [ $? -ne 0 ]; then
    echo "❌ Flask application test failed. Please check the errors above."
    exit 1
fi

# Copy configuration files
echo "📋 Copying configuration files..."
sudo cp deployment/gunicorn.conf.py .
sudo cp deployment/zencrow.service /etc/systemd/system/

# Create log directories
echo "📁 Creating log directories..."
sudo mkdir -p /var/log/gunicorn
sudo chown ec2-user:ec2-user /var/log/gunicorn

# Install and configure Nginx
echo "🌐 Setting up Nginx..."
sudo yum install nginx -y
sudo cp deployment/nginx.conf /etc/nginx/conf.d/zencrow.conf

# Configure firewall
echo "🔥 Configuring firewall..."
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload

# Reload systemd and start services
echo "⚙️ Starting services..."
sudo systemctl daemon-reload
sudo systemctl enable zencrow
sudo systemctl enable nginx
sudo systemctl start zencrow
sudo systemctl start nginx

# Check service status
echo "📊 Checking service status..."
echo "Zencrow service status:"
sudo systemctl status zencrow --no-pager
echo ""
echo "Nginx service status:"
sudo systemctl status nginx --no-pager

# Test the application
echo "🧪 Testing application..."
sleep 5
if curl -s http://127.0.0.1:8000/health > /dev/null; then
    echo "✅ Application is responding on port 8000"
else
    echo "❌ Application is not responding on port 8000"
fi

if curl -s http://localhost > /dev/null; then
    echo "✅ Nginx is responding on port 80"
else
    echo "❌ Nginx is not responding on port 80"
fi

echo ""
echo "🎉 Deployment completed successfully!"
echo "🌐 Your application should now be accessible at:"
echo "   - Local: http://localhost"
echo "   - External: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo ""
echo "📝 Useful commands:"
echo "   - Check logs: sudo journalctl -u zencrow -f"
echo "   - Restart app: sudo systemctl restart zencrow"
echo "   - Check status: sudo systemctl status zencrow"
echo "   - Update app: ./deployment/update.sh"
