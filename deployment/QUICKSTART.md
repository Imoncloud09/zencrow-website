# Quick Start Deployment Guide

## Option 1: Deploy from Windows (PowerShell)

1. **Open PowerShell** in the project directory
2. **Run the deployment script**:
   ```powershell
   .\deployment\transfer-to-ec2.ps1
   ```
3. The script will:
   - Transfer your code to EC2
   - Run the deployment script automatically
   - Show you the deployment URL

## Option 2: Deploy from Linux/Mac (Bash)

1. **Make scripts executable**:
   ```bash
   chmod +x deployment/*.sh
   ```
2. **Run the transfer and deploy script**:
   ```bash
   ./deployment/transfer-and-deploy.sh
   ```

## Option 3: Manual Deployment on EC2

1. **Connect to your EC2 instance**:
   ```bash
   ssh -i "zenprod-new.pem" ec2-user@ec2-3-109-210-116.ap-south-1.compute.amazonaws.com
   ```

2. **Transfer your code** (from your local machine):
   ```bash
   # Using SCP
   scp -i "zenprod-new.pem" -r . ec2-user@ec2-3-109-210-116.ap-south-1.compute.amazonaws.com:/home/ec2-user/zencrow-website
   ```

3. **Run the deployment script** on EC2:
   ```bash
   cd /home/ec2-user/zencrow-website
   chmod +x deployment/*.sh
   bash deployment/deploy-aws.sh
   ```

## Option 4: Quick Deploy (If code is already on EC2)

1. **Connect to EC2**:
   ```bash
   ssh -i "zenprod-new.pem" ec2-user@ec2-3-109-210-116.ap-south-1.compute.amazonaws.com
   ```

2. **Run quick deploy**:
   ```bash
   cd /home/ec2-user/zencrow-website
   bash deployment/quick-deploy.sh
   ```

## Troubleshooting

### If deployment fails:

1. **Run diagnostics**:
   ```bash
   ssh -i "zenprod-new.pem" ec2-user@ec2-3-109-210-116.ap-south-1.compute.amazonaws.com
   cd /home/ec2-user/zencrow-website
   bash deployment/diagnose.sh
   ```

2. **Check service logs**:
   ```bash
   sudo journalctl -u zencrow -f
   ```

3. **Check service status**:
   ```bash
   sudo systemctl status zencrow
   ```

### Common Issues:

- **Service won't start**: Check logs with `sudo journalctl -u zencrow -n 50`
- **Port not accessible**: Check AWS Security Group allows HTTP (80)
- **Permission errors**: Run `sudo chown -R ec2-user:ec2-user /home/ec2-user/zencrow-website`
- **Python errors**: Recreate venv with `python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt`

## Verify Deployment

After deployment, your application should be accessible at:
```
http://<your-ec2-public-ip>
```

To get your EC2 public IP:
```bash
curl http://169.254.169.254/latest/meta-data/public-ipv4
```

## Next Steps

1. Configure your domain name (if you have one)
2. Set up SSL certificate for HTTPS
3. Configure email settings in `.env` file
4. Set up monitoring and backups

For detailed information, see [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)

