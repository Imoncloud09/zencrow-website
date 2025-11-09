# Zencrow Website - AWS EC2 Deployment Guide

Complete guide for deploying the Zencrow website on Amazon Linux EC2.

## Quick Start

### After Uploading Files to EC2

1. **Connect to EC2:**
   ```bash
   ssh -i "D:\zenprod-new.pem" ec2-user@ec2-3-109-210-116.ap-south-1.compute.amazonaws.com
   ```

2. **Navigate to application directory:**
   ```bash
   cd /home/ec2-user/zencrow-website
   ```

3. **Run deployment script:**
   ```bash
   chmod +x deployment/*.sh
   bash deployment/deploy-after-upload.sh
   ```

That's it! The script will handle everything automatically.

### From Windows (Transfer and Deploy)

1. **Run PowerShell script:**
   ```powershell
   .\deployment\transfer-to-ec2.ps1
   ```

   This will transfer your code and deploy automatically.

## What Gets Deployed

The deployment script automatically:

- ✅ Installs system dependencies (Python, Nginx, etc.)
- ✅ Sets up Python virtual environment
- ✅ Installs Python dependencies
- ✅ Tests the application
- ✅ Configures Gunicorn
- ✅ Sets up systemd service
- ✅ Configures Nginx reverse proxy
- ✅ Starts services
- ✅ Verifies deployment

## Deployment Files

### Essential Files

- **`deployment/deploy-after-upload.sh`** - Main deployment script
- **`deployment/gunicorn.conf.py`** - Gunicorn configuration
- **`deployment/nginx.conf`** - Nginx configuration
- **`deployment/zencrow.service`** - Systemd service file
- **`deployment/test-app.py`** - Application test script

### Utility Scripts

- **`deployment/update.sh`** - Update application code
- **`deployment/transfer-to-ec2.ps1`** - Transfer code from Windows

## Updating Application

After making code changes:

```bash
# On EC2
cd /home/ec2-user/zencrow-website
bash deployment/update.sh
```

Or manually:

```bash
# Upload new code, then:
cd /home/ec2-user/zencrow-website
source venv/bin/activate
pip install -r requirements.txt
sudo systemctl restart zencrow
```

## Troubleshooting

### Connection Refused Error

**Most Common Cause:** AWS Security Group not allowing HTTP traffic

**Fix:**
1. Go to AWS Console → EC2 → Instances
2. Select your instance
3. Security tab → Security Group → Edit inbound rules
4. Add rule: HTTP, Port 80, Source: 0.0.0.0/0
5. Save rules

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
python deployment/test-app.py

# Check application logs
sudo journalctl -u zencrow -f
```

### Port Not Listening

```bash
# Check if ports are listening
sudo netstat -tlnp | grep -E ':80|:8000'

# If not, check services
sudo systemctl status zencrow nginx
```

## Verification

After deployment, verify:

```bash
# Check services
sudo systemctl status zencrow nginx

# Check ports
sudo netstat -tlnp | grep -E ':80|:8000'

# Test locally
curl http://localhost:8000/health
curl http://localhost/health

# Get public IP
curl http://169.254.169.254/latest/meta-data/public-ipv4
```

Then access your application at: `http://<your-ec2-ip>`

## Useful Commands

### Service Management

```bash
# Start/Stop/Restart services
sudo systemctl start zencrow nginx
sudo systemctl stop zencrow nginx
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

## Security

1. **AWS Security Group:**
   - Restrict SSH to your IP only
   - Allow HTTP/HTTPS from appropriate sources

2. **Environment Variables:**
   - Use strong SECRET_KEY
   - Don't commit .env file to Git

3. **SSL/HTTPS:**
   - Set up SSL certificate for production
   - Use Let's Encrypt or AWS Certificate Manager

4. **Updates:**
   - Keep system packages updated
   - Update Python dependencies regularly

## Next Steps

After successful deployment:

1. ✅ Configure domain name (if you have one)
2. ✅ Set up SSL certificate for HTTPS
3. ✅ Configure email settings in `.env`
4. ✅ Set up monitoring and alerts
5. ✅ Set up automated backups
6. ✅ Configure log rotation

## Support

For detailed information, see:
- **`deployment/README.md`** - Deployment directory documentation
- **`deployment/DEPLOYMENT_GUIDE.md`** - Comprehensive deployment guide

## Common Issues and Solutions

### Issue: "Unit zencrow.service not found"
**Solution:** Service file not installed. Run deployment script again.

### Issue: "nginx.service failed to start"
**Solution:** Check nginx configuration: `sudo nginx -t`

### Issue: "Connection refused" from browser
**Solution:** Check AWS Security Group allows HTTP (port 80)

### Issue: Services running but can't access
**Solution:** Verify ports are listening and Security Group is configured

---

**Ready to deploy?** Run `bash deployment/deploy-after-upload.sh` on your EC2 instance!
