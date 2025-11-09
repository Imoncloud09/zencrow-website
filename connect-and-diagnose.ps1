# Connect to EC2 and Run Diagnostics
# This script will connect to EC2 and run diagnostic checks

$PemKey = "D:\zenprod-new.pem"
$Ec2Host = "ec2-3-109-210-116.ap-south-1.compute.amazonaws.com"
$Ec2User = "ec2-user"
$AppDir = "/home/ec2-user/zencrow-website"

Write-Host "🔍 Connecting to EC2 and Running Diagnostics" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""

# Check if PEM key exists
if (-not (Test-Path $PemKey)) {
    Write-Host "❌ PEM key not found at: $PemKey" -ForegroundColor Red
    Write-Host "Please verify the PEM key location" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ PEM key found: $PemKey" -ForegroundColor Green
Write-Host ""

# Test SSH connection
Write-Host "🔌 Testing SSH connection..." -ForegroundColor Cyan
try {
    $testResult = ssh -i $PemKey -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$Ec2User@$Ec2Host" "echo 'Connection successful'" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ SSH connection successful" -ForegroundColor Green
    } else {
        Write-Host "❌ SSH connection failed" -ForegroundColor Red
        Write-Host $testResult
        exit 1
    }
} catch {
    Write-Host "❌ SSH connection error: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "📋 Running diagnostics on EC2..." -ForegroundColor Cyan
Write-Host ""

# Create diagnostic script on EC2
$diagnosticScript = @"
#!/bin/bash
echo "🔍 Zencrow Website Diagnostic Report"
echo "===================================="
echo ""
echo "📅 Date: $(date)"
echo "🖥️  Hostname: $(hostname)"
echo "👤 User: $(whoami)"
echo ""

# Check if application directory exists
APP_DIR="/home/ec2-user/zencrow-website"
echo "📁 Application Directory:"
if [ -d "\$APP_DIR" ]; then
    echo "   ✅ Directory exists: \$APP_DIR"
    cd \$APP_DIR
    echo "   📂 Files:"
    ls -la | head -10
else
    echo "   ❌ Directory NOT found: \$APP_DIR"
    echo "   💡 Application needs to be deployed!"
fi
echo ""

# Check Python
echo "🐍 Python Environment:"
if command -v python3 &> /dev/null; then
    echo "   ✅ Python 3: $(python3 --version 2>&1)"
else
    echo "   ❌ Python 3 not found"
fi
echo ""

# Check virtual environment
echo "🔧 Virtual Environment:"
if [ -d "\$APP_DIR/venv" ]; then
    echo "   ✅ venv directory exists"
    if [ -f "\$APP_DIR/venv/bin/activate" ]; then
        echo "   ✅ venv/bin/activate exists"
    else
        echo "   ❌ venv/bin/activate missing"
    fi
else
    echo "   ❌ venv directory missing"
fi
echo ""

# Check services
echo "🚀 Services Status:"
if sudo systemctl is-active --quiet zencrow 2>/dev/null; then
    echo "   ✅ zencrow service is RUNNING"
else
    echo "   ❌ zencrow service is NOT running"
fi

if sudo systemctl is-active --quiet nginx 2>/dev/null; then
    echo "   ✅ nginx service is RUNNING"
else
    echo "   ❌ nginx service is NOT running"
fi
echo ""

# Check ports
echo "🔌 Port Status:"
if netstat -tlnp 2>/dev/null | grep :8000 > /dev/null || ss -tlnp 2>/dev/null | grep :8000 > /dev/null; then
    echo "   ✅ Port 8000 (Gunicorn) is LISTENING"
else
    echo "   ❌ Port 8000 (Gunicorn) is NOT listening"
fi

if netstat -tlnp 2>/dev/null | grep :80 > /dev/null || ss -tlnp 2>/dev/null | grep :80 > /dev/null; then
    echo "   ✅ Port 80 (HTTP) is LISTENING"
else
    echo "   ❌ Port 80 (HTTP) is NOT listening"
fi
echo ""

# Check service logs (last 5 lines)
echo "📝 Recent Service Logs:"
echo "   Zencrow service:"
sudo journalctl -u zencrow -n 5 --no-pager 2>/dev/null | tail -3 || echo "   (No logs found)"
echo "   Nginx service:"
sudo systemctl status nginx --no-pager -l 2>/dev/null | head -5 || echo "   (Status unavailable)"
echo ""

# Check if application files exist
echo "📄 Application Files:"
if [ -f "\$APP_DIR/wsgi.py" ]; then
    echo "   ✅ wsgi.py exists"
else
    echo "   ❌ wsgi.py missing"
fi

if [ -f "\$APP_DIR/requirements.txt" ]; then
    echo "   ✅ requirements.txt exists"
else
    echo "   ❌ requirements.txt missing"
fi

if [ -f "\$APP_DIR/config.py" ]; then
    echo "   ✅ config.py exists"
else
    echo "   ❌ config.py missing"
fi
echo ""

# Get public IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "Not available")
echo "🌐 Public IP: \$PUBLIC_IP"
echo ""

# Summary
echo "===================================="
echo "📊 Diagnostic Summary:"
echo "===================================="
echo ""
echo "If you see errors above, common fixes:"
echo "1. If directory missing: Deploy application"
echo "2. If services not running: Start services"
echo "3. If ports not listening: Check service logs"
echo "4. If connection refused from browser: Check AWS Security Group"
echo ""
"@

# Run diagnostic script on EC2
ssh -i $PemKey "$Ec2User@$Ec2Host" "bash -s" << $diagnosticScript

Write-Host ""
Write-Host "✅ Diagnostics completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Review the diagnostic output above" -ForegroundColor White
Write-Host "2. If application is not deployed, run deployment script" -ForegroundColor White
Write-Host "3. If services are not running, start them" -ForegroundColor White
Write-Host "4. Check AWS Security Group allows HTTP (port 80)" -ForegroundColor White
Write-Host ""

