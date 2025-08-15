#!/bin/bash

# Zencrow Website Update Script
# Run this script to update your application with the latest code

set -e

echo "🔄 Starting Zencrow Website Update..."

# Navigate to application directory
cd /home/ec2-user/zencrow-website

# Pull latest changes
echo "📥 Pulling latest changes from Git..."
git pull origin main

# Activate virtual environment
echo "🐍 Activating virtual environment..."
source venv/bin/activate

# Install/update dependencies
echo "📚 Updating Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# Restart the application service
echo "🚀 Restarting application service..."
sudo systemctl restart zencrow

# Check service status
echo "📊 Checking service status..."
sudo systemctl status zencrow --no-pager

echo "✅ Update completed successfully!"
echo "🌐 Your application is now running the latest version"
echo "📝 Check logs with: sudo journalctl -u zencrow -f"
