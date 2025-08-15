# Zencrow Website Deployment Guide for Amazon Linux EC2

This guide will walk you through deploying your Flask application on Amazon Linux EC2 step by step.

## Prerequisites

- An AWS EC2 instance running Amazon Linux 2
- Security group configured to allow HTTP (port 80) and HTTPS (port 443)
- SSH access to your EC2 instance
- A domain name (optional but recommended)

## Step 1: Launch EC2 Instance

1. **Launch Instance:**
   - Go to AWS Console → EC2 → Launch Instance
   - Choose Amazon Linux 2 AMI
   - Select instance type (t2.micro for testing, t2.small or larger for production)
   - Configure security group to allow:
     - SSH (port 22) from your IP
     - HTTP (port 80) from anywhere
     - HTTPS (port 443) from anywhere

2. **Connect to Instance:**
   ```bash
   ssh -i your-key.pem ec2-user@your-ec2-public-ip
   ```

## Step 2: Prepare Your Local Repository

1. **Push your code to GitHub:**
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin https://github.com/yourusername/zencrow-website.git
   git push -u origin main
   ```

2. **Update the deployment script:**
   - Edit `deployment/deploy.sh` and change `yourusername` to your actual GitHub username

## Step 3: Deploy on EC2

1. **Make the deployment script executable:**
   ```bash
   chmod +x deployment/deploy.sh
   ```

2. **Run the deployment script:**
   ```bash
   ./deployment/deploy.sh
   ```

   The script will:
   - Update system packages
   - Install Python, Nginx, and other dependencies
   - Clone your repository
   - Set up virtual environment
   - Install Python dependencies
   - Configure Nginx and Gunicorn
   - Set up systemd service
   - Configure firewall

## Step 4: Configure Environment Variables

1. **Edit the .env file:**
   ```bash
   nano .env
   ```

2. **Update with your actual values:**
   ```env
   FLASK_ENV=production
   SECRET_KEY=your-generated-secret-key
   DATABASE_URL=sqlite:///zencrow.db
   MAIL_SERVER=smtp.gmail.com
   MAIL_PORT=587
   MAIL_USE_TLS=True
   MAIL_USERNAME=your-email@gmail.com
   MAIL_PASSWORD=your-app-password
   ```

3. **Restart the service:**
   ```bash
   sudo systemctl restart zencrow
   ```

## Step 5: Configure Domain (Optional)

1. **Update Nginx configuration:**
   ```bash
   sudo nano /etc/nginx/conf.d/zencrow.conf
   ```
   Replace `your-domain.com` with your actual domain

2. **Reload Nginx:**
   ```bash
   sudo systemctl reload nginx
   ```

## Step 6: SSL Certificate (Recommended)

1. **Install Certbot:**
   ```bash
   sudo yum install -y certbot python3-certbot-nginx
   ```

2. **Obtain SSL certificate:**
   ```bash
   sudo certbot --nginx -d your-domain.com
   ```

## Step 7: Test Your Application

1. **Check service status:**
   ```bash
   sudo systemctl status zencrow
   sudo systemctl status nginx
   ```

2. **View logs:**
   ```bash
   sudo journalctl -u zencrow -f
   sudo tail -f /var/log/nginx/error.log
   ```

3. **Test in browser:**
   - Visit `http://your-ec2-public-ip` or `https://your-domain.com`

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

### Nginx Management
```bash
# Start Nginx
sudo systemctl start nginx

# Stop Nginx
sudo systemctl stop nginx

# Reload configuration
sudo systemctl reload nginx

# Check status
sudo systemctl status nginx
```

### Application Updates
```bash
# Pull latest code
cd /home/ec2-user/zencrow-website
git pull origin main

# Install new dependencies
source venv/bin/activate
pip install -r requirements.txt

# Restart service
sudo systemctl restart zencrow
```

## Troubleshooting

### Common Issues

1. **Service won't start:**
   ```bash
   sudo journalctl -u zencrow -n 50
   ```

2. **Nginx errors:**
   ```bash
   sudo nginx -t
   sudo tail -f /var/log/nginx/error.log
   ```

3. **Permission issues:**
   ```bash
   sudo chown -R ec2-user:ec2-user /home/ec2-user/zencrow-website
   ```

4. **Port conflicts:**
   ```bash
   sudo netstat -tlnp | grep :80
   sudo netstat -tlnp | grep :8000
   ```

### Performance Tuning

1. **Adjust Gunicorn workers:**
   - Edit `gunicorn.conf.py`
   - Increase workers based on CPU cores: `workers = (2 x num_cores) + 1`

2. **Nginx optimization:**
   - Enable gzip compression
   - Configure caching headers
   - Use CDN for static files

## Security Considerations

1. **Keep system updated:**
   ```bash
   sudo yum update -y
   ```

2. **Configure firewall properly:**
   ```bash
   sudo firewall-cmd --list-all
   ```

3. **Use strong passwords and keys**
4. **Regular security audits**
5. **Monitor logs for suspicious activity**

## Backup Strategy

1. **Database backup:**
   ```bash
   cp /home/ec2-user/zencrow-website/instance/zencrow.db /backup/
   ```

2. **Code backup:**
   ```bash
   git push origin main
   ```

3. **Configuration backup:**
   ```bash
   sudo cp /etc/nginx/conf.d/zencrow.conf /backup/
   sudo cp /etc/systemd/system/zencrow.service /backup/
   ```

## Monitoring

1. **Set up CloudWatch alarms**
2. **Monitor disk space:**
   ```bash
   df -h
   ```
3. **Monitor memory usage:**
   ```bash
   free -h
   ```
4. **Monitor CPU usage:**
   ```bash
   top
   ```

## Support

If you encounter issues:
1. Check the logs first
2. Verify configuration files
3. Test individual components
4. Check system resources
5. Review security group settings

---

**Note:** This deployment uses SQLite for simplicity. For production, consider using PostgreSQL or MySQL with proper backup strategies.
