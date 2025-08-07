from flask import Blueprint, render_template

bp = Blueprint('services', __name__)

@bp.route('/')
def index():
    services = [
        {
            'title': 'IT Support',
            'description': 'Expert IT solutions and support for your business needs.'
        },
        {
            'title': 'Web Development',
            'description': 'Custom web solutions using modern technologies.'
        },
        {
            'title': 'Tech Training',
            'description': 'Professional technology training and skill development.'
        },
        {
            'title': 'Foreign Language Learning',
            'description': 'Language courses tailored to your goals.'
        }
    ]
    return render_template('services/index.html', services=services)
