# Fix Connection Refused Error

You're getting `ERR_CONNECTION_REFUSED` when accessing `3.109.210.116`. This is most likely an **AWS Security Group** configuration issue.

## Quick Fix: Configure AWS Security Group

### Step 1: Open AWS Console

1. Go to **AWS Console** → **EC2** → **Instances**
2. Find your instance with IP `3.109.210.116`
3. Click on the instance to select it

### Step 2: Configure Security Group

1. Click on the **Security** tab (bottom panel)
2. Click on the **Security Group** name (e.g., `sg-xxxxxxxxx`)
3. Click on **Edit inbound rules**
4. Click **Add rule**
5. Configure:
   - **Type:** HTTP
   - **Protocol:** TCP
   - **Port range:** 80
   - **Source:** 0.0.0.0/0
   - **Description:** Allow HTTP traffic
6. Click **Save rules**

### Step 3: Verify Services on EC2

SSH into your EC2 instance and verify services are running:

```bash
# Connect to EC2
ssh -i "zenprod-new.pem" ec2-user@ec2-3-109-210-116.ap-south-1.compute.amazonaws.com

# Run the fix script
cd /home/ec2-user/zencrow-website
chmod +x deployment/*.sh
bash deployment/fix-connection-refused.sh
```

### Step 4: Test Connection

After configuring the Security Group:
1. Wait 10-30 seconds for changes to propagate
2. Try accessing: `http://3.109.210.116`
3. If still not working, check the service status on EC2

## Alternative: Check and Fix on EC2

If the Security Group is configured correctly, the issue might be on the EC2 instance:

```bash
# SSH into EC2
ssh -i "zenprod-new.pem" ec2-user@ec2-3-109-210-116.ap-south-1.compute.amazonaws.com

# Check if application is deployed
cd /home/ec2-user/zencrow-website
ls -la

# If not deployed, deploy it
chmod +x deployment/*.sh
bash deployment/deploy-aws.sh

# If deployed, check service status
sudo systemctl status zencrow
sudo systemctl status nginx

# If services are not running, start them
sudo systemctl start zencrow
sudo systemctl start nginx

# Check if ports are listening
sudo netstat -tlnp | grep -E ':80|:8000'
```

## Common Issues and Solutions

### Issue 1: Security Group Not Configured
**Solution:** Add HTTP (port 80) rule as described above

### Issue 2: Services Not Running
**Solution:** 
```bash
sudo systemctl start zencrow
sudo systemctl start nginx
sudo systemctl enable zencrow
sudo systemctl enable nginx
```

### Issue 3: Application Not Deployed
**Solution:** Run the deployment script:
```bash
cd /home/ec2-user/zencrow-website
bash deployment/deploy-aws.sh
```

### Issue 4: Port Not Listening
**Solution:** Check service logs:
```bash
sudo journalctl -u zencrow -n 50
sudo tail -f /var/log/nginx/error.log
```

## Verification Steps

1. **Check Security Group** (AWS Console)
   - [ ] HTTP (port 80) rule exists
   - [ ] Source is 0.0.0.0/0 or your IP
   - [ ] Rule is saved

2. **Check Services on EC2**
   - [ ] Zencrow service is running: `sudo systemctl status zencrow`
   - [ ] Nginx service is running: `sudo systemctl status nginx`
   - [ ] Port 8000 is listening: `sudo netstat -tlnp | grep :8000`
   - [ ] Port 80 is listening: `sudo netstat -tlnp | grep :80`

3. **Test Locally on EC2**
   - [ ] Health endpoint works: `curl http://localhost:8000/health`
   - [ ] Nginx proxy works: `curl http://localhost/health`

4. **Test from Browser**
   - [ ] Access: `http://3.109.210.116`
   - [ ] Should see your website

## Quick Diagnostic Script

Run this on your EC2 instance to diagnose all issues:

```bash
cd /home/ec2-user/zencrow-website
bash deployment/diagnose.sh
```

## Still Not Working?

1. **Run the fix script:**
   ```bash
   bash deployment/fix-connection-refused.sh
   ```

2. **Check service logs:**
   ```bash
   sudo journalctl -u zencrow -f
   sudo tail -f /var/log/nginx/error.log
   ```

3. **Verify Security Group in AWS Console**
   - Make sure HTTP (port 80) is allowed
   - Source should be 0.0.0.0/0 for public access

4. **Check if instance is in public subnet**
   - Go to EC2 → Instances → Your instance
   - Check if it has a public IP
   - Check route table has internet gateway

---

**Most Common Fix:** Add HTTP (port 80) rule to your Security Group in AWS Console!

