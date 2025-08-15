#!/bin/bash

# Python and Virtual Environment Setup Script
# Run this to fix Python and venv issues

set -e

echo "🐍 Setting up Python and Virtual Environment..."

# Check if we're in the right directory
if [ ! -f "requirements.txt" ]; then
    echo "❌ Error: requirements.txt not found. Please run this from the zencrow-website directory."
    exit 1
fi

# Install Python if not available
if ! command -v python3 &> /dev/null; then
    echo "📦 Installing Python 3..."
    sudo yum update -y
    sudo yum install python3 python3-pip python3-devel -y
else
    echo "✅ Python 3 is already installed"
fi

# Check Python version
PYTHON_VERSION=$(python3 --version 2>&1)
echo "🐍 Python version: $PYTHON_VERSION"

# Remove old venv if it exists
if [ -d "venv" ]; then
    echo "🗑️ Removing old virtual environment..."
    rm -rf venv
fi

# Create new virtual environment
echo "🔧 Creating new virtual environment..."
python3 -m venv venv

# Activate virtual environment
echo "🚀 Activating virtual environment..."
source venv/bin/activate

# Upgrade pip
echo "⬆️ Upgrading pip..."
pip install --upgrade pip

# Install requirements
echo "📚 Installing Python dependencies..."
pip install -r requirements.txt

# Test the setup
echo "🧪 Testing the setup..."
python deployment/test-app.py

echo "✅ Setup completed successfully!"
echo "🌐 You can now activate the virtual environment with: source venv/bin/activate"
echo "🚀 And test your app with: python deployment/test-app.py"
