# Zencrow Website Deployment

This directory contains all the files needed to deploy the Zencrow website on Amazon Linux EC2.

## Files Overview

### Essential Files

- **`deploy-after-upload.sh`** - Main deployment script (run after uploading files to EC2)
- **`gunicorn.conf.py`** - Gunicorn configuration for production
- **`nginx.conf`** - Nginx reverse proxy configuration
- **`zencrow.service`** - Systemd service file for the application
- **`test-app.py`** - Script to test if the application works correctly

### Utility Scripts

- **`update.sh`** - Update application code and restart service
- **`transfer-to-ec2.ps1`** - PowerShell script to transfer code to EC2 (Windows)

### Documentation

- **`DEPLOYMENT_GUIDE.md`** - Comprehensive deployment guide
- **`README.md`** - This file

## Quick Start

### Option 1: Deploy After Uploading Files

1. **Upload your files to EC2** (using SCP, Git, or other method)

2. **Connect to EC2:**
   ```bash
   ssh -i "your-key.pem" ec2-user@your-ec2-host
   ```

3. **Run deployment script:**
   ```bash
   cd /home/ec2-user/zencrow-website
   chmod +x deployment/*.sh
   bash deployment/deploy-after-upload.sh
   ```

### Option 2: Transfer and Deploy from Windows

1. **Run PowerShell script from your local machine:**
   ```powershell
   .\deployment\transfer-to-ec2.ps1
   ```

   This will:
   - Transfer your code to EC2
   - Run the deployment script automatically

## Deployment Script

The `deploy-after-upload.sh` script will:

1. ✅ Install system dependencies (Python, Nginx, etc.)
2. ✅ Set up Python virtual environment
3. ✅ Install Python dependencies
4. ✅ Test the application
5. ✅ Configure Gunicorn
6. ✅ Set up systemd service
7. ✅ Configure Nginx
8. ✅ Start services
9. ✅ Verify deployment

## Updating Application

To update your application after deployment:

```bash
# On EC2
cd /home/ec2-user/zencrow-website
bash deployment/update.sh
```

Or manually:

```bash
# Update code (git pull, or upload new files)
cd /home/ec2-user/zencrow-website
source venv/bin/activate
pip install -r requirements.txt
sudo systemctl restart zencrow
```

## Testing

Test your application:

```bash
# On EC2
cd /home/ec2-user/zencrow-website
python deployment/test-app.py
```

## Configuration Files

### Gunicorn (`gunicorn.conf.py`)
- Configures worker processes
- Sets up logging
- Configures timeouts and connection settings

### Nginx (`nginx.conf`)
- Reverse proxy configuration
- Static file serving
- SSL/HTTPS support (if configured)

### Systemd Service (`zencrow.service`)
- Service configuration
- Auto-restart on failure
- Logging configuration

## Troubleshooting

### Service Won't Start

```bash
# Check service status
sudo systemctl status zencrow

# Check logs
sudo journalctl -u zencrow -n 50

# Restart service
sudo systemctl restart zencrow
```

### Nginx Issues

```bash
# Test nginx configuration
sudo nginx -t

# Check nginx logs
sudo tail -f /var/log/nginx/error.log

# Restart nginx
sudo systemctl restart nginx
```

### Application Errors

```bash
# Test application
cd /home/ec2-user/zencrow-website
source venv/bin/activate
python deployment/test-app.py

# Check application logs
sudo journalctl -u zencrow -f
```

### Connection Refused

1. **Check AWS Security Group:**
   - Ensure HTTP (port 80) is allowed from 0.0.0.0/0
   - Go to: AWS Console → EC2 → Instances → Security Group

2. **Check services are running:**
   ```bash
   sudo systemctl status zencrow nginx
   ```

3. **Check ports are listening:**
   ```bash
   sudo netstat -tlnp | grep -E ':80|:8000'
   ```

## Useful Commands

### Service Management

```bash
# Start services
sudo systemctl start zencrow nginx

# Stop services
sudo systemctl stop zencrow nginx

# Restart services
sudo systemctl restart zencrow nginx

# Check status
sudo systemctl status zencrow nginx

# View logs
sudo journalctl -u zencrow -f
sudo tail -f /var/log/nginx/error.log
```

### Application Management

```bash
# Test application
python deployment/test-app.py

# Update dependencies
source venv/bin/activate
pip install -r requirements.txt

# Restart after changes
sudo systemctl restart zencrow
```

## Security Considerations

1. **Environment Variables:**
   - Update `.env` file with strong SECRET_KEY
   - Configure email credentials if needed

2. **AWS Security Group:**
   - Restrict SSH access to your IP only
   - Allow HTTP/HTTPS from appropriate sources

3. **SSL/HTTPS:**
   - Set up SSL certificate for production
   - Use Let's Encrypt or AWS Certificate Manager

4. **Regular Updates:**
   - Keep system packages updated
   - Update Python dependencies regularly
   - Monitor security advisories

## Support

For detailed deployment instructions, see:
- **`DEPLOYMENT_GUIDE.md`** - Comprehensive deployment guide

For issues:
1. Check service logs: `sudo journalctl -u zencrow -f`
2. Test application: `python deployment/test-app.py`
3. Verify configuration files
4. Check AWS Security Group settings

---

**Ready to deploy?** Run `bash deployment/deploy-after-upload.sh` on your EC2 instance!
