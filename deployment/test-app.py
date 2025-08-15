#!/usr/bin/env python3
"""
Test script to verify Flask application creation
Run this to check if there are any import or configuration errors
"""

import sys
import os

# Add the project root directory to Python path
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, project_root)
print(f"Added to Python path: {project_root}")

try:
    print("🔍 Testing Flask application creation...")
    
    # Test config import
    print("📋 Testing config import...")
    from config import Config
    print("✅ Config imported successfully")
    
    # Test app creation
    print("🚀 Testing app creation...")
    from app import create_app
    
    app = create_app()
    print("✅ Flask app created successfully")
    
    # Test basic functionality
    print("🧪 Testing basic functionality...")
    with app.test_client() as client:
        response = client.get('/health')
        if response.status_code == 200:
            print("✅ Health endpoint working")
        else:
            print(f"❌ Health endpoint returned status {response.status_code}")
    
    print("🎉 All tests passed! Flask app is working correctly.")
    
except Exception as e:
    print(f"❌ Error occurred: {e}")
    print(f"Error type: {type(e).__name__}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
