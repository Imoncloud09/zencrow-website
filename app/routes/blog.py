from flask import Blueprint, render_template, request
from app.models import Post

bp = Blueprint('blog', __name__)

@bp.route('/')
def index():
    # Get search query from request parameters
    search_query = request.args.get('search', '').strip()
    
    # Query posts based on search
    if search_query:
        # Search in title and content (case-insensitive)
        posts = Post.query.filter(
            (Post.title.ilike(f'%{search_query}%')) |
            (Post.content.ilike(f'%{search_query}%'))
        ).order_by(Post.date_posted.desc()).all()
    else:
        # Get all posts if no search query
        posts = Post.query.order_by(Post.date_posted.desc()).all()
    
    return render_template('blog/index.html', posts=posts, search_query=search_query)
