import express from 'express';
import cors from 'cors';
import multer from 'multer';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';
import CryptoJS from 'crypto-js';
import fetch from 'node-fetch';

const app = express();
const PORT = process.env.PORT || 3000;
const SECRET_KEY = '65-a4fdy777nn98sns866by66554fdrfrtty';

// Get current directory in ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Service URLs from environment variables
const FLASK_API_URL = process.env.FLASK_API_URL || 'http://flask-backend:5000';
const NODE_API_URL = process.env.NODE_API_URL || 'http://node-backend:3000';

// Helper function to build API URLs
const buildUrl = (baseUrl, path) => `${baseUrl}${path}`;

// Create uploads directory if it doesn't exist
const uploadsPath = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsPath)) {
  fs.mkdirSync(uploadsPath);
}

// Basic middleware setup
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// CORS configuration
app.use(cors({
  origin: [
    'http://localhost:5173',          // Local development
    'http://localhost:3000',          // Local production build
    'https://web-production-9cffc.up.railway.app',
    'https://musiclibrarybyme.netlify.app', // Railway backend
    process.env.FRONTEND_URL || '*'   // Netlify URL (set this in Railway)
  ],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: function(req, file, cb) {
    cb(null, 'uploads');
  },
  filename: function(req, file, cb) {
    const uniqueName = `${Date.now()}-${file.originalname}`;
    cb(null, uniqueName);
  }
});

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 50 * 1024 * 1024 // 50MB limit
  },
  fileFilter: function(req, file, cb) {
    if (file.fieldname === "albumCover") {
      if (!file.mimetype.startsWith('image/')) {
        return cb(new Error('Only image files are allowed for album cover!'), false);
      }
    } else if (file.fieldname === "audioFile") {
      if (!file.mimetype.startsWith('audio/')) {
        return cb(new Error('Only audio files are allowed for song!'), false);
      }
    }
    cb(null, true);
  }
});

// Helper Functions
function decryptToken(token) {
  const bytes = CryptoJS.AES.decrypt(token, SECRET_KEY);
  return bytes.toString(CryptoJS.enc.Utf8);
}

// Helper function for making API calls to Flask backend
async function callFlaskApi(endpoint, data, fallbackEndpoint = null) {
  console.log(`Calling Flask API: ${endpoint}`, data);
    try {
    // Ensure endpoint starts with a slash
    const normalizedEndpoint = endpoint.startsWith('/') ? endpoint : `/${endpoint}`;
    const url = new URL(normalizedEndpoint, FLASK_API_URL).toString();
    
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(data)
    });

    if (!response.ok) {
      if (response.status === 404 && fallbackEndpoint) {
        return callFlaskApi(fallbackEndpoint, data);
      }
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    return await response.json();
  } catch (error) {
    console.error('API call error:', error);
    return { 
      success: false, 
      error: 'Connection error', 
      details: error.message || error.toString() 
    };
  }
}

// Authentication middleware
async function authenticateUser(req, res, next) {
  const token = req.headers.authorization?.split('Bearer ')[1] || req.query.token;
  
  if (!token) {
    return res.status(401).json({ error: 'Authentication required' });
  }

  try {    const email = decryptToken(token);
    const url = new URL('/getUserByEmail', FLASK_API_URL).toString();
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ email })
    });

    if (!response.ok) {
      throw new Error('Failed to authenticate user');
    }

    const user = await response.json();
    req.user = user;
    next();
  } catch (error) {
    console.error('Authentication error:', error);
    res.status(401).json({ error: 'Authentication failed' });
  }
}

// Admin authentication middleware
async function verifyAdminToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  if (!authHeader) {
    return res.status(401).json({ error: 'Admin authentication required' });
  }

  try {    const url = new URL('/verifyAdmin', FLASK_API_URL).toString();
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Authorization': authHeader
      }
    });

    if (!response.ok) {
      throw new Error('Failed to verify admin token');
    }

    next();
  } catch (err) {
    console.error('Admin verification error:', err);
    res.status(401).json({ error: 'Admin authentication failed' });
  }
}

// Static file serving - before API routes but after middleware
const staticPath = path.join(__dirname, '..', 'dist');
app.use(express.static(staticPath));
app.use('/uploads', express.static(uploadsPath));

// API Routes
app.post('/api/register', async (req, res) => {
  try {
    const response = await callFlaskApi('/register', req.body);
    res.status(200).json(response);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/verify-email', async (req, res) => {
  try {
    const response = await callFlaskApi('/verify-email', req.body);
    res.status(200).json(response);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/login', async (req, res) => {
  try {
    const response = await callFlaskApi('/login', req.body);
    res.status(200).json(response);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/verify-2fa', async (req, res) => {
  try {
    const response = await callFlaskApi('/verify-2fa', req.body);
    res.status(200).json(response);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/toggle-2fa', async (req, res) => {
  try {
    const response = await callFlaskApi('/toggle-2fa', req.body);
    res.status(200).json(response);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Profile routes
app.post('/api/update', authenticateUser, upload.single('avatar'), async (req, res) => {
  try {
    const userData = {
      ...req.body,
      avatar: req.file ? req.file.filename : undefined
    };
    const response = await callFlaskApi('/update-profile', userData);
    res.status(200).json(response);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/profile', authenticateUser, async (req, res) => {
  try {
    const user = req.user;
    const avatarUrl = user.avatar ? `${NODE_API_URL}/uploads/${user.avatar}` : null;
    res.status(200).json({
      user: {
        ...user,
        avatar: avatarUrl
      }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Song routes
app.get('/api/songs', async (req, res) => {
  try {
    const response = await callFlaskApi('/songs', req.query);
    res.status(200).json(response);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// More specific routes first
app.get('/api/songs/search/:query', async (req, res) => {
  try {
    const response = await callFlaskApi(`/songs/search/${req.params.query}`, {});
    if (!response.ok) {
      throw new Error('Error fetching songs from searchSongs API');
    }
    res.status(200).json(response);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/songs/details/:trackId', async (req, res) => {
  try {
    const response = await callFlaskApi(`/songs/details/${req.params.trackId}`, {});
    res.status(200).json(response);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Generic parameter route last
app.get('/api/songs/:songId', async (req, res) => {
  try {
    const response = await callFlaskApi(`/songs/${req.params.songId}`, {});
    res.status(200).json(response);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/songs/review', authenticateUser, async (req, res) => {
  try {
    const response = await callFlaskApi('/songs/review', req.body);
    res.status(200).json(response);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/songs/comment', authenticateUser, async (req, res) => {
  try {
    const response = await callFlaskApi('/songs/comment', req.body);
    res.status(200).json(response);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Liked songs routes
app.post('/api/songs/like', authenticateUser, async (req, res) => {
  try {
    const { email } = req.user;
    const { songId } = req.body;
    const response = await callFlaskApi('/songs/like', { userId: email, trackId: songId });
    res.status(200).json(response);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/songs/liked', authenticateUser, async (req, res) => {
  try {
    const response = await callFlaskApi('/songs/liked', req.body);
    res.status(200).json(response);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Admin routes
app.post('/api/admin/login', async (req, res) => {
  try {
    const response = await callFlaskApi('/admin/login', req.body);
    res.status(200).json(response);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/mostCommonGenre/:rating', async (req, res) => {
  try {
    const response = await callFlaskApi(`/mostCommonGenre/${req.params.rating}`, {});
    res.status(200).json(response);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/monitoredUsers', verifyAdminToken, async (req, res) => {
  try {
    const response = await callFlaskApi('/monitoredUsers', {});
    res.status(200).json(response);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.delete('/api/songs/delete/:songId', verifyAdminToken, async (req, res) => {
  try {
    const response = await callFlaskApi(`/songs/delete/${req.params.songId}`, {});
    res.status(200).json(response);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// SPA support - this should be the last route
app.get('*', (req, res, next) => {
  // Skip API routes
  if (req.url.startsWith('/api')) {
    return next();
  }
  const indexPath = path.join(staticPath, 'index.html');
  console.log('Serving index.html from:', indexPath);
  if (fs.existsSync(indexPath)) {
    res.sendFile(indexPath);
  } else {
    console.log('index.html not found at:', indexPath);
    res.status(404).send('Frontend files not found. Make sure to build the frontend first.');
  }
});

// Start the server
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});