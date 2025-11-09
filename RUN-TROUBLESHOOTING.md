# Run Troubleshooting on EC2

## Quick Start

### Option 1: Run Diagnostic Script (Recommended)

**From Windows PowerShell:**

```powershell
# Connect and run diagnostics
.\connect-and-diagnose.ps1
```

This will:
- Connect to EC2 using the PEM key from D:\
- Run comprehensive diagnostics
- Show you what's wrong
- Provide fix suggestions

### Option 2: Manual Connection and Troubleshooting

**Step 1: Connect to EC2**
```powershell
# Open PowerShell
ssh -i "D:\zenprod-new.pem" ec2-user@ec2-3-109-210-116.ap-south-1.compute.amazonaws.com
```

**Step 2: Run Troubleshooting Script**
```bash
# Once connected to EC2
cd /home/ec2-user/zencrow-website

# If troubleshoot script exists, run it
bash deployment/troubleshoot-ec2.sh

# Or run quick check
bash deployment/quick-check.sh

# Or run comprehensive fix
bash deployment/fix-connection-refused.sh
```

**Step 3: Check Common Issues**

```bash
# Check if application is deployed
ls -la /home/ec2-user/zencrow-website

# Check services
sudo systemctl status zencrow
sudo systemctl status nginx

# Check ports
sudo netstat -tlnp | grep -E ':80|:8000'

# Check logs
sudo journalctl -u zencrow -n 50
sudo tail -f /var/log/nginx/error.log
```

### Option 3: Quick Connect Script

**Run this for an interactive session:**
```powershell
.\quick-connect.ps1
```

This will open an SSH session where you can run commands manually.

## What to Check

### 1. Application Directory
```bash
ls -la /home/ec2-user/zencrow-website
```
**If missing:** Deploy the application first

### 2. Services Status
```bash
sudo systemctl status zencrow
sudo systemctl status nginx
```
**If not running:** Start them
```bash
sudo systemctl start zencrow
sudo systemctl start nginx
```

### 3. Ports Listening
```bash
sudo netstat -tlnp | grep -E ':80|:8000'
```
**If not listening:** Services may not be running or configured incorrectly

### 4. Application Files
```bash
cd /home/ec2-user/zencrow-website
ls -la
```
**Check for:**
- wsgi.py
- requirements.txt
- config.py
- app/ directory
- venv/ directory

### 5. Service Logs
```bash
# Zencrow service logs
sudo journalctl -u zencrow -n 50

# Nginx logs
sudo tail -f /var/log/nginx/error.log

# Gunicorn logs
tail -f /var/log/gunicorn/error.log
```

## Common Fixes

### Fix 1: Deploy Application
If application is not deployed:
```bash
# From your local machine
.\deployment\transfer-to-ec2.ps1
```

### Fix 2: Start Services
```bash
sudo systemctl start zencrow
sudo systemctl start nginx
sudo systemctl enable zencrow
sudo systemctl enable nginx
```

### Fix 3: Fix Permissions
```bash
sudo chown -R ec2-user:ec2-user /home/ec2-user/zencrow-website
sudo chown -R ec2-user:ec2-user /var/log/gunicorn
```

### Fix 4: Recreate Virtual Environment
```bash
cd /home/ec2-user/zencrow-website
rm -rf venv
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### Fix 5: Configure Services
```bash
cd /home/ec2-user/zencrow-website

# Copy service files
sudo cp deployment/zencrow.service /etc/systemd/system/
sudo cp deployment/nginx.conf /etc/nginx/conf.d/zencrow.conf

# Reload systemd
sudo systemctl daemon-reload
sudo systemctl enable zencrow
sudo systemctl start zencrow
sudo systemctl restart nginx
```

### Fix 6: Check AWS Security Group
1. Go to AWS Console → EC2 → Instances
2. Select your instance
3. Security tab → Security Group
4. Ensure HTTP (port 80) rule exists with source 0.0.0.0/0

## Diagnostic Scripts Available

1. **troubleshoot-ec2.sh** - Comprehensive troubleshooting
2. **quick-check.sh** - Quick status check
3. **fix-connection-refused.sh** - Fix connection issues
4. **diagnose.sh** - Full diagnostic report

## After Troubleshooting

Once issues are fixed:

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

## Still Having Issues?

1. Run comprehensive diagnostic:
   ```bash
   bash deployment/diagnose.sh
   ```

2. Check all logs:
   ```bash
   sudo journalctl -u zencrow -f
   sudo tail -f /var/log/nginx/error.log
   ```

3. Verify AWS Security Group configuration
4. Check if EC2 instance is in public subnet
5. Verify route table has internet gateway

