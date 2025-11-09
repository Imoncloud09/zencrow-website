#!/bin/bash

# Zencrow Website Update Script
# Run this script to update your application after code changes

set -e

APP_DIR="/home/ec2-user/zencrow-website"

echo "🔄 Updating Zencrow Website..."
echo "==============================="

# Navigate to application directory
cd $APP_DIR

# Update code (if using Git)
if [ -d ".git" ]; then
    echo "📥 Pulling latest changes from Git..."
    git pull origin main || echo "⚠️  Git pull failed, continuing with existing code..."
else
    echo "ℹ️  Not a Git repository, skipping Git pull"
    echo "💡 Make sure you've uploaded the latest code"
fi

# Activate virtual environment
echo "🐍 Activating virtual environment..."
source venv/bin/activate

# Update dependencies
echo "📚 Updating Python dependencies..."
pip install --upgrade pip --quiet
pip install -r requirements.txt --quiet

# Test application
echo "🧪 Testing application..."
if python -c "from app import create_app; app = create_app()" 2>/dev/null; then
    echo "✅ Application test passed"
else
    echo "❌ Application test failed"
    echo "Error:"
    python -c "from app import create_app; app = create_app()" 2>&1 | head -5
    exit 1
fi

# Restart the application service
echo "🚀 Restarting application service..."
sudo systemctl restart zencrow

# Wait a moment
sleep 2

# Check service status
if sudo systemctl is-active --quiet zencrow; then
    echo "✅ Service restarted successfully"
else
    echo "❌ Service failed to restart"
    echo "Logs:"
    sudo journalctl -u zencrow -n 10 --no-pager
    exit 1
fi

echo ""
echo "✅ Update completed successfully!"
echo "🌐 Your application is now running the latest version"
echo "📝 View logs: sudo journalctl -u zencrow -f"
echo ""
