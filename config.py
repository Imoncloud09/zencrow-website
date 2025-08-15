import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    # Flask
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'dev-key-change-in-production'
    FLASK_ENV = os.environ.get('FLASK_ENV', 'development')
    DEBUG = os.environ.get('FLASK_ENV') == 'development'
    
    # Database
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL') or 'sqlite:///zencrow.db'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    
    # Mail settings
    MAIL_SERVER = os.environ.get('MAIL_SERVER', 'smtp.gmail.com')
    MAIL_PORT = int(os.environ.get('MAIL_PORT', 587))
    MAIL_USE_TLS = os.environ.get('MAIL_USE_TLS', True)
    MAIL_USERNAME = os.environ.get('MAIL_USERNAME')
    MAIL_PASSWORD = os.environ.get('MAIL_PASSWORD')
    
    # Production settings
    PREFERRED_URL_SCHEME = 'https' if os.environ.get('FLASK_ENV') == 'production' else 'http'
    
    # Security headers
    SECURE_HEADERS = {
        'STRICT_TRANSPORT_SECURITY': 'max-age=31536000; includeSubDomains',
        'X_CONTENT_TYPE_OPTIONS': 'nosniff',
        'X_FRAME_OPTIONS': 'SAMEORIGIN',
        'X_XSS_PROTECTION': '1; mode=block'
    }

class ProductionConfig(Config):
    FLASK_ENV = 'production'
    DEBUG = False
    
class DevelopmentConfig(Config):
    FLASK_ENV = 'development'
    DEBUG = True
    
class TestingConfig(Config):
    TESTING = True
    SQLALCHEMY_DATABASE_URI = 'sqlite:///:memory:'
    
config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'testing': TestingConfig,
    'default': DevelopmentConfig
}
