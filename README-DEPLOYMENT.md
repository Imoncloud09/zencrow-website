# Zencrow Website - AWS EC2 Deployment

This document provides instructions for deploying the Zencrow website on Amazon Linux EC2.

## Quick Deployment

### For Windows Users

1. **Open PowerShell** in the project directory
2. **Run the deployment script**:
   ```powershell
   .\deployment\transfer-to-ec2.ps1
   ```

### For Linux/Mac Users

1. **Make scripts executable**:
   ```bash
   chmod +x deployment/*.sh
   ```

2. **Run the deployment script**:
   ```bash
   ./deployment/transfer-and-deploy.sh
   ```

### Manual Deployment on EC2

1. **Connect to EC2**:
   ```bash
   ssh -i "zenprod-new.pem" ec2-user@ec2-3-109-210-116.ap-south-1.compute.amazonaws.com
   ```

2. **Transfer code** (from local machine):
   ```bash
   scp -i "zenprod-new.pem" -r . ec2-user@ec2-3-109-210-116.ap-south-1.compute.amazonaws.com:/home/ec2-user/zencrow-website
   ```

3. **Run deployment** (on EC2):
   ```bash
   cd /home/ec2-user/zencrow-website
   chmod +x deployment/*.sh
   bash deployment/deploy-aws.sh
   ```

## Deployment Scripts

### Main Scripts

- **`deploy-aws.sh`** - Main deployment script for Amazon Linux EC2
- **`quick-deploy.sh`** - Quick deployment if code is already on EC2
- **`transfer-and-deploy.sh`** - Transfer code and deploy (Linux/Mac)
- **`transfer-to-ec2.ps1`** - Transfer code and deploy (Windows PowerShell)

### Diagnostic Scripts

- **`diagnose.sh`** - Comprehensive diagnostic tool
- **`troubleshoot.sh`** - Troubleshooting helper
- **`verify-deployment.sh`** - Post-deployment verification

### Utility Scripts

- **`setup-python.sh`** - Python environment setup
- **`test-app.py`** - Application test script
- **`update.sh`** - Update application code

## Configuration Files

- **`zencrow.service`** - Systemd service file
- **`gunicorn.conf.py`** - Gunicorn configuration
- **`nginx.conf`** - Nginx configuration

## Prerequisites

1. **AWS EC2 Instance** running Amazon Linux 2 or 2023
2. **SSH Access** with PEM key file
3. **Security Group** configured to allow:
   - SSH (port 22) from your IP
   - HTTP (port 80) from anywhere (0.0.0.0/0)
   - HTTPS (port 443) from anywhere (0.0.0.0/0) [optional]

## Deployment Process

The deployment script will:

1. Update system packages
2. Install Python, Nginx, and dependencies
3. Set up Python virtual environment
4. Install Python dependencies
5. Configure Gunicorn
6. Configure Nginx
7. Set up systemd service
8. Start services
9. Verify deployment

## Troubleshooting

### Service Won't Start

```bash
# Check service logs
sudo journalctl -u zencrow -n 50

# Check service status
sudo systemctl status zencrow

# Restart service
sudo systemctl restart zencrow
```

### Run Diagnostics

```bash
cd /home/ec2-user/zencrow-website
bash deployment/diagnose.sh
```

### Common Issues

1. **Permission Errors**:
   ```bash
   sudo chown -R ec2-user:ec2-user /home/ec2-user/zencrow-website
   sudo chown -R ec2-user:ec2-user /var/log/gunicorn
   ```

2. **Python/Venv Issues**:
   ```bash
   cd /home/ec2-user/zencrow-website
   rm -rf venv
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```

3. **Port Not Accessible**:
   - Check AWS Security Group allows HTTP (80)
   - Check if service is running: `sudo systemctl status zencrow`
   - Check if port is listening: `sudo netstat -tlnp | grep :8000`

4. **Nginx Errors**:
   ```bash
   sudo nginx -t
   sudo systemctl restart nginx
   sudo tail -f /var/log/nginx/error.log
   ```

## Verification

After deployment, verify the installation:

```bash
# Run verification script
bash deployment/verify-deployment.sh

# Check service status
sudo systemctl status zencrow

# Test health endpoint
curl http://localhost:8000/health

# Get public IP
curl http://169.254.169.254/latest/meta-data/public-ipv4
```

## Accessing Your Application

Your application should be accessible at:
```
http://<your-ec2-public-ip>
```

To get your EC2 public IP:
```bash
curl http://169.254.169.254/latest/meta-data/public-ipv4
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
cd /home/ec2-user/zencrow-website
git pull origin main  # If using Git
source venv/bin/activate
pip install -r requirements.txt
sudo systemctl restart zencrow
```

### Logs

```bash
# Service logs
sudo journalctl -u zencrow -f

# Gunicorn logs
tail -f /var/log/gunicorn/error.log
tail -f /var/log/gunicorn/access.log

# Nginx logs
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log
```

## Configuration

### Environment Variables

Edit `.env` file to configure:
- `SECRET_KEY` - Flask secret key
- `MAIL_USERNAME` - Email username
- `MAIL_PASSWORD` - Email password
- `DATABASE_URL` - Database connection string

### Gunicorn Configuration

Edit `gunicorn.conf.py` to adjust:
- Number of workers
- Timeout settings
- Log levels

### Nginx Configuration

Edit `/etc/nginx/conf.d/zencrow.conf` to:
- Configure domain name
- Set up SSL/HTTPS
- Adjust proxy settings

## Security Considerations

1. **Update .env file** with strong SECRET_KEY
2. **Configure email credentials** properly
3. **Use HTTPS** in production (configure SSL certificate)
4. **Keep system updated**: `sudo yum update -y`
5. **Configure AWS Security Groups** properly
6. **Regular backups** of database and code
7. **Monitor logs** for suspicious activity

## Next Steps

After successful deployment:

1. Configure your domain name to point to EC2 IP
2. Set up SSL certificate for HTTPS
3. Configure monitoring and alerts
4. Set up automated backups
5. Configure log rotation
6. Set up CI/CD pipeline for automated deployments

## Support

For detailed deployment instructions, see:
- [DEPLOYMENT_GUIDE.md](./deployment/DEPLOYMENT_GUIDE.md)
- [QUICKSTART.md](./deployment/QUICKSTART.md)

For troubleshooting, run:
```bash
bash deployment/diagnose.sh
```

