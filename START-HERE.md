# Start Here - Troubleshoot EC2 Deployment

## Quick Start: Connect and Troubleshoot

### Step 1: Run Diagnostic Script (Easiest)

**Open PowerShell in your project directory and run:**

```powershell
.\connect-and-diagnose.ps1
```

This will:
- Connect to EC2 using PEM key from D:\
- Run diagnostics
- Show you what's wrong
- Provide fix suggestions

### Step 2: Manual Connection (If script doesn't work)

**Open PowerShell and run:**

```powershell
# Connect to EC2
ssh -i "D:\zenprod-new.pem" ec2-user@ec2-3-109-210-116.ap-south-1.compute.amazonaws.com
```

**Once connected, run:**

```bash
# Check if application is deployed
ls -la /home/ec2-user/zencrow-website

# If directory exists, run troubleshooting
cd /home/ec2-user/zencrow-website
bash deployment/troubleshoot-ec2.sh

# Or run auto-fix (if code is already there)
bash deployment/auto-fix.sh
```

## What Each Script Does

### 1. `connect-and-diagnose.ps1`
- Connects to EC2
- Runs diagnostics
- Shows status of services, ports, and application

### 2. `quick-connect.ps1`
- Opens interactive SSH session
- Lets you run commands manually

### 3. `troubleshoot-ec2.sh` (run on EC2)
- Comprehensive diagnostic
- Checks all components
- Provides fix suggestions

### 4. `auto-fix.sh` (run on EC2)
- Automatically fixes common issues
- Sets up services
- Starts application

## Common Scenarios

### Scenario 1: Application Not Deployed

**Symptoms:**
- Directory `/home/ec2-user/zencrow-website` doesn't exist
- No application files

**Solution:**
```powershell
# From your local machine
.\deployment\transfer-to-ec2.ps1
```

This will transfer code and deploy automatically.

### Scenario 2: Services Not Running

**Symptoms:**
- Services exist but not running
- Ports not listening

**Solution:**
```bash
# On EC2
sudo systemctl start zencrow
sudo systemctl start nginx
sudo systemctl enable zencrow
sudo systemctl enable nginx
```

### Scenario 3: Connection Refused from Browser

**Symptoms:**
- Services running on EC2
- Can't access from browser
- ERR_CONNECTION_REFUSED

**Solution:**
1. **Check AWS Security Group:**
   - Go to AWS Console → EC2 → Instances
   - Select your instance
   - Security tab → Security Group
   - Add rule: HTTP, Port 80, Source: 0.0.0.0/0

2. **Verify services on EC2:**
   ```bash
   sudo systemctl status zencrow
   sudo systemctl status nginx
   sudo netstat -tlnp | grep -E ':80|:8000'
   ```

### Scenario 4: Application Errors

**Symptoms:**
- Services running but application errors
- Check logs for errors

**Solution:**
```bash
# Check service logs
sudo journalctl -u zencrow -n 50

# Check application
cd /home/ec2-user/zencrow-website
source venv/bin/activate
python -c "from app import create_app; app = create_app()"
```

## Step-by-Step Troubleshooting

### Step 1: Connect to EC2
```powershell
ssh -i "D:\zenprod-new.pem" ec2-user@ec2-3-109-210-116.ap-south-1.compute.amazonaws.com
```

### Step 2: Check Application Status
```bash
# Check if directory exists
ls -la /home/ec2-user/zencrow-website

# Check services
sudo systemctl status zencrow
sudo systemctl status nginx

# Check ports
sudo netstat -tlnp | grep -E ':80|:8000'

# Check logs
sudo journalctl -u zencrow -n 20
```

### Step 3: Fix Issues

**If application not deployed:**
```bash
# Exit SSH and run from local machine
# .\deployment\transfer-to-ec2.ps1
```

**If services not running:**
```bash
sudo systemctl start zencrow nginx
sudo systemctl enable zencrow nginx
```

**If need to reconfigure:**
```bash
cd /home/ec2-user/zencrow-website
bash deployment/auto-fix.sh
```

### Step 4: Verify

```bash
# Test locally
curl http://localhost:8000/health
curl http://localhost/health

# Get public IP
curl http://169.254.169.254/latest/meta-data/public-ipv4
```

### Step 5: Check AWS Security Group

1. AWS Console → EC2 → Instances
2. Select your instance
3. Security tab → Security Group
4. Ensure HTTP (port 80) rule exists
5. Source should be 0.0.0.0/0

## Quick Commands Reference

### On EC2
```bash
# Check status
sudo systemctl status zencrow nginx

# Start services
sudo systemctl start zencrow nginx

# Restart services
sudo systemctl restart zencrow nginx

# View logs
sudo journalctl -u zencrow -f
sudo tail -f /var/log/nginx/error.log

# Check ports
sudo netstat -tlnp | grep -E ':80|:8000'

# Test application
curl http://localhost:8000/health
```

### From Local Machine
```powershell
# Connect to EC2
ssh -i "D:\zenprod-new.pem" ec2-user@ec2-3-109-210-116.ap-south-1.compute.amazonaws.com

# Run diagnostics
.\connect-and-diagnose.ps1

# Deploy application
.\deployment\transfer-to-ec2.ps1
```

## Files Created for Troubleshooting

1. **connect-and-diagnose.ps1** - Run diagnostics from Windows
2. **quick-connect.ps1** - Quick SSH connection
3. **troubleshoot-ec2.sh** - Comprehensive diagnostics on EC2
4. **auto-fix.sh** - Auto-fix common issues on EC2
5. **fix-connection-refused.sh** - Fix connection issues
6. **quick-check.sh** - Quick status check

## Next Steps

1. **Run diagnostic script:**
   ```powershell
   .\connect-and-diagnose.ps1
   ```

2. **Review the output** and see what needs to be fixed

3. **Fix issues** based on the diagnostic output

4. **Verify** the application is accessible

5. **Check AWS Security Group** if still can't access from browser

## Need Help?

- Check `RUN-TROUBLESHOOTING.md` for detailed troubleshooting
- Check `FIX-CONNECTION-REFUSED.md` for connection issues
- Check `deployment/DEPLOYMENT_GUIDE.md` for deployment guide

---

**Start with:** `.\connect-and-diagnose.ps1`

