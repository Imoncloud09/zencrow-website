# Import necessary modules from Flask
from flask import Blueprint, render_template

# Create a Blueprint for the 'services' section of the site
# This helps in organizing routes into separate components
bp = Blueprint('services', __name__)

# Define the route for the services index page
@bp.route('/')
def index():
    # Create a list of dictionaries containing detailed service information
    services = [
        {
            'id': 'it-support',
            'title': 'IT Support & Solutions',
            'icon': 'bi-headset',
            'color': 'primary',
            'description': 'Comprehensive IT support and solutions tailored to your business needs.',
            'features': [
                '24/7 Technical Support',
                'Network Infrastructure Setup',
                'Cloud Migration Services',
                'Cybersecurity Solutions',
                'Hardware & Software Maintenance',
                'Data Backup & Recovery'
            ],
            'pricing': {
                'basic': {'price': '$299', 'period': 'month', 'features': ['Basic Support', 'Email Support', 'Remote Assistance']},
                'professional': {'price': '$599', 'period': 'month', 'features': ['Priority Support', 'Phone Support', 'On-site Visits', 'Proactive Monitoring']},
                'enterprise': {'price': 'Custom', 'period': '', 'features': ['Dedicated Team', 'Custom Solutions', 'SLA Guarantee', 'Strategic Consulting']}
            }
        },
        {
            'id': 'web-development',
            'title': 'Web Development',
            'icon': 'bi-code-slash',
            'color': 'success',
            'description': 'Custom web solutions and applications built with modern technologies and best practices.',
            'features': [
                'Custom Website Development',
                'E-commerce Solutions',
                'Web Application Development',
                'Mobile-Responsive Design',
                'API Development & Integration',
                'Performance Optimization'
            ],
            'pricing': {
                'basic': {'price': '$2,999', 'period': 'project', 'features': ['5 Pages', 'Responsive Design', 'Contact Form', 'Basic SEO']},
                'professional': {'price': '$5,999', 'period': 'project', 'features': ['10 Pages', 'CMS Integration', 'Advanced SEO', 'Analytics Setup']},
                'enterprise': {'price': 'Custom', 'period': '', 'features': ['Unlimited Pages', 'Custom Features', 'E-commerce', 'Advanced Integrations']}
            }
        },
        {
            'id': 'tech-training',
            'title': 'Tech Training',
            'icon': 'bi-mortarboard',
            'color': 'warning',
            'description': 'Professional development programs to enhance your team\'s technical skills and knowledge.',
            'features': [
                'Programming Languages Training',
                'Web Development Bootcamps',
                'Data Science & Analytics',
                'Cloud Computing Courses',
                'Cybersecurity Training',
                'Agile & DevOps Practices'
            ],
            'pricing': {
                'individual': {'price': '$299', 'period': 'course', 'features': ['Online Access', 'Course Materials', 'Certificate', 'Email Support']},
                'team': {'price': '$2,999', 'period': 'course', 'features': ['Up to 10 People', 'Live Sessions', 'Custom Content', 'Progress Tracking']},
                'corporate': {'price': 'Custom', 'period': '', 'features': ['Custom Curriculum', 'On-site Training', 'Ongoing Support', 'ROI Analysis']}
            }
        },
        {
            'id': 'language-learning',
            'title': 'Language Learning',
            'icon': 'bi-translate',
            'color': 'info',
            'description': 'Comprehensive language courses designed to expand your global communication capabilities.',
            'features': [
                'Multiple Language Options',
                'Interactive Learning Platform',
                'Native Speaker Instructors',
                'Business Language Focus',
                'Cultural Training',
                'Progress Assessment'
            ],
            'pricing': {
                'basic': {'price': '$99', 'period': 'month', 'features': ['1 Language', 'Basic Lessons', 'Mobile App', 'Email Support']},
                'premium': {'price': '$199', 'period': 'month', 'features': ['3 Languages', 'Live Sessions', 'Cultural Content', 'Priority Support']},
                'corporate': {'price': 'Custom', 'period': '', 'features': ['Custom Programs', 'Group Sessions', 'Business Focus', 'Progress Reports']}
            }
        }
    ]

    # Render the services/index.html template, passing the list of services
    return render_template('services/index.html', services=services)

