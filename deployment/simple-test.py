#!/usr/bin/env python3
"""
Simple test to isolate Flask app creation issues
"""

import sys
import os

# Add the project root directory to Python path
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, project_root)
print(f"Added to Python path: {project_root}")

print("🔍 Simple Flask App Test")
print("========================")

try:
    print("1. Testing basic Python...")
    print(f"Python version: {sys.version}")
    print(f"Current directory: {os.getcwd()}")
    
    print("\n2. Testing config import...")
    from config import Config
    print("✅ Config imported")
    
    print("\n3. Testing app import...")
    from app import create_app
    print("✅ create_app imported")
    
    print("\n4. Testing app creation...")
    app = create_app()
    print("✅ App created successfully")
    
    print("\n5. Testing app context...")
    with app.app_context():
        print("✅ App context works")
    
    print("\n🎉 All tests passed!")
    
except Exception as e:
    print(f"\n❌ Error: {e}")
    print(f"Error type: {type(e).__name__}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
