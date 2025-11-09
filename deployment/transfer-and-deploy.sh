#!/bin/bash

# Script to transfer code to EC2 and deploy
# Run this from your local machine (Windows/Linux/Mac)
# Make sure you have the PEM key file and SSH access

set -e

# Configuration
PEM_KEY="zenprod-new.pem"
EC2_USER="ec2-user"
EC2_HOST="ec2-3-109-210-116.ap-south-1.compute.amazonaws.com"
APP_DIR="/home/ec2-user/zencrow-website"
LOCAL_DIR="."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if PEM key exists
if [ ! -f "$PEM_KEY" ]; then
    print_error "PEM key file not found: $PEM_KEY"
    print_info "Please update PEM_KEY variable in this script with the correct path"
    exit 1
fi

# Set correct permissions for PEM key
chmod 400 "$PEM_KEY"

# Test SSH connection
print_info "Testing SSH connection..."
ssh -i "$PEM_KEY" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_HOST" "echo 'SSH connection successful'" || {
    print_error "SSH connection failed!"
    print_info "Please check:"
    print_info "  1. PEM key path is correct"
    print_info "  2. EC2 instance is running"
    print_info "  3. Security group allows SSH from your IP"
    exit 1
}

# Create .gitignore if it doesn't exist to exclude unnecessary files
print_info "Preparing files for transfer..."

# Create temporary exclude file
EXCLUDE_FILE=$(mktemp)
cat > "$EXCLUDE_FILE" << EOF
__pycache__/
*.pyc
*.pyo
*.pyd
.Python
venv/
env/
ENV/
.venv
instance/
*.db
*.sqlite
*.sqlite3
.DS_Store
.vscode/
.idea/
*.log
.env
*.pem
*.key
.git/
EOF

# Transfer code to EC2
print_info "Transferring code to EC2..."
rsync -avz -e "ssh -i $PEM_KEY" \
    --exclude-from="$EXCLUDE_FILE" \
    --exclude='venv' \
    --exclude='instance' \
    --exclude='*.db' \
    --exclude='.git' \
    "$LOCAL_DIR/" "$EC2_USER@$EC2_HOST:$APP_DIR/" || {
    print_warning "rsync not available, using SCP instead..."
    # Alternative: use SCP
    ssh -i "$PEM_KEY" "$EC2_USER@$EC2_HOST" "mkdir -p $APP_DIR"
    scp -i "$PEM_KEY" -r \
        --exclude='venv' \
        --exclude='instance' \
        --exclude='*.db' \
        "$LOCAL_DIR"/* "$EC2_USER@$EC2_HOST:$APP_DIR/"
}

# Clean up
rm -f "$EXCLUDE_FILE"

# Make deployment script executable
print_info "Setting up deployment script..."
ssh -i "$PEM_KEY" "$EC2_USER@$EC2_HOST" "chmod +x $APP_DIR/deployment/*.sh"

# Run deployment script
print_info "Running deployment script on EC2..."
ssh -i "$PEM_KEY" "$EC2_USER@$EC2_HOST" "cd $APP_DIR && bash deployment/deploy-aws.sh"

print_info "Deployment completed!"
print_info "Your application should be accessible at: http://$(ssh -i "$PEM_KEY" $EC2_USER@$EC2_HOST 'curl -s http://169.254.169.254/latest/meta-data/public-ipv4')"

