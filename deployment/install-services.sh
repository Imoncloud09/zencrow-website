#!/bin/bash

# Quick service installation script
# Run this on EC2 to install and start services

APP_DIR="/home/ec2-user/zencrow-website"

echo "🔧 Installing and Starting Services"
echo "===================================="

# Navigate to app directory
cd $APP_DIR 2>/dev/null || {
    echo "❌ Application directory not found: $APP_DIR"
    echo "💡 Please deploy the application first"
    exit 1
}

# Create service file if it doesn't exist
echo "📋 Creating zencrow service..."
sudo tee /etc/systemd/system/zencrow.service > /dev/null <<EOF
[Unit]
Description=Zencrow Flask Application
After=network.target

[Service]
Type=exec
User=ec2-user
Group=ec2-user
WorkingDirectory=$APP_DIR
Environment="PATH=$APP_DIR/venv/bin:/usr/local/bin:/usr/bin:/bin"
Environment="FLASK_ENV=production"
ExecStart=$APP_DIR/venv/bin/gunicorn --config gunicorn.conf.py wsgi:application
ExecReload=/bin/kill -s HUP \$MAINPID
KillMode=mixed
TimeoutStopSec=5
PrivateTmp=true
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal
SyslogIdentifier=zencrow

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
sudo systemctl daemon-reload

# Enable and start zencrow
sudo systemctl enable zencrow
sudo systemctl start zencrow

# Wait a moment
sleep 2

# Check zencrow status
if sudo systemctl is-active --quiet zencrow; then
    echo "✅ zencrow service started"
else
    echo "❌ zencrow service failed to start"
    echo "Logs:"
    sudo journalctl -u zencrow -n 10 --no-pager
fi

# Fix nginx
echo ""
echo "🌐 Fixing nginx..."

# Remove default config
sudo rm -f /etc/nginx/conf.d/default.conf

# Create nginx config
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "_")
sudo tee /etc/nginx/conf.d/zencrow.conf > /dev/null <<EOF
server {
    listen 80;
    server_name $PUBLIC_IP _;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /static {
        alias $APP_DIR/app/static;
    }

    location /public {
        alias $APP_DIR/public;
    }
}
EOF

# Test nginx config
if sudo nginx -t 2>&1; then
    echo "✅ Nginx configuration is valid"
    sudo systemctl enable nginx
    sudo systemctl start nginx
    sleep 2
    if sudo systemctl is-active --quiet nginx; then
        echo "✅ nginx service started"
    else
        echo "❌ nginx service failed to start"
        sudo journalctl -u nginx -n 10 --no-pager
    fi
else
    echo "❌ Nginx configuration error:"
    sudo nginx -t
fi

# Summary
echo ""
echo "=========================================="
echo "Service Status:"
echo "=========================================="
sudo systemctl status zencrow --no-pager -l | head -3
echo ""
sudo systemctl status nginx --no-pager -l | head -3
echo ""

