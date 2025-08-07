const express = require('express');
const app = express();
const path = require('path');

// Set view engine to EJS
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Static files
app.use(express.static(path.join(__dirname, 'public')));

// Routes
// Update your routes to include title
app.get('/', (req, res) => res.render('index', { title: 'Home - Zencrow Technologies' }));
app.get('/services', (req, res) => res.render('services', { title: 'Services - Zencrow Technologies' }));
app.get('/contact', (req, res) => res.render('contact', { title: 'Contact - Zencrow Technologies' }));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));