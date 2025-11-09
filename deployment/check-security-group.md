# AWS Security Group Configuration

## Connection Refused Error Fix

If you're getting `ERR_CONNECTION_REFUSED` when trying to access your EC2 instance, it's likely a Security Group configuration issue.

## Step-by-Step Fix

### 1. Check Your EC2 Instance Security Group

1. Go to **AWS Console** → **EC2** → **Instances**
2. Select your EC2 instance (`3.109.210.116`)
3. Click on the **Security** tab
4. Click on the **Security Group** name (e.g., `sg-xxxxxxxxx`)

### 2. Add Inbound Rules

Your Security Group needs these **Inbound Rules**:

#### HTTP (Port 80)
- **Type:** HTTP
- **Protocol:** TCP
- **Port range:** 80
- **Source:** 0.0.0.0/0 (or your specific IP)
- **Description:** Allow HTTP traffic

#### HTTPS (Port 443) - Optional but recommended
- **Type:** HTTPS
- **Protocol:** TCP
- **Port range:** 443
- **Source:** 0.0.0.0/0 (or your specific IP)
- **Description:** Allow HTTPS traffic

#### SSH (Port 22) - Should already be configured
- **Type:** SSH
- **Protocol:** TCP
- **Port range:** 22
- **Source:** Your IP address
- **Description:** Allow SSH access

### 3. Quick Fix via AWS CLI

If you have AWS CLI configured, you can add the rule:

```bash
# Get your security group ID (from EC2 console)
SECURITY_GROUP_ID="sg-xxxxxxxxx"

# Add HTTP rule
aws ec2 authorize-security-group-ingress \
    --group-id $SECURITY_GROUP_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0

# Add HTTPS rule (optional)
aws ec2 authorize-security-group-ingress \
    --group-id $SECURITY_GROUP_ID \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0
```

### 4. Verify Services Are Running

After fixing the Security Group, verify services are running on EC2:

```bash
# SSH into your EC2 instance
ssh -i "zenprod-new.pem" ec2-user@ec2-3-109-210-116.ap-south-1.compute.amazonaws.com

# Run the fix script
cd /home/ec2-user/zencrow-website
bash deployment/fix-connection-refused.sh
```

### 5. Test Connection

After configuring the Security Group:

1. Wait a few seconds for changes to propagate
2. Try accessing: `http://3.109.210.116`
3. If still not working, check:
   - Services are running: `sudo systemctl status zencrow nginx`
   - Ports are listening: `sudo netstat -tlnp | grep -E ':80|:8000'`
   - Application is working: `curl http://localhost:8000/health`

## Common Issues

### Issue: Security Group allows traffic but still can't connect

**Solution:**
1. Check if services are running on EC2
2. Check if ports are actually listening
3. Verify the application is deployed correctly

### Issue: Can connect via SSH but not HTTP

**Solution:**
- This confirms it's a Security Group issue
- Add the HTTP (port 80) rule as described above

### Issue: Connection times out instead of refused

**Solution:**
- This might be a network routing issue
- Check if the instance is in a public subnet
- Verify the route table has internet gateway

## Verification Checklist

- [ ] Security Group has HTTP (port 80) inbound rule
- [ ] Security Group has HTTPS (port 443) inbound rule (optional)
- [ ] Security Group source is 0.0.0.0/0 or your IP
- [ ] EC2 instance is running
- [ ] Nginx service is running: `sudo systemctl status nginx`
- [ ] Zencrow service is running: `sudo systemctl status zencrow`
- [ ] Port 80 is listening: `sudo netstat -tlnp | grep :80`
- [ ] Port 8000 is listening: `sudo netstat -tlnp | grep :8000`
- [ ] Application responds: `curl http://localhost:8000/health`

## Still Having Issues?

1. Run the diagnostic script:
   ```bash
   bash deployment/diagnose.sh
   ```

2. Run the connection fix script:
   ```bash
   bash deployment/fix-connection-refused.sh
   ```

3. Check service logs:
   ```bash
   sudo journalctl -u zencrow -f
   sudo tail -f /var/log/nginx/error.log
   ```

4. Verify Security Group in AWS Console

