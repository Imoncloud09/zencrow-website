#!/bin/bash

# Post-deployment verification script
# Run this after deployment to verify everything is working

APP_DIR="/home/ec2-user/zencrow-website"
SERVICE_NAME="zencrow"

echo "🔍 Verifying Zencrow Deployment"
echo "================================"
echo ""

# Check if service is running
echo "1. Checking service status..."
if sudo systemctl is-active --quiet $SERVICE_NAME; then
    echo "   ✅ Service is running"
else
    echo "   ❌ Service is not running"
    echo "   Run: sudo systemctl status $SERVICE_NAME"
    exit 1
fi

# Check if port 8000 is listening
echo "2. Checking port 8000..."
if netstat -tlnp 2>/dev/null | grep :8000 > /dev/null || ss -tlnp 2>/dev/null | grep :8000 > /dev/null; then
    echo "   ✅ Port 8000 is listening"
else
    echo "   ❌ Port 8000 is not listening"
    exit 1
fi

# Check if Nginx is running
echo "3. Checking Nginx..."
if sudo systemctl is-active --quiet nginx; then
    echo "   ✅ Nginx is running"
else
    echo "   ❌ Nginx is not running"
    exit 1
fi

# Check if port 80 is listening
echo "4. Checking port 80..."
if netstat -tlnp 2>/dev/null | grep :80 > /dev/null || ss -tlnp 2>/dev/null | grep :80 > /dev/null; then
    echo "   ✅ Port 80 is listening"
else
    echo "   ❌ Port 80 is not listening"
    exit 1
fi

# Test health endpoint
echo "5. Testing health endpoint..."
HEALTH_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health)
if [ "$HEALTH_RESPONSE" == "200" ]; then
    echo "   ✅ Health endpoint responding (HTTP $HEALTH_RESPONSE)"
    curl -s http://localhost:8000/health | python3 -m json.tool 2>/dev/null || curl -s http://localhost:8000/health
else
    echo "   ❌ Health endpoint not responding (HTTP $HEALTH_RESPONSE)"
    exit 1
fi

# Test main page through Nginx
echo "6. Testing main page through Nginx..."
MAIN_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/)
if [ "$MAIN_RESPONSE" == "200" ]; then
    echo "   ✅ Main page accessible (HTTP $MAIN_RESPONSE)"
else
    echo "   ⚠️  Main page returned HTTP $MAIN_RESPONSE (may be expected if no domain configured)"
fi

# Get public IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "Not available")

echo ""
echo "=========================================="
echo "✅ Deployment Verification Complete!"
echo "=========================================="
echo ""
echo "🌐 Your application is accessible at:"
echo "   http://$PUBLIC_IP"
echo ""
echo "📊 Service Status:"
sudo systemctl status $SERVICE_NAME --no-pager -l | head -5
echo ""
echo "📝 Useful commands:"
echo "   View logs: sudo journalctl -u $SERVICE_NAME -f"
echo "   Restart: sudo systemctl restart $SERVICE_NAME"
echo "   Check status: sudo systemctl status $SERVICE_NAME"
echo ""

