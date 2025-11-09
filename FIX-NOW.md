# Fix Connection Refused - Step by Step

## Problem
`ERR_CONNECTION_REFUSED` when accessing `http://3.109.210.116`

## Solution: Two Things to Check

### Step 1: Configure AWS Security Group (MOST IMPORTANT)

1. **Go to AWS Console**
   - Open: https://console.aws.amazon.com/ec2/
   - Sign in if needed

2. **Find Your Instance**
   - Click "Instances" in left menu
   - Find instance with IP `3.109.210.116`
   - Click on the instance to select it

3. **Open Security Group**
   - Look at bottom panel, click "Security" tab
   - Click on the Security Group name (blue link like `sg-0123456789abcdef0`)

4. **Add HTTP Rule**
   - Click "Edit inbound rules" button
   - Click "Add rule"
   - Fill in:
     ```
     Type: HTTP
     Protocol: TCP
     Port range: 80
     Source: 0.0.0.0/0
     Description: Allow HTTP traffic
     ```
   - Click "Save rules"

5. **Wait 10-30 seconds** for changes to take effect

### Step 2: Verify Services on EC2

1. **Open PowerShell or Git Bash** on your local machine

2. **Connect to EC2:**
   ```bash
   ssh -i "zenprod-new.pem" ec2-user@ec2-3-109-210-116.ap-south-1.compute.amazonaws.com
   ```

3. **Check if application directory exists:**
   ```bash
   ls -la /home/ec2-user/zencrow-website
   ```

4. **If directory doesn't exist or is empty, deploy first:**
   ```bash
   # Exit SSH (type: exit)
   # Then from your local machine, transfer code:
   ```

5. **If directory exists, check services:**
   ```bash
   cd /home/ec2-user/zencrow-website
   
   # Check if services are running
   sudo systemctl status zencrow
   sudo systemctl status nginx
   
   # If not running, start them
   sudo systemctl start zencrow
   sudo systemctl start nginx
   sudo systemctl enable zencrow
   sudo systemctl enable nginx
   
   # Check if ports are listening
   sudo netstat -tlnp | grep -E ':80|:8000'
   ```

## If Application is Not Deployed Yet

### Option A: Deploy from Windows (Easiest)

1. **Open PowerShell** in your project directory
2. **Run:**
   ```powershell
   .\deployment\transfer-to-ec2.ps1
   ```

### Option B: Manual Deployment

1. **From your local machine (PowerShell or Git Bash):**
   ```bash
   # Transfer code to EC2
   scp -i "zenprod-new.pem" -r . ec2-user@ec2-3-109-210-116.ap-south-1.compute.amazonaws.com:/home/ec2-user/zencrow-website
   ```

2. **Connect to EC2 and deploy:**
   ```bash
   ssh -i "zenprod-new.pem" ec2-user@ec2-3-109-210-116.ap-south-1.compute.amazonaws.com
   cd /home/ec2-user/zencrow-website
   chmod +x deployment/*.sh
   bash deployment/deploy-aws.sh
   ```

## Quick Test Commands (Run on EC2)

```bash
# Test 1: Check if services are running
sudo systemctl status zencrow nginx

# Test 2: Check if ports are listening
sudo netstat -tlnp | grep -E ':80|:8000'

# Test 3: Test application locally
curl http://localhost:8000/health

# Test 4: Test through Nginx
curl http://localhost/health

# Test 5: Check public IP
curl http://169.254.169.254/latest/meta-data/public-ipv4
```

## Common Issues

### Issue: "Permission denied (publickey)"
**Solution:** Make sure PEM key is in current directory and has correct name

### Issue: "Connection timed out" (not refused)
**Solution:** Security Group might be blocking SSH. Check Security Group allows SSH (port 22) from your IP

### Issue: Services won't start
**Solution:** Check logs:
```bash
sudo journalctl -u zencrow -n 50
sudo tail -f /var/log/nginx/error.log
```

## Verification Checklist

After fixing, verify:

- [ ] AWS Security Group has HTTP (port 80) rule with source 0.0.0.0/0
- [ ] SSH into EC2 works
- [ ] Application directory exists: `/home/ec2-user/zencrow-website`
- [ ] Zencrow service is running: `sudo systemctl status zencrow`
- [ ] Nginx service is running: `sudo systemctl status nginx`
- [ ] Port 80 is listening: `sudo netstat -tlnp | grep :80`
- [ ] Port 8000 is listening: `sudo netstat -tlnp | grep :8000`
- [ ] Can access: `http://3.109.210.116`

## Still Not Working?

Run the diagnostic script on EC2:
```bash
cd /home/ec2-user/zencrow-website
bash deployment/diagnose.sh
```

Or run the fix script:
```bash
bash deployment/fix-connection-refused.sh
```

---

**Remember: 90% of connection refused errors are due to Security Group not allowing HTTP (port 80) traffic!**

