#!/bin/bash

# Zencrow Website Deployment Script for Amazon Linux EC2
# Run this script as ec2-user after connecting to your EC2 instance

set -e

echo "🚀 Starting Zencrow Website Deployment..."

# Update system packages
echo "📦 Updating system packages..."
sudo yum update -y

# Install required packages
echo "🔧 Installing required packages..."
sudo yum install -y python3 python3-pip python3-devel nginx git

# Install development tools for building packages
sudo yum groupinstall -y "Development Tools"

# Create application directory
echo "📁 Setting up application directory..."
cd /home/ec2-user
if [ -d "zencrow-website" ]; then
    echo "Directory already exists, updating..."
    cd zencrow-website
    git pull origin main
else
    echo "Cloning repository..."
    git clone https://github.com/yourusername/zencrow-website.git
    cd zencrow-website
fi

# Create and activate virtual environment
echo "🐍 Setting up Python virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
echo "📚 Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# Test the Flask application
echo "🧪 Testing Flask application..."
python deployment/test-app.py
if [ $? -ne 0 ]; then
    echo "❌ Flask application test failed. Please check the errors above."
    exit 1
fi

# Create environment file
echo "⚙️ Creating environment configuration..."
cat > .env << EOF
FLASK_ENV=production
SECRET_KEY=$(python3 -c 'import secrets; print(secrets.token_hex(32))')
DATABASE_URL=sqlite:///zencrow.db
MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587
MAIL_USE_TLS=True
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=your-app-password
EOF

echo "⚠️  Please edit .env file with your actual email credentials!"

# Create log directories
echo "📝 Creating log directories..."
sudo mkdir -p /var/log/gunicorn
sudo chown ec2-user:ec2-user /var/log/gunicorn

# Copy configuration files
echo "📋 Copying configuration files..."
sudo cp deployment/nginx.conf /etc/nginx/conf.d/zencrow.conf
sudo cp deployment/zencrow.service /etc/systemd/system/
sudo cp deployment/gunicorn.conf.py /home/ec2-user/zencrow-website/

# Configure Nginx
echo "🌐 Configuring Nginx..."
sudo sed -i 's/your-domain.com/your-actual-domain.com/g' /etc/nginx/conf.d/zencrow.conf
sudo systemctl enable nginx
sudo systemctl start nginx

# Configure firewall
echo "🔥 Configuring firewall..."
sudo yum install -y firewalld
sudo systemctl enable firewalld
sudo systemctl start firewalld
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload

# Enable and start the application service
echo "🚀 Starting application service..."
sudo systemctl daemon-reload
sudo systemctl enable zencrow
sudo systemctl start zencrow

# Check service status
echo "📊 Checking service status..."
sudo systemctl status zencrow --no-pager
sudo systemctl status nginx --no-pager

echo "✅ Deployment completed successfully!"
echo "🌐 Your application should be accessible at: http://your-ec2-public-ip"
echo "📝 Check logs with: sudo journalctl -u zencrow -f"
echo "🔄 Restart service with: sudo systemctl restart zencrow"
