from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_mail import Mail
from config import Config

db = SQLAlchemy()
mail = Mail()

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    db.init_app(app)
    
    # Initialize mail only if configuration is provided
    if app.config.get('MAIL_USERNAME') and app.config.get('MAIL_PASSWORD'):
        mail.init_app(app)
        app.logger.info("Email functionality enabled")
    else:
        app.logger.warning("Email configuration not set up. Email functionality disabled.")
        # Create a mock mail object for routes that expect it
        app.mail = None

    from app.routes import main, services, about, contact, blog
    app.register_blueprint(main.bp)
    app.register_blueprint(services.bp, url_prefix='/services')
    app.register_blueprint(about.bp, url_prefix='/about')
    app.register_blueprint(contact.bp, url_prefix='/contact')
    app.register_blueprint(blog.bp, url_prefix='/blog')

    with app.app_context():
        db.create_all()

    return app
