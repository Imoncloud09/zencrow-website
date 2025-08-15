#!/bin/bash

# Zencrow Website Quick Fix Script
# Run this script to fix common deployment issues

echo "🔧 Zencrow Website Quick Fix Script"
echo "==================================="

# Stop services first
echo "🛑 Stopping services..."
sudo systemctl stop zencrow
sudo systemctl stop nginx

# Fix file permissions
echo "🔐 Fixing file permissions..."
sudo chown -R ec2-user:ec2-user /home/ec2-user/zencrow-website
chmod +x deployment/*.sh

# Ensure virtual environment is properly set up
echo "🐍 Setting up virtual environment..."
cd /home/ec2-user/zencrow-website
if [ ! -d "venv" ]; then
    echo "Creating new virtual environment..."
    python3 -m venv venv
fi

source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# Test the Flask application
echo "🧪 Testing Flask application..."
python deployment/test-app.py
if [ $? -ne 0 ]; then
    echo "❌ Flask application test failed. Please check the errors above."
    echo "This needs to be fixed before the service can start."
    exit 1
fi

# Create log directories with proper permissions
echo "📝 Creating log directories..."
sudo mkdir -p /var/log/gunicorn
sudo chown ec2-user:ec2-user /var/log/gunicorn

# Copy configuration files to correct locations
echo "📋 Copying configuration files..."
sudo cp deployment/nginx.conf /etc/nginx/conf.d/zencrow.conf
sudo cp deployment/zencrow.service /etc/systemd/system/
sudo cp deployment/gunicorn.conf.py /home/ec2-user/zencrow-website/

# Reload systemd and start services
echo "🚀 Starting services..."
sudo systemctl daemon-reload
sudo systemctl enable zencrow
sudo systemctl start zencrow

# Wait a moment for the service to start
sleep 3

# Check if the service started successfully
if sudo systemctl is-active --quiet zencrow; then
    echo "✅ zencrow service started successfully"
else
    echo "❌ zencrow service failed to start"
    echo "Checking logs..."
    sudo journalctl -u zencrow -n 20 --no-pager
fi

# Start Nginx
echo "🌐 Starting Nginx..."
sudo systemctl enable nginx
sudo systemctl start nginx

# Check Nginx status
if sudo systemctl is-active --quiet nginx; then
    echo "✅ Nginx started successfully"
else
    echo "❌ Nginx failed to start"
    echo "Checking Nginx logs..."
    sudo tail -n 20 /var/log/nginx/error.log
fi

# Check if ports are listening
echo "🔌 Checking ports..."
echo "Port 8000 (Gunicorn):"
sudo netstat -tlnp | grep :8000 || echo "Port 8000 not listening"
echo "Port 80 (Nginx):"
sudo netstat -tlnp | grep :80 || echo "Port 80 not listening"

# Test the application locally
echo "🧪 Testing application locally..."
if curl -s http://127.0.0.1:8000/health > /dev/null; then
    echo "✅ Application responds on localhost:8000"
else
    echo "❌ Application not responding on localhost:8000"
fi

echo ""
echo "🔧 Quick fix completed!"
echo "If issues persist, run the troubleshooting script:"
echo "./deployment/troubleshoot.sh"
