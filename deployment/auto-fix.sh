#!/bin/bash

# Auto-fix script for Zencrow deployment issues
# This script will attempt to fix common deployment issues automatically

set -e

APP_DIR="/home/ec2-user/zencrow-website"
SERVICE_NAME="zencrow"

echo "🔧 Auto-Fix Script for Zencrow Deployment"
echo "=========================================="
echo ""

# Function to print status
print_info() {
    echo "✅ $1"
}

print_error() {
    echo "❌ $1"
}

print_warning() {
    echo "⚠️  $1"
}

# Step 1: Check if application directory exists
echo "📁 Step 1: Checking Application Directory"
if [ ! -d "$APP_DIR" ]; then
    print_error "Application directory not found: $APP_DIR"
    print_warning "Creating directory..."
    mkdir -p $APP_DIR
    print_info "Directory created. You need to deploy the application."
    print_warning "Run: bash deployment/deploy-aws.sh (after transferring code)"
    exit 1
else
    print_info "Application directory exists"
    cd $APP_DIR
fi

# Step 2: Check if code is deployed
echo ""
echo "📄 Step 2: Checking Application Files"
if [ ! -f "wsgi.py" ] || [ ! -f "requirements.txt" ]; then
    print_error "Application files not found"
    print_warning "Application needs to be deployed"
    print_info "Please transfer your code to EC2 and run deployment script"
    exit 1
else
    print_info "Application files found"
fi

# Step 3: Setup Python environment
echo ""
echo "🐍 Step 3: Setting Up Python Environment"
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 not found"
    print_warning "Installing Python 3..."
    sudo yum update -y
    sudo yum install -y python3 python3-pip python3-devel
    print_info "Python 3 installed"
else
    print_info "Python 3 is installed: $(python3 --version)"
fi

# Step 4: Setup virtual environment
echo ""
echo "🔧 Step 4: Setting Up Virtual Environment"
if [ ! -d "venv" ]; then
    print_warning "Virtual environment not found. Creating..."
    python3 -m venv venv
    print_info "Virtual environment created"
fi

source venv/bin/activate
print_info "Virtual environment activated"

# Upgrade pip
pip install --upgrade pip setuptools wheel --quiet

# Install dependencies
if [ -f "requirements.txt" ]; then
    print_info "Installing Python dependencies..."
    pip install -r requirements.txt --quiet
    print_info "Dependencies installed"
else
    print_error "requirements.txt not found"
    exit 1
fi

# Step 5: Create .env file if it doesn't exist
echo ""
echo "⚙️  Step 5: Setting Up Environment Configuration"
if [ ! -f ".env" ]; then
    print_warning ".env file not found. Creating..."
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
    print_info ".env file created"
else
    print_info ".env file exists"
fi

# Create instance directory
mkdir -p instance
chmod 755 instance

# Step 6: Test application
echo ""
echo "🧪 Step 6: Testing Application"
if python -c "from app import create_app; app = create_app()" 2>/dev/null; then
    print_info "Application test passed"
else
    print_error "Application test failed"
    echo "Error:"
    python -c "from app import create_app; app = create_app()" 2>&1 | head -10
    exit 1
fi

# Step 7: Create log directories
echo ""
echo "📝 Step 7: Setting Up Log Directories"
sudo mkdir -p /var/log/gunicorn
sudo chown ec2-user:ec2-user /var/log/gunicorn
sudo chmod 755 /var/log/gunicorn
print_info "Log directories created"

# Step 8: Fix file permissions
echo ""
echo "🔐 Step 8: Fixing File Permissions"
sudo chown -R ec2-user:ec2-user $APP_DIR
print_info "File permissions fixed"

# Step 9: Setup Gunicorn configuration
echo ""
echo "⚙️  Step 9: Setting Up Gunicorn Configuration"
if [ -f "deployment/gunicorn.conf.py" ]; then
    cp deployment/gunicorn.conf.py gunicorn.conf.py
    # Update paths in gunicorn.conf.py
    sed -i "s|/home/ec2-user/zencrow-website|$APP_DIR|g" gunicorn.conf.py
    print_info "Gunicorn configuration set up"
else
    print_warning "deployment/gunicorn.conf.py not found"
fi

# Step 10: Setup systemd service
echo ""
echo "🚀 Step 10: Setting Up Systemd Service"
if [ -f "deployment/zencrow.service" ]; then
    sudo cp deployment/zencrow.service /etc/systemd/system/$SERVICE_NAME.service
    # Update paths in service file
    sudo sed -i "s|/home/ec2-user/zencrow-website|$APP_DIR|g" /etc/systemd/system/$SERVICE_NAME.service
    sudo systemctl daemon-reload
    print_info "Systemd service configured"
else
    print_warning "deployment/zencrow.service not found"
fi

# Step 11: Setup Nginx
echo ""
echo "🌐 Step 11: Setting Up Nginx"
# Install Nginx if not installed
if ! command -v nginx &> /dev/null; then
    print_warning "Nginx not installed. Installing..."
    sudo yum install -y nginx
    print_info "Nginx installed"
fi

if [ -f "deployment/nginx.conf" ]; then
    sudo cp deployment/nginx.conf /etc/nginx/conf.d/$SERVICE_NAME.conf
    # Update paths in nginx.conf
    sudo sed -i "s|/home/ec2-user/zencrow-website|$APP_DIR|g" /etc/nginx/conf.d/$SERVICE_NAME.conf
    # Update server_name
    PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "_")
    sudo sed -i "s|your-domain.com|$PUBLIC_IP|g" /etc/nginx/conf.d/$SERVICE_NAME.conf
    
    # Test nginx configuration
    if sudo nginx -t 2>&1; then
        print_info "Nginx configuration is valid"
    else
        print_error "Nginx configuration has errors"
        sudo nginx -t
        exit 1
    fi
else
    print_warning "deployment/nginx.conf not found"
fi

# Step 12: Start services
echo ""
echo "🚀 Step 12: Starting Services"

# Enable and start zencrow service
if [ -f "/etc/systemd/system/$SERVICE_NAME.service" ]; then
    sudo systemctl enable $SERVICE_NAME
    if sudo systemctl is-active --quiet $SERVICE_NAME; then
        print_info "zencrow service is already running"
    else
        print_warning "Starting zencrow service..."
        sudo systemctl start $SERVICE_NAME
        sleep 3
        if sudo systemctl is-active --quiet $SERVICE_NAME; then
            print_info "zencrow service started"
        else
            print_error "zencrow service failed to start"
            echo "Logs:"
            sudo journalctl -u $SERVICE_NAME -n 20 --no-pager
            exit 1
        fi
    fi
else
    print_warning "Service file not found. Cannot start service."
fi

# Enable and start nginx
sudo systemctl enable nginx
if sudo systemctl is-active --quiet nginx; then
    print_info "nginx service is already running"
    sudo systemctl restart nginx
else
    print_warning "Starting nginx service..."
    sudo systemctl start nginx
    sleep 2
    if sudo systemctl is-active --quiet nginx; then
        print_info "nginx service started"
    else
        print_error "nginx service failed to start"
        sudo systemctl status nginx --no-pager -l | head -10
        exit 1
    fi
fi

# Step 13: Verify services
echo ""
echo "🔍 Step 13: Verifying Services"

# Check port 8000
if netstat -tlnp 2>/dev/null | grep :8000 > /dev/null || ss -tlnp 2>/dev/null | grep :8000 > /dev/null; then
    print_info "Port 8000 (Gunicorn) is listening"
else
    print_error "Port 8000 (Gunicorn) is NOT listening"
fi

# Check port 80
if netstat -tlnp 2>/dev/null | grep :80 > /dev/null || ss -tlnp 2>/dev/null | grep :80 > /dev/null; then
    print_info "Port 80 (HTTP) is listening"
else
    print_error "Port 80 (HTTP) is NOT listening"
fi

# Test health endpoint
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    print_info "Health endpoint is responding"
else
    print_warning "Health endpoint is NOT responding"
fi

# Get public IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "Not available")

# Summary
echo ""
echo "=========================================="
echo "✅ Auto-Fix Completed!"
echo "=========================================="
echo ""
echo "🌐 Public IP: $PUBLIC_IP"
echo "🔗 Application URL: http://$PUBLIC_IP"
echo ""
echo "📊 Service Status:"
sudo systemctl status $SERVICE_NAME --no-pager -l | head -5
echo ""
echo "⚠️  IMPORTANT: If you still can't access from browser:"
echo "   1. Check AWS Security Group allows HTTP (port 80) from 0.0.0.0/0"
echo "   2. Go to: AWS Console → EC2 → Instances → Security Group"
echo "   3. Add inbound rule: HTTP, Port 80, Source: 0.0.0.0/0"
echo ""
echo "📝 Useful Commands:"
echo "   View logs: sudo journalctl -u $SERVICE_NAME -f"
echo "   Restart: sudo systemctl restart $SERVICE_NAME"
echo "   Status: sudo systemctl status $SERVICE_NAME"
echo ""

