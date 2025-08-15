#!/usr/bin/env python3
"""
Minimal Gunicorn test to isolate startup issues
"""

import sys
import os

# Add current directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

try:
    print("🔍 Testing minimal Gunicorn startup...")
    
    # Test basic imports
    from flask import Flask
    
    # Create minimal app
    app = Flask(__name__)
    
    @app.route('/test')
    def test():
        return 'Hello from minimal app!'
    
    print("✅ Minimal Flask app created")
    
    # Test if it can be imported by Gunicorn
    if __name__ == '__main__':
        app.run(debug=True, host='127.0.0.1', port=8000)
    
    print("✅ App ready for Gunicorn")
    
except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
