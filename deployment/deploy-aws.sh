#!/bin/bash

# Zencrow Website Deployment Script for Amazon Linux EC2
# This script handles deployment on Amazon Linux 2 and Amazon Linux 2023
# Run this script on your EC2 instance

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Check if running as ec2-user
if [ "$USER" != "ec2-user" ]; then
    print_error "This script should be run as ec2-user"
    exit 1
fi

APP_DIR="/home/ec2-user/zencrow-website"
SERVICE_NAME="zencrow"

echo "🚀 Starting Zencrow Website Deployment on Amazon Linux EC2..."
echo "=============================================================="

# Detect Amazon Linux version
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$ID" == "amzn" ]]; then
        if [[ "$VERSION_ID" == "2" ]]; then
            AMAZON_LINUX_VERSION="2"
            PACKAGE_MANAGER="yum"
        else
            AMAZON_LINUX_VERSION="2023"
            PACKAGE_MANAGER="dnf"
        fi
        print_info "Detected Amazon Linux $AMAZON_LINUX_VERSION"
    else
        print_warning "Not Amazon Linux, using yum as package manager"
        PACKAGE_MANAGER="yum"
    fi
else
    print_warning "Cannot detect OS version, using yum"
    PACKAGE_MANAGER="yum"
fi

# Update system packages
print_info "Updating system packages..."
sudo $PACKAGE_MANAGER update -y

# Install required packages
print_info "Installing required packages..."
if [ "$PACKAGE_MANAGER" == "dnf" ]; then
    sudo dnf install -y python3 python3-pip python3-devel nginx git gcc
    sudo dnf groupinstall -y "Development Tools" || sudo dnf install -y gcc gcc-c++ make
else
    sudo yum install -y python3 python3-pip python3-devel nginx git gcc
    sudo yum groupinstall -y "Development Tools" || sudo yum install -y gcc gcc-c++ make
fi

# Check if application directory exists
if [ ! -d "$APP_DIR" ]; then
    print_error "Application directory not found at $APP_DIR"
    print_info "Please transfer your code to $APP_DIR first"
    print_info "You can use SCP or Git to transfer the code"
    exit 1
fi

# Navigate to application directory
cd $APP_DIR
print_info "Working directory: $(pwd)"

# Check for required files
if [ ! -f "requirements.txt" ]; then
    print_error "requirements.txt not found!"
    exit 1
fi

if [ ! -f "wsgi.py" ]; then
    print_error "wsgi.py not found!"
    exit 1
fi

# Check Python installation
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 is not installed!"
    exit 1
fi

PYTHON_VERSION=$(python3 --version)
print_info "Python version: $PYTHON_VERSION"

# Remove old virtual environment if it exists
if [ -d "venv" ]; then
    print_warning "Removing old virtual environment..."
    rm -rf venv
fi

# Create virtual environment
print_info "Creating Python virtual environment..."
python3 -m venv venv

# Activate virtual environment
print_info "Activating virtual environment..."
source venv/bin/activate

# Upgrade pip
print_info "Upgrading pip..."
pip install --upgrade pip setuptools wheel

# Install Python dependencies
print_info "Installing Python dependencies..."
pip install -r requirements.txt

# Test the Flask application
print_info "Testing Flask application..."
if [ -f "deployment/test-app.py" ]; then
    python deployment/test-app.py || {
        print_error "Flask application test failed!"
        print_info "Checking for common issues..."
        python -c "from app import create_app; app = create_app()" || {
            print_error "Application creation failed. Check the error above."
            exit 1
        }
    }
else
    print_warning "test-app.py not found, skipping test"
    # Try to create app directly
    python -c "from app import create_app; app = create_app()" || {
        print_error "Application creation failed. Check the error above."
        exit 1
    }
fi

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    print_info "Creating .env file..."
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
    print_warning "Created .env file with default values. Please update with your email credentials if needed."
else
    print_info ".env file already exists, keeping existing configuration"
fi

# Create instance directory for database
mkdir -p instance
chmod 755 instance

# Create log directories with proper permissions
print_info "Creating log directories..."
sudo mkdir -p /var/log/gunicorn
sudo chown ec2-user:ec2-user /var/log/gunicorn
sudo chmod 755 /var/log/gunicorn

# Fix file permissions
print_info "Fixing file permissions..."
sudo chown -R ec2-user:ec2-user $APP_DIR
chmod +x deployment/*.sh 2>/dev/null || true

# Copy gunicorn configuration
print_info "Setting up Gunicorn configuration..."
if [ -f "deployment/gunicorn.conf.py" ]; then
    cp deployment/gunicorn.conf.py $APP_DIR/gunicorn.conf.py
else
    print_warning "deployment/gunicorn.conf.py not found, using existing gunicorn.conf.py"
fi

# Verify gunicorn configuration
if [ ! -f "$APP_DIR/gunicorn.conf.py" ]; then
    print_error "gunicorn.conf.py not found!"
    exit 1
fi

# Update gunicorn.conf.py with correct paths
sed -i "s|/home/ec2-user/zencrow-website|$APP_DIR|g" $APP_DIR/gunicorn.conf.py

# Copy systemd service file
print_info "Setting up systemd service..."
if [ -f "deployment/zencrow.service" ]; then
    sudo cp deployment/zencrow.service /etc/systemd/system/$SERVICE_NAME.service
else
    print_error "deployment/zencrow.service not found!"
    exit 1
fi

# Update service file with correct paths
sudo sed -i "s|/home/ec2-user/zencrow-website|$APP_DIR|g" /etc/systemd/system/$SERVICE_NAME.service

# Verify service file
if [ ! -f "/etc/systemd/system/$SERVICE_NAME.service" ]; then
    print_error "Service file not created!"
    exit 1
fi

# Configure Nginx
print_info "Configuring Nginx..."
if [ -f "deployment/nginx.conf" ]; then
    # Remove default nginx configuration if it exists
    sudo rm -f /etc/nginx/conf.d/default.conf
    
    # Copy nginx configuration
    sudo cp deployment/nginx.conf /etc/nginx/conf.d/$SERVICE_NAME.conf
    
    # Update nginx.conf with correct paths
    sudo sed -i "s|/home/ec2-user/zencrow-website|$APP_DIR|g" /etc/nginx/conf.d/$SERVICE_NAME.conf
    
    # Get EC2 public IP or use default
    PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "your-ec2-public-ip")
    sudo sed -i "s|your-domain.com|$PUBLIC_IP|g" /etc/nginx/conf.d/$SERVICE_NAME.conf
    
    # Test Nginx configuration
    if sudo nginx -t; then
        print_info "Nginx configuration is valid"
    else
        print_error "Nginx configuration has errors!"
        exit 1
    fi
else
    print_warning "deployment/nginx.conf not found, skipping Nginx configuration"
fi

# Configure firewall (if firewalld is installed)
if command -v firewall-cmd &> /dev/null; then
    print_info "Configuring firewall..."
    sudo systemctl enable firewalld 2>/dev/null || true
    sudo systemctl start firewalld 2>/dev/null || true
    sudo firewall-cmd --permanent --add-service=http 2>/dev/null || true
    sudo firewall-cmd --permanent --add-service=https 2>/dev/null || true
    sudo firewall-cmd --reload 2>/dev/null || true
else
    print_warning "firewalld not installed. Make sure your AWS Security Group allows HTTP (80) and HTTPS (443)"
fi

# Enable and start Nginx
print_info "Starting Nginx..."
sudo systemctl enable nginx
sudo systemctl restart nginx

# Reload systemd daemon
print_info "Reloading systemd daemon..."
sudo systemctl daemon-reload

# Stop existing service if running
if sudo systemctl is-active --quiet $SERVICE_NAME; then
    print_info "Stopping existing service..."
    sudo systemctl stop $SERVICE_NAME
fi

# Enable and start the application service
print_info "Starting application service..."
sudo systemctl enable $SERVICE_NAME
sudo systemctl start $SERVICE_NAME

# Wait a moment for the service to start
sleep 3

# Check service status
print_info "Checking service status..."
if sudo systemctl is-active --quiet $SERVICE_NAME; then
    print_info "$SERVICE_NAME service is running"
else
    print_error "$SERVICE_NAME service failed to start!"
    print_info "Checking service logs..."
    sudo journalctl -u $SERVICE_NAME -n 50 --no-pager
    exit 1
fi

# Check if port 8000 is listening
if netstat -tlnp 2>/dev/null | grep :8000 > /dev/null || ss -tlnp 2>/dev/null | grep :8000 > /dev/null; then
    print_info "Port 8000 is listening"
else
    print_warning "Port 8000 is not listening. Check service logs."
fi

# Get public IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "your-ec2-public-ip")

# Display deployment information
echo ""
echo "=============================================================="
print_info "Deployment completed successfully!"
echo "=============================================================="
echo ""
echo "📊 Service Status:"
sudo systemctl status $SERVICE_NAME --no-pager -l | head -10
echo ""
echo "🌐 Your application should be accessible at:"
echo "   http://$PUBLIC_IP"
echo ""
echo "📝 Useful commands:"
echo "   Check service status: sudo systemctl status $SERVICE_NAME"
echo "   View service logs: sudo journalctl -u $SERVICE_NAME -f"
echo "   Restart service: sudo systemctl restart $SERVICE_NAME"
echo "   View Nginx logs: sudo tail -f /var/log/nginx/error.log"
echo "   View Gunicorn logs: tail -f /var/log/gunicorn/error.log"
echo ""
print_warning "Make sure your AWS Security Group allows:"
echo "   - HTTP (port 80) from anywhere (0.0.0.0/0)"
echo "   - HTTPS (port 443) from anywhere (0.0.0.0/0) [if using SSL]"
echo "   - SSH (port 22) from your IP"
echo ""

