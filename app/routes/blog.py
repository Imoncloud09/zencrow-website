from flask import Blueprint, render_template
from app.models import Post

bp = Blueprint('blog', __name__)

@bp.route('/')
def index():
    posts = Post.query.order_by(Post.date_posted.desc()).all()
    return render_template('blog/index.html', posts=posts)
