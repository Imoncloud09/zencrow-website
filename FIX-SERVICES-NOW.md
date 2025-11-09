# Fix Services - Quick Guide

## Problem
- `zencrow.service` not found
- `nginx.service` failed to start

## Quick Fix

### Step 1: Connect to EC2
```bash
ssh -i "D:\zenprod-new.pem" ec2-user@ec2-3-109-210-116.ap-south-1.compute.amazonaws.com
```

### Step 2: Run Fix Script
```bash
cd /home/ec2-user/zencrow-website
chmod +x deployment/*.sh
bash deployment/fix-services.sh
```

This script will:
- Install zencrow service file
- Fix nginx configuration
- Start both services
- Verify everything is working

## Manual Fix (If script doesn't work)

### Fix 1: Install zencrow service

```bash
cd /home/ec2-user/zencrow-website

# Copy service file
sudo cp deployment/zencrow.service /etc/systemd/system/zencrow.service

# Update paths in service file
sudo sed -i 's|/home/ec2-user/zencrow-website|/home/ec2-user/zencrow-website|g' /etc/systemd/system/zencrow.service

# Reload systemd
sudo systemctl daemon-reload

# Enable and start service
sudo systemctl enable zencrow
sudo systemctl start zencrow

# Check status
sudo systemctl status zencrow
```

### Fix 2: Fix nginx

```bash
# Test nginx configuration
sudo nginx -t

# If there are errors, check the error message
# Common issues:
# 1. Missing include directive in nginx.conf
# 2. Port 80 already in use
# 3. Invalid configuration syntax

# Check nginx error log
sudo tail -f /var/log/nginx/error.log

# If nginx.conf is missing include, add it:
sudo nano /etc/nginx/nginx.conf
# Add this line inside http { block:
#     include /etc/nginx/conf.d/*.conf;

# Remove default configuration if it conflicts
sudo rm -f /etc/nginx/conf.d/default.conf

# Test again
sudo nginx -t

# Start nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

### Fix 3: Create service file manually (if deployment/zencrow.service doesn't exist)

```bash
sudo tee /etc/systemd/system/zencrow.service > /dev/null <<'EOF'
[Unit]
Description=Zencrow Flask Application
After=network.target

[Service]
Type=exec
User=ec2-user
Group=ec2-user
WorkingDirectory=/home/ec2-user/zencrow-website
Environment="PATH=/home/ec2-user/zencrow-website/venv/bin:/usr/local/bin:/usr/bin:/bin"
Environment="FLASK_ENV=production"
ExecStart=/home/ec2-user/zencrow-website/venv/bin/gunicorn --config gunicorn.conf.py wsgi:application
ExecReload=/bin/kill -s HUP $MAINPID
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

sudo systemctl daemon-reload
sudo systemctl enable zencrow
sudo systemctl start zencrow
```

## Verify Services

```bash
# Check service status
sudo systemctl status zencrow
sudo systemctl status nginx

# Check if ports are listening
sudo netstat -tlnp | grep -E ':80|:8000'

# Test endpoints
curl http://localhost:8000/health
curl http://localhost/health

# View logs
sudo journalctl -u zencrow -f
sudo journalctl -u nginx -f
```

## Common nginx Errors

### Error: "bind() to 0.0.0.0:80 failed (98: Address already in use)"
**Solution:**
```bash
# Find what's using port 80
sudo netstat -tlnp | grep :80
# Kill the process or stop the service
sudo systemctl stop httpd  # If Apache is running
```

### Error: "nginx: [emerg] open() /etc/nginx/nginx.conf failed"
**Solution:**
```bash
# Check if nginx.conf exists
ls -la /etc/nginx/nginx.conf
# If not, reinstall nginx
sudo yum reinstall nginx
```

### Error: "nginx: [emerg] unknown directive"
**Solution:**
```bash
# Check nginx configuration syntax
sudo nginx -t
# Fix the syntax error in the configuration file
```

## After Fixing

1. **Verify services are running:**
   ```bash
   sudo systemctl status zencrow nginx
   ```

2. **Test locally:**
   ```bash
   curl http://localhost:8000/health
   curl http://localhost/health
   ```

3. **Get public IP:**
   ```bash
   curl http://169.254.169.254/latest/meta-data/public-ipv4
   ```

4. **Test from browser:**
   - Open: http://<your-ec2-ip>
   - Should see your website

5. **If still can't access:**
   - Check AWS Security Group allows HTTP (port 80)
   - Go to: AWS Console → EC2 → Instances → Security Group
   - Add rule: HTTP, Port 80, Source: 0.0.0.0/0

