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
    mail.init_app(app)

    from app.routes import main, services, about, contact, blog
    app.register_blueprint(main.bp)
    app.register_blueprint(services.bp, url_prefix='/services')
    app.register_blueprint(about.bp, url_prefix='/about')
    app.register_blueprint(contact.bp, url_prefix='/contact')
    app.register_blueprint(blog.bp, url_prefix='/blog')

    with app.app_context():
        db.create_all()

    return app
