import express from 'express';
import bcrypt from 'bcrypt';
import cors from 'cors';
import CryptoJS from 'crypto-js';
import fetch from 'node-fetch';
import jwt from 'jsonwebtoken';
import { use } from 'react';
import multer from 'multer';
import path from 'path';
import fs from 'fs';

const app = express();
const PORT = process.env.PORT || 3000;
const SECRET_KEY = '65-a4fdy777nn98sns866by66554fdrfrtty';

app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));
app.use(cors({
  origin: '*', // Allow all origins for development
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Create uploads directory if it doesn't exist
if (!fs.existsSync('uploads')) {
  fs.mkdirSync('uploads');
}

// Ensure the /uploads directory is served correctly
app.use('/uploads', express.static('uploads'));

// Configure multer for file uploads
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, 'uploads');
    },
    filename: (req, file, cb) => {
        const uniqueName = `${Date.now()}-${file.originalname}`;
        cb(null, uniqueName);
    }
});
const upload = multer({
    storage: storage,
    limits: {
        fileSize: 50 * 1024 * 1024 // 50MB limit
    },
    fileFilter: (req, file, cb) => {
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

const decryptToken = (token) => {
  const bytes = CryptoJS.AES.decrypt(token, SECRET_KEY);
  return bytes.toString(CryptoJS.enc.Utf8);
};

// Helper function for making API calls to Flask backend
const callFlaskApi = async (endpoint, data, fallbackEndpoint = null) => {
  console.log(`Calling Flask API: ${endpoint}`, data);
  
  try {
    // Try the primary endpoint
    let response = await fetch(`http://localhost:5000${endpoint}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    });
    
    // If first endpoint fails with a 404 and we have a fallback, try it
    if (response.status === 404 && fallbackEndpoint) {
      console.log(`Primary endpoint ${endpoint} returned 404, trying fallback: ${fallbackEndpoint}`);
      response = await fetch(`http://localhost:5000${fallbackEndpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
      });
    }
    
    // Handle unsuccessful responses
    if (!response.ok) {
      console.error(`API error: ${response.status}`);
      
      // Try to parse error content
      let errorContent;
      const contentType = response.headers.get('content-type');
      
      if (contentType && contentType.includes('application/json')) {
        try {
          errorContent = await response.json();
        } catch (e) {
          errorContent = await response.text();
        }
      } else {
        errorContent = await response.text();
      }
      
      // Check if we got HTML instead of proper JSON (indicates server error)
      if (typeof errorContent === 'string' && 
          (errorContent.includes('<!DOCTYPE') || errorContent.includes('<html'))) {
        console.error('Received HTML response instead of JSON from Flask');
        return {
          success: false,
          status: response.status,
          error: 'Flask server error',
          details: 'Communication with backend server failed. Please check if Flask is running.'
        };
      }
      
      return { 
        success: false,
        status: response.status,
        error: 'Backend error',
        details: typeof errorContent === 'string' ? 
          errorContent.substring(0, 200) : 
          JSON.stringify(errorContent)
      };
    }
    
    // Handle successful responses
    try {
      const contentType = response.headers.get('content-type');
      if (contentType && contentType.includes('application/json')) {
        const data = await response.json();
        return { success: true, data };
      } else {
        const text = await response.text();
        
        // Check if we got HTML when we expected JSON
        if (text.includes('<!DOCTYPE') || text.includes('<html')) {
          console.error('Received HTML response instead of JSON from Flask');
          return {
            success: false,
            error: 'Flask server error',
            details: 'Communication with backend server failed. Please check if Flask is running.'
          };
        }
        
        console.warn('Expected JSON response but got text:', text.substring(0, 100));
        return { 
          success: true, 
          data: { message: "Operation successful" } 
        };
      }
    } catch (jsonError) {
      console.error('Failed to parse JSON from Flask API:', jsonError);
      return { 
        success: true, 
        data: { message: "Operation completed successfully" } 
      };
    }
  } catch (error) {
    console.error('API call error:', error);
    return { 
      success: false, 
      error: 'Connection error', 
      details: error.message || error.toString() 
    };
  }
};

// REGISTER
app.post('/api/register', async (req, res) => {
  const { username, email, password } = req.body;
  if (!username || !email || !password)
    return res.status(400).json({ error: 'All fields required' });

  try {
    const checkRes = await fetch('http://localhost:5000/getUserByEmail', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email })
    });
    const user = await checkRes.json();
    if (user?.email)
      return res.status(400).json({ error: 'Email already registered' });

    const hashed = await bcrypt.hash(password, 10);
    const registerResponse = await fetch('http://localhost:5000/registerUser', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        username,
        email,
        password: hashed,
        favoriteGenre: '',
        favoriteArtist: '',
        bio: '',
        avatar: null
      })
    });

    const result = await registerResponse.json();
    if (registerResponse.ok) {
      // Generate token for the user
      const token = CryptoJS.AES.encrypt(email, SECRET_KEY).toString();
      res.status(201).json({
        message: 'Registration successful. Please check your email for verification code.',
        token: token,
        email: email
      });
    } else {
      res.status(registerResponse.status).json(result);
    }
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal error' });
  }
});

// Verify Email
app.post('/api/verify-email', async (req, res) => {
  const { email, code } = req.body;
  
  try {
    const response = await fetch('http://localhost:5000/verify-email', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, code })
    });

    const result = await response.json();
    if (response.ok) {
      const token = CryptoJS.AES.encrypt(email, SECRET_KEY).toString();
      res.status(200).json({
        message: 'Email verified successfully',
        token,
        email
      });
    } else {
      res.status(response.status).json(result);
    }
  } catch (err) {
    console.error('Email verification error:', err);
    res.status(500).json({ error: 'Internal error' });
  }
});

// LOGIN
app.post('/api/login', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password)
    return res.status(400).json({ error: 'All fields required' });

  try {
    const response = await fetch('http://localhost:5000/getUserByEmail', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email })
    });
    const user = await response.json();
    if (!user || !(await bcrypt.compare(password, user.password)))
      return res.status(400).json({ error: 'Invalid credentials' });

    // Check if email is verified
    if (!user.email_verified) {
      // Resend verification code
      const registerResponse = await fetch('http://localhost:5000/registerUser', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          username: user.username,
          email: user.email,
          password: user.password,  // Already hashed
          favoriteGenre: user.favorite_genre,
          favoriteArtist: user.favorite_artist,
          bio: user.bio,
          avatar: user.avatar
        })
      });

      return res.status(403).json({ 
        error: 'Please verify your email first',
        needsVerification: true,
        email: email
      });
    }

    // If email is verified, proceed with normal login
    const token = CryptoJS.AES.encrypt(email, SECRET_KEY).toString();
    res.status(200).json({
      message: 'Login successful',
      token,
      user: {
        username: user.username,
        email: user.email,
        favoriteGenre: user.favorite_genre,
        favoriteArtist: user.favorite_artist,
        bio: user.bio,
        avatar: user.avatar
      }
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal error' });
  }
});

// Verify 2FA code
app.post('/api/verify-2fa', async (req, res) => {
  const { tempToken, code } = req.body;
  
  try {
    const email = decryptToken(tempToken);
    if (!email) {
      return res.status(400).json({ error: 'Invalid token' });
    }

    const verify2FAResponse = await fetch('http://localhost:5000/verify-2fa', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, code })
    });

    if (!verify2FAResponse.ok) {
      const error = await verify2FAResponse.json();
      return res.status(400).json(error);
    }

    // Get user data after successful 2FA
    const userResponse = await fetch('http://localhost:5000/getUserByEmail', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email })
    });
    const user = await userResponse.json();

    // Generate final token
    const token = CryptoJS.AES.encrypt(email, SECRET_KEY).toString();
    
    res.status(200).json({
      message: 'Login successful',
      token,
      user: {
        username: user.username,
        email: user.email,
        favoriteGenre: user.favorite_genre,
        favoriteArtist: user.favorite_artist,
        bio: user.bio,
        avatar: user.avatar,
        twoFactorEnabled: user.two_factor_enabled
      }
    });
  } catch (err) {
    console.error('2FA verification error:', err);
    res.status(500).json({ error: 'Internal error' });
  }
});

// Enable/Disable 2FA
app.post('/api/toggle-2fa', async (req, res) => {
  const { token, enable } = req.body;
  
  try {
    const email = decryptToken(token);
    if (!email) {
      return res.status(400).json({ error: 'Invalid token' });
    }

    const endpoint = enable ? '/enable-2fa' : '/disable-2fa';
    const response = await fetch(`http://localhost:5000${endpoint}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email })
    });

    if (!response.ok) {
      const error = await response.json();
      return res.status(400).json(error);
    }

    const result = await response.json();
    res.status(200).json(result);
  } catch (err) {
    console.error('Toggle 2FA error:', err);
    res.status(500).json({ error: 'Internal error' });
  }
});

// Authentication middleware
const authenticateUser = async (req, res, next) => {
  const token = req.headers.authorization?.split('Bearer ')[1] || req.query.token;
  
  if (!token) {
    return res.status(401).json({ error: 'Authentication required' });
  }

  try {
    const email = CryptoJS.AES.decrypt(token, SECRET_KEY).toString(CryptoJS.enc.Utf8);
    
    if (!email) {
      return res.status(401).json({ error: 'Invalid token format' });
    }

    const response = await fetch('http://localhost:5000/getUserByEmail', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email })
    });

    const user = await response.json();
    
    if (!user || !user.email) {
      return res.status(401).json({ error: 'User not found' });
    }

    if (!user.email_verified) {
      return res.status(403).json({ 
        error: 'Email not verified',
        needsVerification: true,
        email: email
      });
    }

    console.log('authenticateUser middleware triggered');

    // Add user info to request object
    req.user = {
      email: user.email,
      username: user.username,
      id: user.id
    };
    
    next();
  } catch (error) {
    console.error('Authentication error:', error);
    res.status(401).json({ error: 'Authentication failed' });
  }
};

// UPDATE PROFILE
app.post('/api/update', authenticateUser, upload.single('avatar'), async (req, res) => {
  const { username, favoriteGenre, favoriteArtist, bio } = req.body;
  const avatar = req.file ? req.file.filename : null;

  try {
    const email = req.user.email;
    const resUser = await fetch('http://localhost:5000/getUserByEmail', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email })
    });
    
    const user = await resUser.json();
    if (!user) return res.status(404).json({ error: 'User not found' });

    const updateResponse = await fetch('http://localhost:5000/updateUserProfile', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        username: username || user.username,
        email: user.email,
        password: user.password,
        favoriteGenre: favoriteGenre || user.favorite_genre,
        favoriteArtist: favoriteArtist || user.favorite_artist,
        bio: bio || user.bio,
        avatar: avatar || user.avatar
      })
    });

    if (!updateResponse.ok) {
      throw new Error('Failed to update profile');
    }

    // Generate a new token with updated data
    const token = CryptoJS.AES.encrypt(email, SECRET_KEY).toString();

    // Convert avatar filename to full URL if it exists
    const avatarUrl = (avatar || user.avatar) ? `http://localhost:3000/uploads/${avatar || user.avatar}` : null;

    res.status(200).json({
      message: 'Profile updated successfully',
      token: token,
      user: {
        username: username || user.username,
        email: user.email,
        favoriteGenre: favoriteGenre || user.favorite_genre,
        favoriteArtist: favoriteArtist || user.favorite_artist,
        bio: bio || user.bio,
        avatar: avatarUrl
      }
    });
  } catch (err) {
    console.error('Error updating profile:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/api/songs', async (req, res) => {
    const offset = parseInt(req.query.offset, 10) || 0;
    const limit = parseInt(req.query.limit, 10) || 30;
    const sortBy = req.query.sortBy;
    const order = req.query.order;

    try {
        const response = await fetch('http://localhost:5000/getAllSongs');
        const allSongs = await response.json();

        if (!response.ok) {
            console.error('Error fetching songs from backend:', response.statusText);
            return res.status(response.status).json({ error: 'Failed to fetch songs' });
        }

        // Sort the songs if sortBy is specified
        if (sortBy) {
            allSongs.sort((a, b) => {
                let aValue = a[sortBy];
                let bValue = b[sortBy];
                
                // Handle special cases for different field names
                if (sortBy === 'title') {
                    aValue = a.track_name;
                    bValue = b.track_name;
                } else if (sortBy === 'artist') {
                    aValue = a.artist_name;
                    bValue = b.artist_name;
                } else if (sortBy === 'album') {
                    aValue = a.album_name;
                    bValue = b.album_name;
                }

                // Convert to strings for comparison
                aValue = String(aValue).toLowerCase();
                bValue = String(bValue).toLowerCase();

                if (order === 'desc') {
                    return bValue.localeCompare(aValue);
                }
                return aValue.localeCompare(bValue);
            });
        }        // Apply pagination after sorting
        const paginatedSongs = allSongs.slice(offset, offset + limit);
        console.log(`Returning ${paginatedSongs.length} songs from offset ${offset}`);

        // Update image URLs for local files
        paginatedSongs.forEach(song => {
          if (song.album_image && song.album_image.startsWith('/uploads/')) {
            song.album_image = `http://localhost:3000${song.album_image}`;
          }
        });
        
        res.status(200).json(paginatedSongs);
    } catch (err) {
        console.error('Error fetching songs:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});
// GET SONG BY ID
app.get('/api/songs/:id', async (req, res) => {
  const { id } = req.params;  try {
    const response = await fetch(`http://localhost:5000/getSongById/${id}`);
    const song = await response.json();
    if (!song) return res.status(404).json({ error: 'Song not found' });
    
    // Update image URL if it's a local file
    if (song.album_image && song.album_image.startsWith('/uploads/')) {
      song.album_image = `http://localhost:3000${song.album_image}`;
    }
    
    res.status(200).json(song);
  } catch (err) {
    res.status(500).json({ error: 'Internal error' });
  }
});

// GET USER PROFILE
app.get('/api/profile', authenticateUser, async (req, res) => {
  try {
    const response = await fetch('http://localhost:5000/getUserByEmail', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: req.user.email })
    });

    if (!response.ok) {
      throw new Error('Failed to fetch user profile');
    }

    const user = await response.json();
    
    // Convert avatar filename to full URL if it exists
    const avatarUrl = user.avatar ? `http://localhost:3000/uploads/${user.avatar}` : null;
    
    res.json({
      username: user.username,
      email: user.email,
      favoriteGenre: user.favorite_genre,
      favoriteArtist: user.favorite_artist,
      bio: user.bio,
      avatar: avatarUrl
    });
  } catch (error) {
    console.error('Error fetching profile:', error);
    res.status(500).json({ error: 'Failed to fetch profile' });
  }
});

app.get('/api/songs/search/:query', async (req, res) => {
  const { query } = req.params; // Extract the query param correctly
  console.log("Query received:", query);

  if (!query || query.trim() === "") {
    return res.status(400).json({ error: 'Query parameter is required' });
  }

  try {
    const response = await fetch(`http://localhost:5000/api/searchSongs/${query}`);
    if (!response.ok) {
      console.error("Failed to fetch from searchSongs API:", response.statusText);
      return res.status(500).json({ error: 'Error fetching songs from searchSongs API' });
    }
    
    const songs = await response.json();
    if (!Array.isArray(songs)) {
      console.error("Unexpected response format:", songs);
      return res.status(500).json({ error: 'Invalid response format from searchSongs API' });
    }

    res.status(200).json(songs);
  } catch (err) {
    console.error("Error in /api/songs/search:", err);
    res.status(500).json({ error: 'Internal error during search' });
  }
});

app.post('/api/songs/review', async (req, res) => {
  try {
    // Get token from request
    const token = req.headers.authorization?.split(' ')[1] || req.body.token;
    if (!token) {
      return res.status(401).json({ error: 'No token provided' });
    }
    
    const songId = req.body.songId;
    const comment = req.body.comment || "";
    const rating = req.body.rating || 0;
    
    if (!songId) {
      return res.status(400).json({ error: 'Song ID is required' });
    }
    
    // Get email from token
    let email;
    try {
      email = decryptToken(token);
      if (!email) {
        return res.status(401).json({ error: 'Invalid token' });
      }
    } catch (err) {
      return res.status(401).json({ error: 'Invalid token format' });
    }
    
    console.log(`Adding review for song ${songId} by user ${email}`);
    
    // Simple direct call to Flask - we'll just use /api/addReview
    const response = await fetch('http://localhost:5000/api/addReview', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
      body: JSON.stringify({
        userId: email,
        trackId: songId,
        comment: comment,
        rating: rating
      })
    });
    
    // Handle response - first check if it's OK
    if (!response.ok) {
      console.error(`Error response from Flask API: ${response.status}`);
      let errorMessage = 'Failed to submit review';
      
      try {
        // Try to get error details as JSON
        const errorData = await response.json();
        errorMessage = errorData.error || errorMessage;
      } catch (e) {
        // If JSON parsing fails, try as text
        try {
          const errorText = await response.text();
          // Check if it's HTML (likely an error page)
          if (errorText.includes('<!DOCTYPE') || errorText.includes('<html')) {
            console.error('Received HTML instead of JSON response');
            errorMessage = 'Server error - received HTML instead of JSON';
          } else {
            errorMessage = errorText || errorMessage;
          }
        } catch (textError) {
          // If all else fails, use the status text
          errorMessage = response.statusText || errorMessage;
        }
      }
      
      return res.status(response.status || 500).json({ error: errorMessage });
    }
    
    // Success path - return a simple success message
    return res.status(200).json({ message: "Review submitted successfully" });
  } catch (error) {
    console.error('Error in review endpoint:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

// Find the /api/songs/comment route and update it
app.post('/api/songs/comment', async (req, res) => {
  try {
    // Get token from authorization header (preferred) or body
    const token = req.headers.authorization?.split(' ')[1] || req.body.token;
    if (!token) {
      console.log('No token provided');
      return res.status(401).json({ error: 'No token provided' });
    }
    
    const songId = req.body.songId;
    const comment = req.body.comment;
    
    if (!songId) {
      return res.status(400).json({ error: 'Song ID is required' });
    }
    
    if (!comment || !comment.trim()) {
      return res.status(400).json({ error: 'Comment text is required' });
    }
    
    console.log(`Adding comment for song ${songId}, comment: ${comment}`);
    
    // Decrypt token to get email
    let email;
    try {
      email = decryptToken(token);
      if (!email) {
        console.error('Failed to decrypt token - returned empty email');
        return res.status(401).json({ error: 'Invalid token - could not extract email' });
      }
    } catch (decryptError) {
      console.error('Error decrypting token:', decryptError);
      return res.status(401).json({ error: 'Invalid token format' });
    }
    
    console.log('Using email from token:', email);
    
    // Simple direct call to Flask - we'll just use /api/addComment
    const response = await fetch('http://localhost:5000/api/addComment', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        userId: email,
        trackId: songId,
        comment: comment
      })
    });
    
    // Handle response - first check if it's OK
    if (!response.ok) {
      console.error(`Error response from Flask API: ${response.status}`);
      let errorMessage = 'Failed to submit comment';
      
      try {
        // Try to get error details as JSON
        const errorData = await response.json();
        errorMessage = errorData.error || errorMessage;
      } catch (e) {
        // If JSON parsing fails, try as text
        try {
          const errorText = await response.text();
          // Check if it's HTML (likely an error page)
          if (errorText.includes('<!DOCTYPE') || errorText.includes('<html')) {
            console.error('Received HTML instead of JSON response');
            errorMessage = 'Server error - received HTML instead of JSON';
          } else {
            errorMessage = errorText || errorMessage;
          }
        } catch (textError) {
          // If all else fails, use the status text
          errorMessage = response.statusText || errorMessage;
        }
      }
      
      return res.status(response.status || 500).json({ error: errorMessage });
    }
    
    // Success path - return a simple success message
    return res.status(200).json({ message: "Comment submitted successfully" });
  } catch (error) {
    console.error('Error in comment endpoint:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/api/songs/details/:trackId', async (req, res) => {
  const { trackId } = req.params;

  try {
    const response = await fetch(`http://localhost:5000/api/getSongDetails/${trackId}`);
    if (!response.ok) {
      const error = await response.json();
      return res.status(response.status).json(error);
    }

    const data = await response.json();
    res.status(200).json(data);
  } catch (err) {
    console.error('Error fetching song details:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Add to liked songs
app.post('/api/songs/like', authenticateUser, async (req, res) => {
  const { songId } = req.body;
  const email = req.user.email;

  try {
    const response = await fetch('http://localhost:5000/api/addToLiked', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ userId: email, trackId: songId }),
    });

    if (!response.ok) {
      const error = await response.json();
      return res.status(response.status).json(error);
    }

    res.status(200).json({ message: 'Song added to liked list successfully' });
  } catch (err) {
    console.error('Error adding to liked list:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get liked songs
app.post('/api/songs/liked', async (req, res) => {
  try {
    const token = req.headers.authorization?.split('Bearer ')[1] || req.body?.token;
    
    if (!token) {
      return res.status(401).json({ error: 'Authentication required' });
    }
    
    // Use the established decryptToken function
    const email = decryptToken(token);
    console.log('Request received at /api/songs/liked (POST):', email);
    if (!email) {
      console.log('No email found in decrypted token');
      return res.status(401).json({ error: 'Unauthorized' });
    }
    
    console.log(`Fetching liked songs for email: ${email}`);

    const response = await fetch('http://localhost:5000/api/getLikedSongs', {
      method: 'POST', // Flask endpoint expects POST
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email }), // Send email in the request body
    });    console.log(`Flask response status: ${response.status}`);
    
    if (!response.ok) {
      const errorText = await response.text();
      console.error('Error response from Flask:', errorText);
      return res.status(response.status).json({ error: 'Failed to fetch liked songs' });
    }

    try {
      const data = await response.json();
      console.log(`Successfully received ${Array.isArray(data) ? data.length : 0} liked songs from Flask`);
      return res.status(200).json(data);
    } catch (parseError) {
      console.error('Error parsing JSON response:', parseError);
      const responseText = await response.text();
      console.error('Raw response:', responseText);
      return res.status(500).json({ error: 'Invalid response format from Flask service' });
    }
  } catch (error) {
    console.error('Error fetching liked songs:', error);
    return res.status(500).json({ error: 'Internal server error', details: error.message });
  }
});
;

//AdminLogin
app.post('/api/admin/login', async (req, res) => {
  const { email, password } = req.body;

  // Validate input fields
  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password are required' });
  }

  console.log('Request received at /api/admin/login:', req.body);

  try {
    // Forward login request to Flask server
    const response = await fetch('http://localhost:5000/api/admin/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password })
    });

    // Check if the response is ok
    console.log('Response status:', response.status);

    if (!response.ok) {
      return res.status(404).json({ error: 'Admin not found' });
    }    const adminData = await response.json();
    
    // The Flask backend already validated the password, so we can just pass through its response
    res.status(200).json(adminData);
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Middleware to check admin token
const verifyAdminToken = async (req, res, next) => {
  const authHeader = req.headers['authorization'];
  if (!authHeader) {
    return res.status(401).json({ error: 'No token provided' });
  }

  try {
    // Forward the token to the Flask backend
    const response = await fetch('http://localhost:5000/api/admin/verify', {
      method: 'GET',
      headers: {
        'Authorization': authHeader
      }
    });

    if (!response.ok) {
      const error = await response.json();
      return res.status(response.status).json(error);
    }

    next();
  } catch (err) {
    console.error('Error verifying admin token:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Endpoint to get the most common genre based on rating range
app.get('/api/mostCommonGenre/:rating', async (req, res) => {
  const { rating } = req.params;

  try {
    const response = await fetch(`http://localhost:5000/api/mostCommonGenre/${rating}`);
    if (!response.ok) {
      const error = await response.json();
      return res.status(response.status).json(error);
    }

    const data = await response.json();
    res.status(200).json(data);
  } catch (err) {
    console.error('Error fetching most common genre:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

//end point to get monitored users
app.get('/api/monitoredUsers', async (req, res) => {
  try {
    const response = await fetch('http://localhost:5000/api/getMonitoredUsers');
    if (!response.ok) {
      const error = await response.json();
      return res.status(response.status).json(error);
    }

    const data = await response.json();
    res.status(200).json(data);
  } catch (err) {
    console.error('Error fetching monitored users:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

//Endpoint to delete a song
app.delete('/api/songs/delete/:songId', verifyAdminToken, async (req, res) => {
  const { songId } = req.params;

  try {
    // First get the song details to get the file paths
    const songResponse = await fetch(`http://localhost:5000/getSongById/${songId}`);
    const song = await songResponse.json();
    
    if (!song) {
      return res.status(404).json({ error: 'Song not found' });
    }

    // Delete the song from the database first
    const response = await fetch(`http://localhost:5000/api/songs/delete/${songId}`, {
      method: 'DELETE',
      headers: { 'Content-Type': 'application/json' }
    });

    if (!response.ok) {
      const error = await response.json();
      return res.status(response.status).json(error);
    }

    // If database deletion was successful, clean up files
    try {
      // Clean up album cover if it's a local file
      if (song.album_image?.includes('/uploads/')) {
        const filePath = song.album_image.split('/uploads/')[1];
        const fullPath = path.join('uploads', filePath);
        if (fs.existsSync(fullPath)) {
          fs.unlinkSync(fullPath);
        }
      }

      // Clean up audio file if it's a local file
      if (song.audio_url?.includes('/uploads/')) {
        const filePath = song.audio_url.split('/uploads/')[1];
        const fullPath = path.join('uploads', filePath);
        if (fs.existsSync(fullPath)) {
          fs.unlinkSync(fullPath);
        }
      }
    } catch (cleanupError) {
      console.error('Error cleaning up files:', cleanupError);
      // Don't fail the request if file cleanup fails
    }

    res.status(200).json({ message: 'Song deleted successfully' });
  } catch (err) {
    console.error('Error deleting song:', err);
    res.status(500).json({ error: 'Internal server error' });
  }

});

// Endpoint to add a new song with file upload support
app.post('/api/addSong', upload.fields([
  { name: 'audioFile', maxCount: 1 },
  { name: 'albumCover', maxCount: 1 }
]), async (req, res) => {
  try {
    const { trackName, artistName, albumName, rating, genres } = req.body;
    const files = req.files;

    if (!files?.albumCover || !files?.audioFile) {
      return res.status(400).json({ error: 'Both album cover and audio file are required' });
    }    // Generate URLs for uploaded files with server URL prefix
    const audioUrl = `http://localhost:3000/uploads/${files.audioFile[0].filename}`;
    const albumImage = `http://localhost:3000/uploads/${files.albumCover[0].filename}`;

    const response = await fetch('http://localhost:5000/api/spngs/add', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        trackName,
        artistName,
        albumName,
        albumImage,
        rating,
        genres,
        audioUrl
      })
    });

    if (!response.ok) {
      // If backend fails, clean up uploaded files
      fs.unlinkSync(`uploads/${files.audioFile[0].filename}`);
      fs.unlinkSync(`uploads/${files.albumCover[0].filename}`);
      const error = await response.json();
      return res.status(response.status).json(error);
    }

    res.status(200).json({ message: 'Song added successfully' });
  } catch (err) {
    // Clean up any uploaded files in case of error
    if (req.files) {
      Object.values(req.files).forEach(fileArray => {
        fileArray.forEach(file => {
          if (fs.existsSync(file.path)) {
            fs.unlinkSync(file.path);
          }
        });
      });
    }
    console.error('Error adding song:', err);
    res.status(500).json({ error: err.message || 'Internal server error' });
  }
});

// Endpoint to update a song
app.put('/api/songs/update/:songId', upload.fields([
  { name: 'audioFile', maxCount: 1 },
  { name: 'albumCover', maxCount: 1 }
]), async (req, res) => {
  console.log('Update song request received for songId:', req.params.songId);
  console.log('Request body:', req.body);
  console.log('Files:', req.files);

  const { songId } = req.params;
  const { trackName, artistName, albumName, genres } = req.body;
  const files = req.files;

  try {
    // Build update data
    const updateData = {
      trackName,
      artistName,
      albumName,
      genres,
    };
    if (files?.albumCover) {
      updateData.albumImage = `http://localhost:3000/uploads/${files.albumCover[0].filename}`;
    }
    if (files?.audioFile) {
      updateData.audioUrl = `http://localhost:3000/uploads/${files.audioFile[0].filename}`;
    }

    const response = await fetch(`http://localhost:5000/api/songs/update/${songId}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(updateData)
    });

    if (!response.ok) {
      // If backend fails, clean up uploaded files
      if (files) {
        Object.values(files).forEach(fileArray => {
          fileArray.forEach(file => {
            if (fs.existsSync(`uploads/${file.filename}`)) {
              fs.unlinkSync(`uploads/${file.filename}`);
            }
          });
        });
      }
      const error = await response.json();
      return res.status(response.status).json(error);
    }

    res.status(200).json({ message: 'Song updated successfully' });

    if (!response.ok) {
      const error = await response.json();
      return res.status(response.status).json(error);
    }

    res.status(200).json({ message: 'Song updated successfully' });
  } catch (err) {
    console.error('Error updating song:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Verify token endpoint
app.get('/api/verify-token', async (req, res) => {
  console.log('Received verify-token request');
  const token = req.headers.authorization?.split('Bearer ')[1];
  console.log('Token received:', !!token);
  
  if (!token) {
    console.log('No token provided');
    return res.status(401).json({ 
      error: 'No token provided',
      valid: false 
    });
  }

  try {
    // Decrypt the token (email)
    const email = CryptoJS.AES.decrypt(token, SECRET_KEY).toString(CryptoJS.enc.Utf8);
    console.log('Decrypted email:', email);
    
    if (!email) {
      console.log('Invalid token format - could not decrypt');
      return res.status(401).json({ 
        error: 'Invalid token format',
        valid: false 
      });
    }
    
    // Verify the user exists and is verified
    console.log('Checking user in database...');
    const response = await fetch('http://localhost:5000/getUserByEmail', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email })
    });

    const user = await response.json();
    console.log('User found:', !!user);
    
    if (!user || !user.email) {
      console.log('User not found in database');
      return res.status(401).json({ 
        error: 'User not found',
        valid: false 
      });
    }

    if (!user.email_verified) {
      console.log('User email not verified');
      return res.status(403).json({ 
        error: 'Email not verified',
        valid: false,
        needsVerification: true,
        email: email
      });
    }

    console.log('Token verification successful');
    res.status(200).json({ 
      valid: true,
      user: {
        email: user.email,
        username: user.username
      }
    });
  } catch (error) {
    console.error('Token verification error:', error);
    res.status(401).json({ 
      error: 'Invalid token',
      valid: false 
    });
  }
});

// Resend verification code
app.post('/api/resend-verification', async (req, res) => {
  const { email } = req.body;
  
  if (!email) {
    return res.status(400).json({ error: 'Email is required' });
  }

  try {
    // Check if user exists and needs verification
    const checkRes = await fetch('http://localhost:5000/getUserByEmail', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email })
    });
    
    const user = await checkRes.json();
    if (!user?.email) {
      return res.status(404).json({ error: 'User not found' });
    }

    if (user.email_verified) {
      return res.status(400).json({ error: 'Email is already verified' });
    }

    // Resend verification code
    const registerResponse = await fetch('http://localhost:5000/registerUser', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        username: user.username,
        email: user.email,
        password: user.password,  // Already hashed
        favoriteGenre: user.favorite_genre,
        favoriteArtist: user.favorite_artist,
        bio: user.bio,
        avatar: user.avatar
      })
    });

    if (registerResponse.ok) {
      res.status(200).json({ message: 'Verification code resent successfully' });
    } else {
      const error = await registerResponse.json();
      res.status(registerResponse.status).json(error);
    }
  } catch (err) {
    console.error('Error resending verification:', err);
    res.status(500).json({ error: 'Internal error' });
  }
});

// Log all incoming requests
app.use((req, res, next) => {
    console.log(`Incoming request: ${req.method} ${req.path}`);
    next();
});

//start server
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});