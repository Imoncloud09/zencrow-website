# Connect to EC2, Run Diagnostics, and Fix Issues
# This script will connect to EC2, diagnose issues, and attempt to fix them

$PemKey = "D:\zenprod-new.pem"
$Ec2Host = "ec2-3-109-210-116.ap-south-1.compute.amazonaws.com"
$Ec2User = "ec2-user"
$AppDir = "/home/ec2-user/zencrow-website"

Write-Host "🔧 Connect to EC2 and Fix Issues" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green
Write-Host ""

# Check if PEM key exists
if (-not (Test-Path $PemKey)) {
    Write-Host "❌ PEM key not found at: $PemKey" -ForegroundColor Red
    Write-Host "Please verify the PEM key location" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ PEM key found: $PemKey" -ForegroundColor Green
Write-Host "🌐 EC2 Host: $Ec2Host" -ForegroundColor Green
Write-Host ""

# Test SSH connection
Write-Host "🔌 Testing SSH connection..." -ForegroundColor Cyan
try {
    $null = ssh -i $PemKey -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$Ec2User@$Ec2Host" "echo 'Connected'" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ SSH connection successful" -ForegroundColor Green
    } else {
        Write-Host "❌ SSH connection failed. Please check:" -ForegroundColor Red
        Write-Host "   - PEM key permissions" -ForegroundColor Yellow
        Write-Host "   - EC2 instance is running" -ForegroundColor Yellow
        Write-Host "   - Security Group allows SSH from your IP" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "❌ SSH connection error: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🔍 Running diagnostics on EC2..." -ForegroundColor Cyan
Write-Host ""

# Run diagnostic commands directly
$diagnosticCommands = @"
cd /home/ec2-user/zencrow-website 2>/dev/null || echo 'Directory does not exist'
echo ''
echo '=== Checking Application Directory ==='
if [ -d '/home/ec2-user/zencrow-website' ]; then
    echo '✅ Application directory exists'
    cd /home/ec2-user/zencrow-website
    ls -la | head -10
else
    echo '❌ Application directory NOT found'
    echo '💡 Need to deploy application'
fi
echo ''
echo '=== Checking Services ==='
sudo systemctl status zencrow --no-pager -l | head -10 || echo 'zencrow service not found'
echo ''
sudo systemctl status nginx --no-pager -l | head -10 || echo 'nginx service not found'
echo ''
echo '=== Checking Ports ==='
sudo netstat -tlnp 2>/dev/null | grep -E ':80|:8000' || ss -tlnp 2>/dev/null | grep -E ':80|:8000' || echo 'No ports listening'
echo ''
echo '=== Public IP ==='
curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo 'Not available'
"@

ssh -i $PemKey "$Ec2User@$Ec2Host" $diagnosticCommands

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "1. Review the diagnostic output above" -ForegroundColor White
Write-Host "2. If application is not deployed:" -ForegroundColor White
Write-Host "   Run: .\deployment\transfer-to-ec2.ps1" -ForegroundColor Yellow
Write-Host ""
Write-Host "3. If services are not running, SSH and run:" -ForegroundColor White
Write-Host "   sudo systemctl start zencrow nginx" -ForegroundColor Yellow
Write-Host ""
Write-Host "4. Check AWS Security Group allows HTTP (port 80)" -ForegroundColor White
Write-Host "   Go to: AWS Console → EC2 → Instances → Security Group" -ForegroundColor Yellow
Write-Host ""
Write-Host "5. To connect manually:" -ForegroundColor White
Write-Host "   ssh -i `"$PemKey`" $Ec2User@$Ec2Host" -ForegroundColor Yellow
Write-Host ""

