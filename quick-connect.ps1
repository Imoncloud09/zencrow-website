# Quick Connect to EC2 and Run Commands
# Simple script to connect and troubleshoot

$PemKey = "D:\zenprod-new.pem"
$Ec2Host = "ec2-3-109-210-116.ap-south-1.compute.amazonaws.com"
$Ec2User = "ec2-user"

Write-Host "🚀 Quick Connect to EC2" -ForegroundColor Green
Write-Host "=======================" -ForegroundColor Green
Write-Host ""

# Check PEM key
if (-not (Test-Path $PemKey)) {
    Write-Host "❌ PEM key not found at: $PemKey" -ForegroundColor Red
    Write-Host "Please update the PEM key path in this script" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ PEM key: $PemKey" -ForegroundColor Green
Write-Host "🌐 Connecting to: $Ec2Host" -ForegroundColor Green
Write-Host ""

# Connect to EC2 with interactive shell
Write-Host "Connecting to EC2 instance..." -ForegroundColor Cyan
Write-Host "Once connected, you can run:" -ForegroundColor Yellow
Write-Host "  - cd /home/ec2-user/zencrow-website" -ForegroundColor White
Write-Host "  - bash deployment/troubleshoot-ec2.sh" -ForegroundColor White
Write-Host "  - sudo systemctl status zencrow" -ForegroundColor White
Write-Host "  - sudo systemctl status nginx" -ForegroundColor White
Write-Host ""

ssh -i $PemKey "$Ec2User@$Ec2Host"

