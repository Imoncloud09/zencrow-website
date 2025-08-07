from flask import Blueprint, render_template, flash, redirect, url_for
from app.forms import ContactForm
from flask_mail import Message
from app import mail

bp = Blueprint('contact', __name__)

@bp.route('/', methods=['GET', 'POST'])
def index():
    form = ContactForm()
    if form.validate_on_submit():
        msg = Message(
            subject=form.subject.data,
            sender=form.email.data,
            recipients=['contact@zencrow.com']  # Replace with your email
        )
        msg.body = f"""
        From: {form.name.data}
        Email: {form.email.data}
        
        {form.message.data}
        """
        mail.send(msg)
        flash('Your message has been sent successfully!', 'success')
        return redirect(url_for('contact.index'))
    return render_template('contact/index.html', form=form)
