# Zencrow Website - AWS EC2 Deployment Guide

This guide will help you deploy the Zencrow website on Amazon Linux EC2 instance.

## Prerequisites

1. **AWS EC2 Instance** running Amazon Linux 2 or Amazon Linux 2023
2. **SSH Access** with PEM key file
3. **Security Group** configured to allow:
   - SSH (port 22) from your IP
   - HTTP (port 80) from anywhere (0.0.0.0/0)
   - HTTPS (port 443) from anywhere (0.0.0.0/0) [optional]
4. **Domain Name** (optional but recommended)

## Quick Deployment (Automated)

### Option 1: Transfer and Deploy from Local Machine

1. **Update the transfer script** with your EC2 details:
   ```bash
   # Edit deployment/transfer-and-deploy.sh
   PEM_KEY="zenprod-new.pem"
   EC2_HOST="ec2-3-109-210-116.ap-south-1.compute.amazonaws.com"
   ```

2. **Run the transfer and deploy script**:
   ```bash
   # On Windows (Git Bash or WSL)
   bash deployment/transfer-and-deploy.sh
   
   # On Linux/Mac
   chmod +x deployment/transfer-and-deploy.sh
   ./deployment/transfer-and-deploy.sh
   ```

### Option 2: Manual Deployment on EC2

1. **Connect to your EC2 instance**:
   ```bash
   ssh -i "zenprod-new.pem" ec2-user@ec2-3-109-210-116.ap-south-1.compute.amazonaws.com
   ```

2. **Transfer your code** to EC2:
   ```bash
   # Option A: Using SCP (from local machine)
   scp -i "zenprod-new.pem" -r . ec2-user@ec2-3-109-210-116.ap-south-1.compute.amazonaws.com:/home/ec2-user/zencrow-website
   
   # Option B: Using Git (on EC2)
   cd /home/ec2-user
   git clone https://github.com/yourusername/zencrow-website.git
   cd zencrow-website
   ```

3. **Run the deployment script**:
   ```bash
   cd /home/ec2-user/zencrow-website
   chmod +x deployment/deploy-aws.sh
   bash deployment/deploy-aws.sh
   ```

## Step-by-Step Manual Deployment

If you prefer to deploy manually, follow these steps:

### 1. Connect to EC2 Instance

```bash
ssh -i "zenprod-new.pem" ec2-user@ec2-3-109-210-116.ap-south-1.compute.amazonaws.com
```

### 2. Update System Packages

```bash
sudo yum update -y  # Amazon Linux 2
# or
sudo dnf update -y  # Amazon Linux 2023
```

### 3. Install Required Packages

```bash
# Amazon Linux 2
sudo yum install -y python3 python3-pip python3-devel nginx git gcc
sudo yum groupinstall -y "Development Tools"

# Amazon Linux 2023
sudo dnf install -y python3 python3-pip python3-devel nginx git gcc
sudo dnf groupinstall -y "Development Tools"
```

### 4. Transfer Code to EC2

```bash
# Create application directory
mkdir -p /home/ec2-user/zencrow-website
cd /home/ec2-user/zencrow-website

# Option A: Clone from Git
git clone https://github.com/yourusername/zencrow-website.git .

# Option B: Transfer using SCP (from local machine)
# scp -i "zenprod-new.pem" -r . ec2-user@your-ec2-host:/home/ec2-user/zencrow-website
```

### 5. Set Up Python Virtual Environment

```bash
cd /home/ec2-user/zencrow-website
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

### 6. Test the Application

```bash
python deployment/test-app.py
```

### 7. Configure Environment Variables

```bash
# Create .env file
cat > .env << EOF
FLASK_ENV=production
SECRET_KEY=$(python3 -c 'import secrets; print(secrets.token_hex(32))')
DATABASE_URL=sqlite:///instance/zencrow.db
MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587
MAIL_USE_TLS=True
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=your-app-password
EOF

# Edit with your email credentials if needed
nano .env
```

### 8. Create Log Directories

```bash
sudo mkdir -p /var/log/gunicorn
sudo chown ec2-user:ec2-user /var/log/gunicorn
```

### 9. Configure Gunicorn

```bash
# Copy gunicorn configuration
cp deployment/gunicorn.conf.py .
```

### 10. Configure Systemd Service

```bash
# Copy service file
sudo cp deployment/zencrow.service /etc/systemd/system/

# Update paths in service file (if needed)
sudo nano /etc/systemd/system/zencrow.service

# Reload systemd
sudo systemctl daemon-reload
sudo systemctl enable zencrow
sudo systemctl start zencrow
```

### 11. Configure Nginx

```bash
# Copy nginx configuration
sudo cp deployment/nginx.conf /etc/nginx/conf.d/zencrow.conf

# Update server_name in nginx.conf
sudo nano /etc/nginx/conf.d/zencrow.conf

# Test nginx configuration
sudo nginx -t

# Start nginx
sudo systemctl enable nginx
sudo systemctl start nginx
```

### 12. Configure Firewall (if using firewalld)

```bash
sudo systemctl enable firewalld
sudo systemctl start firewalld
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

**Note**: On AWS EC2, security groups handle firewall rules. Make sure your security group allows HTTP (80) and HTTPS (443).

### 13. Verify Deployment

```bash
# Check service status
sudo systemctl status zencrow
sudo systemctl status nginx

# Check if port 8000 is listening
sudo netstat -tlnp | grep :8000

# Check application logs
sudo journalctl -u zencrow -f
```

## Troubleshooting

### Service Won't Start

1. **Check service logs**:
   ```bash
   sudo journalctl -u zencrow -n 50
   ```

2. **Check Gunicorn logs**:
   ```bash
   tail -f /var/log/gunicorn/error.log
   ```

3. **Test application manually**:
   ```bash
   cd /home/ec2-user/zencrow-website
   source venv/bin/activate
   python deployment/test-app.py
   ```

### Nginx Errors

1. **Check nginx configuration**:
   ```bash
   sudo nginx -t
   ```

2. **Check nginx logs**:
   ```bash
   sudo tail -f /var/log/nginx/error.log
   ```

3. **Verify nginx is running**:
   ```bash
   sudo systemctl status nginx
   ```

### Permission Issues

```bash
# Fix file permissions
sudo chown -R ec2-user:ec2-user /home/ec2-user/zencrow-website
sudo chown -R ec2-user:ec2-user /var/log/gunicorn
```

### Port Already in Use

```bash
# Check what's using port 8000
sudo netstat -tlnp | grep :8000

# Kill the process if needed
sudo kill -9 <PID>
```

### Application Not Accessible

1. **Check AWS Security Group**:
   - Ensure HTTP (port 80) is open from 0.0.0.0/0
   - Ensure HTTPS (port 443) is open if using SSL

2. **Check if service is running**:
   ```bash
   sudo systemctl status zencrow
   sudo systemctl status nginx
   ```

3. **Check if ports are listening**:
   ```bash
   sudo netstat -tlnp | grep :80
   sudo netstat -tlnp | grep :8000
   ```

### Database Issues

```bash
# Create instance directory
mkdir -p /home/ec2-user/zencrow-website/instance
chmod 755 /home/ec2-user/zencrow-website/instance

# Initialize database (if needed)
cd /home/ec2-user/zencrow-website
source venv/bin/activate
python -c "from app import create_app; app = create_app(); from app.models import *; db.create_all()"
```

## Useful Commands

### Service Management

```bash
# Start service
sudo systemctl start zencrow

# Stop service
sudo systemctl stop zencrow

# Restart service
sudo systemctl restart zencrow

# Check status
sudo systemctl status zencrow

# View logs
sudo journalctl -u zencrow -f
```

### Application Updates

```bash
# Update code
cd /home/ec2-user/zencrow-website
git pull origin main

# Update dependencies
source venv/bin/activate
pip install -r requirements.txt

# Restart service
sudo systemctl restart zencrow
```

### Monitoring

```bash
# View application logs
sudo journalctl -u zencrow -f

# View Gunicorn logs
tail -f /var/log/gunicorn/error.log
tail -f /var/log/gunicorn/access.log

# View Nginx logs
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log

# Check system resources
df -h  # Disk space
free -h  # Memory
top  # CPU and processes
```

## Security Considerations

1. **Update .env file** with strong SECRET_KEY
2. **Configure email credentials** properly
3. **Use HTTPS** in production (configure SSL certificate)
4. **Keep system updated**: `sudo yum update -y`
5. **Configure AWS Security Groups** properly
6. **Regular backups** of database and code
7. **Monitor logs** for suspicious activity

## SSL/HTTPS Setup (Optional)

To enable HTTPS:

1. **Install Certbot**:
   ```bash
   sudo yum install -y certbot python3-certbot-nginx
   ```

2. **Obtain SSL certificate**:
   ```bash
   sudo certbot --nginx -d your-domain.com -d www.your-domain.com
   ```

3. **Auto-renewal**:
   ```bash
   sudo certbot renew --dry-run
   ```

## Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review service logs: `sudo journalctl -u zencrow -n 100`
3. Verify configuration files
4. Test individual components
5. Check AWS Security Group settings
6. Verify file permissions

## Next Steps

After successful deployment:

1. Configure your domain name to point to EC2 IP
2. Set up SSL certificate for HTTPS
3. Configure monitoring and alerts
4. Set up automated backups
5. Configure log rotation
6. Set up CI/CD pipeline for automated deployments

