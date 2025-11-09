#!/bin/bash

# Quick check script - Run this on EC2 to see what's wrong

echo "🔍 Quick Connection Check"
echo "========================"
echo ""

# Check if we're on EC2
if ! curl -s http://169.254.169.254/latest/meta-data/instance-id > /dev/null 2>&1; then
    echo "⚠️  This doesn't appear to be an EC2 instance"
    echo ""
fi

# Get public IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "Not available")
echo "📍 Public IP: $PUBLIC_IP"
echo ""

# Check if application directory exists
APP_DIR="/home/ec2-user/zencrow-website"
if [ -d "$APP_DIR" ]; then
    echo "✅ Application directory exists: $APP_DIR"
    cd $APP_DIR
else
    echo "❌ Application directory NOT found: $APP_DIR"
    echo "   You need to deploy the application first!"
    echo "   Run: bash deployment/deploy-aws.sh"
    exit 1
fi

# Check zencrow service
echo ""
echo "🚀 Checking Zencrow Service:"
if sudo systemctl is-active --quiet zencrow; then
    echo "   ✅ Service is RUNNING"
else
    echo "   ❌ Service is NOT running"
    echo "   Trying to start..."
    sudo systemctl start zencrow 2>&1
    sleep 2
    if sudo systemctl is-active --quiet zencrow; then
        echo "   ✅ Service started successfully"
    else
        echo "   ❌ Service failed to start"
        echo "   Checking logs..."
        sudo journalctl -u zencrow -n 10 --no-pager
    fi
fi

# Check nginx service
echo ""
echo "🌐 Checking Nginx Service:"
if sudo systemctl is-active --quiet nginx; then
    echo "   ✅ Nginx is RUNNING"
else
    echo "   ❌ Nginx is NOT running"
    echo "   Trying to start..."
    sudo systemctl start nginx 2>&1
    sleep 2
    if sudo systemctl is-active --quiet nginx; then
        echo "   ✅ Nginx started successfully"
    else
        echo "   ❌ Nginx failed to start"
        echo "   Checking configuration..."
        sudo nginx -t
    fi
fi

# Check port 8000
echo ""
echo "🔌 Checking Port 8000 (Gunicorn):"
if netstat -tlnp 2>/dev/null | grep :8000 > /dev/null || ss -tlnp 2>/dev/null | grep :8000 > /dev/null; then
    echo "   ✅ Port 8000 is LISTENING"
    netstat -tlnp 2>/dev/null | grep :8000 || ss -tlnp 2>/dev/null | grep :8000
else
    echo "   ❌ Port 8000 is NOT listening"
    echo "   Gunicorn may not be running"
fi

# Check port 80
echo ""
echo "🔌 Checking Port 80 (HTTP):"
if netstat -tlnp 2>/dev/null | grep :80 > /dev/null || ss -tlnp 2>/dev/null | grep :80 > /dev/null; then
    echo "   ✅ Port 80 is LISTENING"
    netstat -tlnp 2>/dev/null | grep :80 || ss -tlnp 2>/dev/null | grep :80
else
    echo "   ❌ Port 80 is NOT listening"
    echo "   Nginx may not be running"
fi

# Test local connection
echo ""
echo "🧪 Testing Local Connection:"
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo "   ✅ Gunicorn is responding on port 8000"
    curl -s http://localhost:8000/health
else
    echo "   ❌ Gunicorn is NOT responding on port 8000"
fi

# Test through nginx
echo ""
echo "🧪 Testing Through Nginx:"
if curl -s http://localhost/health > /dev/null 2>&1; then
    echo "   ✅ Nginx proxy is working"
    curl -s http://localhost/health
else
    echo "   ❌ Nginx proxy is NOT working"
    echo "   Checking Nginx error log..."
    sudo tail -5 /var/log/nginx/error.log 2>/dev/null || echo "   (No error log found)"
fi

# Summary
echo ""
echo "=========================================="
echo "📊 Summary"
echo "=========================================="
echo ""
echo "If services are running but you still can't connect from browser:"
echo "  ⚠️  Check AWS Security Group allows HTTP (port 80) from 0.0.0.0/0"
echo ""
echo "If services are NOT running:"
echo "  💡 Deploy the application: bash deployment/deploy-aws.sh"
echo "  💡 Or start services: sudo systemctl start zencrow nginx"
echo ""
echo "Your application URL: http://$PUBLIC_IP"
echo ""

