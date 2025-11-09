#!/bin/bash

# Fix Connection Refused Error
# Run this on your EC2 instance to diagnose and fix connection issues

APP_DIR="/home/ec2-user/zencrow-website"
SERVICE_NAME="zencrow"

echo "🔧 Fixing Connection Refused Error"
echo "==================================="
echo ""

# Check if service is running
echo "1. Checking zencrow service status..."
if sudo systemctl is-active --quiet $SERVICE_NAME; then
    echo "   ✅ Service is running"
else
    echo "   ❌ Service is not running"
    echo "   Starting service..."
    sudo systemctl start $SERVICE_NAME
    sleep 2
    if sudo systemctl is-active --quiet $SERVICE_NAME; then
        echo "   ✅ Service started successfully"
    else
        echo "   ❌ Service failed to start"
        echo "   Checking logs..."
        sudo journalctl -u $SERVICE_NAME -n 20 --no-pager
        exit 1
    fi
fi

# Check if port 8000 is listening
echo ""
echo "2. Checking if port 8000 is listening..."
if netstat -tlnp 2>/dev/null | grep :8000 > /dev/null || ss -tlnp 2>/dev/null | grep :8000 > /dev/null; then
    echo "   ✅ Port 8000 is listening"
    netstat -tlnp 2>/dev/null | grep :8000 || ss -tlnp 2>/dev/null | grep :8000
else
    echo "   ❌ Port 8000 is NOT listening"
    echo "   Service may not be running properly"
    echo "   Checking service logs..."
    sudo journalctl -u $SERVICE_NAME -n 30 --no-pager
    exit 1
fi

# Check if Nginx is running
echo ""
echo "3. Checking Nginx status..."
if sudo systemctl is-active --quiet nginx; then
    echo "   ✅ Nginx is running"
else
    echo "   ❌ Nginx is not running"
    echo "   Starting Nginx..."
    sudo systemctl start nginx
    sleep 2
    if sudo systemctl is-active --quiet nginx; then
        echo "   ✅ Nginx started successfully"
    else
        echo "   ❌ Nginx failed to start"
        echo "   Checking Nginx configuration..."
        sudo nginx -t
        exit 1
    fi
fi

# Check if port 80 is listening
echo ""
echo "4. Checking if port 80 is listening..."
if netstat -tlnp 2>/dev/null | grep :80 > /dev/null || ss -tlnp 2>/dev/null | grep :80 > /dev/null; then
    echo "   ✅ Port 80 is listening"
    netstat -tlnp 2>/dev/null | grep :80 || ss -tlnp 2>/dev/null | grep :80
else
    echo "   ❌ Port 80 is NOT listening"
    echo "   Nginx may not be running properly"
    sudo systemctl status nginx --no-pager -l | head -20
    exit 1
fi

# Check Nginx configuration
echo ""
echo "5. Checking Nginx configuration..."
if sudo nginx -t 2>&1; then
    echo "   ✅ Nginx configuration is valid"
else
    echo "   ❌ Nginx configuration has errors"
    echo "   Please fix the configuration errors above"
    exit 1
fi

# Check if Nginx can connect to Gunicorn
echo ""
echo "6. Testing connection from Nginx to Gunicorn..."
if curl -s http://localhost:8000/health > /dev/null; then
    echo "   ✅ Gunicorn is responding on port 8000"
    curl -s http://localhost:8000/health | python3 -m json.tool 2>/dev/null || curl -s http://localhost:8000/health
else
    echo "   ❌ Gunicorn is not responding on port 8000"
    echo "   Checking Gunicorn logs..."
    tail -20 /var/log/gunicorn/error.log 2>/dev/null || echo "   Log file not found"
    exit 1
fi

# Check if Nginx can serve the application
echo ""
echo "7. Testing Nginx proxy..."
if curl -s http://localhost/health > /dev/null; then
    echo "   ✅ Nginx is proxying correctly"
    curl -s http://localhost/health | python3 -m json.tool 2>/dev/null || curl -s http://localhost/health
else
    echo "   ❌ Nginx is not proxying correctly"
    echo "   Checking Nginx error log..."
    sudo tail -20 /var/log/nginx/error.log
    exit 1
fi

# Check firewall (if firewalld is installed)
echo ""
echo "8. Checking firewall..."
if command -v firewall-cmd &> /dev/null; then
    if sudo systemctl is-active --quiet firewalld; then
        echo "   ⚠️  Firewalld is running"
        echo "   Checking firewall rules..."
        sudo firewall-cmd --list-all
        echo ""
        echo "   Adding HTTP service if not present..."
        sudo firewall-cmd --permanent --add-service=http 2>/dev/null
        sudo firewall-cmd --permanent --add-service=https 2>/dev/null
        sudo firewall-cmd --reload 2>/dev/null
        echo "   ✅ Firewall configured"
    else
        echo "   ✅ Firewalld is not running (AWS Security Groups handle firewall)"
    fi
else
    echo "   ✅ Firewalld not installed (AWS Security Groups handle firewall)"
fi

# Get public IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "Not available")

echo ""
echo "=========================================="
echo "✅ Connection Issues Fixed!"
echo "=========================================="
echo ""
echo "🌐 Your application should be accessible at:"
echo "   http://$PUBLIC_IP"
echo ""
echo "⚠️  IMPORTANT: If you still can't connect, check your AWS Security Group:"
echo "   1. Go to AWS Console → EC2 → Security Groups"
echo "   2. Select your EC2 instance's security group"
echo "   3. Ensure there's an Inbound rule for:"
echo "      - Type: HTTP"
echo "      - Protocol: TCP"
echo "      - Port: 80"
echo "      - Source: 0.0.0.0/0 (or your IP)"
echo ""
echo "📊 Service Status:"
sudo systemctl status $SERVICE_NAME --no-pager -l | head -5
sudo systemctl status nginx --no-pager -l | head -5
echo ""
echo "📝 To check logs:"
echo "   sudo journalctl -u $SERVICE_NAME -f"
echo "   sudo tail -f /var/log/nginx/error.log"
echo ""

