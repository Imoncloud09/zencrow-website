from flask import Blueprint, render_template, flash, redirect, url_for
from app.forms import ContactForm
from flask_mail import Message
from app import mail
import os

bp = Blueprint('contact', __name__)

@bp.route('/', methods=['GET', 'POST'])
def index():
    form = ContactForm()
    if form.validate_on_submit():
        # Build email body with all form fields
        email_body = f"""
        New Contact Form Submission from Zencrow Technologies Website
        
        ========================================
        CONTACT INFORMATION
        ========================================
        Name: {form.name.data}
        Email: {form.email.data}
        Subject: {form.subject.data}
        
        ========================================
        MESSAGE
        ========================================
        {form.message.data}
        """
        
        # Add service-specific fields if they were filled
        if form.language.data:
            email_body += f"""
        ========================================
        LANGUAGE LEARNING DETAILS
        ========================================
        Language of Interest: {form.language.data}
        """
        
        if form.proficiency_level.data:
            email_body += f"Proficiency Level: {form.proficiency_level.data}\n"
            
        if form.it_services.data:
            email_body += f"""
        ========================================
        IT SERVICES DETAILS
        ========================================
        IT Service Required: {form.it_services.data}
        """
            
        if form.web_development_services.data:
            email_body += f"""
        ========================================
        WEB DEVELOPMENT DETAILS
        ========================================
        Web Development Service: {form.web_development_services.data}
        """
            
        if form.tech_training_services.data:
            email_body += f"""
        ========================================
        TECH TRAINING DETAILS
        ========================================
        Tech Training Program: {form.tech_training_services.data}
        """
        
        email_body += """
        ========================================
        END OF MESSAGE
        ========================================
        
        This message was sent from the Zencrow Technologies contact form.
        """
        
        # Check if email configuration is set up
        mail_server = os.environ.get('MAIL_SERVER')
        mail_username = os.environ.get('MAIL_USERNAME')
        mail_password = os.environ.get('MAIL_PASSWORD')
        
        print(f"DEBUG: MAIL_SERVER = {mail_server}")
        print(f"DEBUG: MAIL_USERNAME = {mail_username}")
        print(f"DEBUG: MAIL_PASSWORD = {'*' * len(mail_password) if mail_password else 'NOT SET'}")
        
        if not all([mail_server, mail_username, mail_password]):
            flash('Email configuration is not set up. Please contact the administrator.', 'error')
            print("Email configuration missing: MAIL_SERVER, MAIL_USERNAME, or MAIL_PASSWORD not set")
            return redirect(url_for('contact.index'))
        
        # Check if using placeholder values
        if 'your-email@gmail.com' in mail_username or 'your-email-password' in mail_password:
            flash('Please configure your email credentials in the .env file.', 'error')
            print("Using placeholder email credentials - please update .env file")
            return redirect(url_for('contact.index'))
        
        # Always send from authenticated mailbox to avoid SPF/DMARC rejections
        default_sender = os.environ.get('MAIL_DEFAULT_SENDER') or mail_username

        # Determine recipients from environment variable (comma-separated)
        raw_recipients = os.environ.get('CONTACT_RECIPIENTS', 'hr@zencrowtechnologies.com')
        recipients = [r.strip() for r in raw_recipients.split(',') if r.strip()]

        msg = Message(
            subject=f"New Contact Form: {form.subject.data}",
            sender=default_sender,
            recipients=recipients,
            reply_to=form.email.data
        )
        msg.body = email_body
        
        try:
            mail.send(msg)
            flash('Your message has been sent successfully! We will get back to you soon.', 'success')
            print(f"Email sent successfully to hr@zencrowtechnologies.com from {form.email.data}")
        except Exception as e:
            error_msg = f"Email sending failed: {str(e)}"
            flash(f'Email Error: {str(e)}', 'error')
            print(error_msg)
            
        return redirect(url_for('contact.index'))
    return render_template('contact/index.html', form=form)
