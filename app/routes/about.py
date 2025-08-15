# Import necessary modules from Flask
from flask import Blueprint, render_template

# Create a Blueprint named 'about' to organize the 'About' section of the site
# '__name__' helps Flask locate resources related to this blueprint
bp = Blueprint('about', __name__)

# Define the route for the root URL of the 'about' section (e.g., /about/)
@bp.route('/')
def index():
    # Render and return the 'about/index.html' template when the route is accessed
    return render_template('about/index.html')
