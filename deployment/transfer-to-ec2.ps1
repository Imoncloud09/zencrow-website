# PowerShell script to transfer code to EC2 and deploy
# Run this from Windows PowerShell

param(
    [string]$PemKey = "zenprod-new.pem",
    [string]$Ec2Host = "ec2-3-109-210-116.ap-south-1.compute.amazonaws.com",
    [string]$Ec2User = "ec2-user",
    [string]$AppDir = "/home/ec2-user/zencrow-website"
)

Write-Host "🚀 Zencrow Website - EC2 Deployment Script" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green

# Check if PEM key exists
if (-not (Test-Path $PemKey)) {
    Write-Host "❌ PEM key file not found: $PemKey" -ForegroundColor Red
    Write-Host "Please update the PemKey parameter or place the key file in the current directory" -ForegroundColor Yellow
    exit 1
}

# Set correct permissions for PEM key (Windows doesn't have chmod, but SSH should work)
Write-Host "✅ PEM key found: $PemKey" -ForegroundColor Green

# Test SSH connection
Write-Host "`n🔍 Testing SSH connection..." -ForegroundColor Cyan
$testConnection = ssh -i $PemKey -o StrictHostKeyChecking=no "$Ec2User@$Ec2Host" "echo 'SSH connection successful'" 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ SSH connection failed!" -ForegroundColor Red
    Write-Host "Please check:" -ForegroundColor Yellow
    Write-Host "  1. PEM key path is correct" -ForegroundColor Yellow
    Write-Host "  2. EC2 instance is running" -ForegroundColor Yellow
    Write-Host "  3. Security group allows SSH from your IP" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ SSH connection successful" -ForegroundColor Green

# Create application directory on EC2
Write-Host "`n📁 Creating application directory on EC2..." -ForegroundColor Cyan
ssh -i $PemKey "$Ec2User@$Ec2Host" "mkdir -p $AppDir" 2>&1 | Out-Null

# Transfer files using SCP
Write-Host "📤 Transferring files to EC2..." -ForegroundColor Cyan
Write-Host "This may take a few moments..." -ForegroundColor Yellow

# Exclude unnecessary files
$excludePatterns = @(
    "__pycache__",
    "*.pyc",
    "venv",
    "instance",
    "*.db",
    ".git",
    ".vscode",
    ".idea",
    "*.log",
    ".env"
)

# Build SCP command
$scpCommand = "scp -i $PemKey -r"

# Transfer deployment directory first
Write-Host "  → Transferring deployment files..." -ForegroundColor Gray
scp -i $PemKey -r deployment "$Ec2User@${Ec2Host}:$AppDir/" 2>&1 | Out-Null

# Transfer main application files
Write-Host "  → Transferring application files..." -ForegroundColor Gray
$filesToTransfer = @(
    "app",
    "config.py",
    "run.py",
    "wsgi.py",
    "requirements.txt",
    "gunicorn.conf.py"
)

foreach ($file in $filesToTransfer) {
    if (Test-Path $file) {
        if (Test-Path $file -PathType Container) {
            scp -i $PemKey -r $file "$Ec2User@${Ec2Host}:$AppDir/" 2>&1 | Out-Null
        } else {
            scp -i $PemKey $file "$Ec2User@${Ec2Host}:$AppDir/" 2>&1 | Out-Null
        }
        Write-Host "    ✓ $file" -ForegroundColor DarkGray
    }
}

# Transfer public directory if it exists
if (Test-Path "public") {
    Write-Host "  → Transferring public files..." -ForegroundColor Gray
    scp -i $PemKey -r public "$Ec2User@${Ec2Host}:$AppDir/" 2>&1 | Out-Null
}

Write-Host "✅ Files transferred successfully" -ForegroundColor Green

# Make deployment scripts executable
Write-Host "`n🔧 Setting up deployment scripts..." -ForegroundColor Cyan
ssh -i $PemKey "$Ec2User@$Ec2Host" "chmod +x $AppDir/deployment/*.sh" 2>&1 | Out-Null

# Run deployment script
Write-Host "`n🚀 Running deployment script on EC2..." -ForegroundColor Cyan
Write-Host "This may take several minutes..." -ForegroundColor Yellow

ssh -i $PemKey "$Ec2User@$Ec2Host" "cd $AppDir && bash deployment/deploy-after-upload.sh"

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Deployment completed successfully!" -ForegroundColor Green
    
    # Get public IP
    $publicIp = ssh -i $PemKey "$Ec2User@$Ec2Host" "curl -s http://169.254.169.254/latest/meta-data/public-ipv4" 2>&1
    
    Write-Host "`n🌐 Your application should be accessible at:" -ForegroundColor Cyan
    Write-Host "   http://$publicIp" -ForegroundColor White
    
    Write-Host "`n📝 Useful commands:" -ForegroundColor Cyan
    Write-Host "   Check service status: ssh -i $PemKey $Ec2User@$Ec2Host 'sudo systemctl status zencrow'" -ForegroundColor Gray
    Write-Host "   View logs: ssh -i $PemKey $Ec2User@$Ec2Host 'sudo journalctl -u zencrow -f'" -ForegroundColor Gray
} else {
    Write-Host "`n❌ Deployment failed!" -ForegroundColor Red
    Write-Host "Please check the error messages above and try again." -ForegroundColor Yellow
    exit 1
}

