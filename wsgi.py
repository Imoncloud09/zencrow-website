#!/usr/bin/env python3
"""
WSGI entry point for Zencrow Website
This file is used by Gunicorn in production
"""

import os
from app import create_app

# Set environment to production
os.environ['FLASK_ENV'] = 'production'

# Create the Flask application
application = create_app()

if __name__ == "__main__":
    application.run()
