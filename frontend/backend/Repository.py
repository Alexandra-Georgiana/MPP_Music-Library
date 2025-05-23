from flask import Flask, request, jsonify
import pyodbc
from monitor_thread import monitor_comments
import datetime
from functools import wraps
import jwt as pyjwt  # Rename to avoid confusion
import random
import string
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import os
from dotenv import load_dotenv
import ssl

app = Flask(__name__)
# Email Configuration
GMAIL_USER = os.getenv('GMAIL_USER', 'your-email@gmail.com')
GMAIL_APP_PASSWORD = os.getenv('GMAIL_APP_PASSWORD', 'your-app-password')

# Setup HTTPS if enabled
use_https = os.getenv('USE_HTTPS', 'false').lower() == 'true'
CERT_FILE = os.getenv('SSL_CERT', './certs/certificate.crt')
KEY_FILE = os.getenv('SSL_KEY', './certs/private.key')

# Set your secret key for JWT from environment variable
app.config['SECRET_KEY'] = os.getenv('JWT_SECRET_KEY', 'admin-secret-key-change-this-in-production')

def generate_admin_token(admin_id, email):
    expiration = datetime.datetime.utcnow() + datetime.timedelta(hours=24)  # Token expires in 24 hours
    token = pyjwt.encode({
        'admin_id': admin_id,
        'email': email,
        'exp': expiration.timestamp()  # Convert to Unix timestamp
    }, app.config['SECRET_KEY'], algorithm='HS256')
    return token

def admin_token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = request.headers.get('Authorization')
        if not token:
            return jsonify({'error': 'Token is missing!'}), 401

        try:
            if token.startswith('Bearer '):
                token = token.split('Bearer ')[1]
            data = pyjwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])
            current_admin = data
        except pyjwt.ExpiredSignatureError:
            return jsonify({'error': 'Token has expired!'}), 401
        except pyjwt.InvalidTokenError:
            return jsonify({'error': 'Invalid token!'}), 401

        return f(*args, **kwargs)
    return decorated# Start the monitoring thread

def get_db_connection():
    try:
        # Check if running on Azure (DATABASE_URL environment variable will be set)
        database_url = os.getenv('DATABASE_URL')
        
        if database_url:
            # Parse Azure SQL Server connection string
            conn_str = (
                'DRIVER={ODBC Driver 17 for SQL Server};'
                f'SERVER={os.getenv("AZURE_SQL_SERVER")};'  # Azure SQL Server hostname
                f'DATABASE={os.getenv("AZURE_SQL_DATABASE", "MusicLibrary")};'  # Database name, default to MusicLibrary
                f'UID={os.getenv("AZURE_SQL_USER")};'  # Azure SQL Server username
                f'PWD={os.getenv("AZURE_SQL_PASSWORD")};'  # Azure SQL Server password
                'TrustServerCertificate=yes;'
                'Encrypt=yes;'  # Azure requires encryption
            )
        else:
            # Local development configuration with Windows Authentication
            conn_str = (
                'DRIVER={ODBC Driver 17 for SQL Server};'
                'SERVER=USER\\MSSQLSERVER03;'
                'DATABASE=MusicLibrary;'
                'Trusted_Connection=yes;'
                'TrustServerCertificate=yes;'
            )
        
        conn = pyodbc.connect(conn_str)
        return conn
        return conn
    except Exception as e:
        print("Error establishing database connection:", e)
        raise

@app.before_request
def log_request_info():
    print(f"Incoming request: {request.method} {request.path}")
    print(f"Request headers: {dict(request.headers)}")
    print(f"Request content type: {request.content_type}")
    if request.is_json:
        try:
            print(f"Request JSON data: {request.json}")
        except Exception as e:
            print(f"Error parsing JSON: {str(e)}")
    else:
        print(f"Request body: {request.get_data(as_text=True)[:200]}")

# ------------------------------- USER ENDPOINTS -------------------------------

@app.route('/getUserByEmail', methods=['POST'])
def get_user_by_email():
    email = request.json.get('email')
    
    cursor.execute("SELECT * FROM users WHERE email = ?", email)
    row = cursor.fetchone()
    if row:
        columns = [col[0] for col in cursor.description]
        return jsonify(dict(zip(columns, row)))
    return jsonify({})

def generate_verification_token():
    # Generate a random 6-digit verification code
    return ''.join(random.choices(string.digits, k=6))

def send_verification_email(to_email, verification_code):
    try:
        # Create message
        msg = MIMEMultipart('alternative')
        msg['Subject'] = "Music Library - Email Verification"
        msg['From'] = GMAIL_USER  # Use the actual Gmail address
        msg['To'] = to_email
        
        # Create the plain-text and HTML version of your message
        text = f"""
        Welcome to Music Library!
        
        Your verification code is: {verification_code}
        
        This code will expire in 10 minutes.
        If you didn't request this code, please ignore this email.
        """
        
        html = f"""
        <html>
            <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
                <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
                    <h2 style="color: #2c3e50; text-align: center;">Welcome to Music Library!</h2>
                    <div style="background-color: #f9f9f9; padding: 20px; border-radius: 5px; margin: 20px 0;">
                        <p style="font-size: 16px;">Your verification code is:</p>
                        <h1 style="text-align: center; color: #3498db; font-size: 32px; letter-spacing: 5px;">{verification_code}</h1>
                        <p style="color: #7f8c8d; font-size: 14px;">This code will expire in 10 minutes.</p>
                    </div>
                    <p style="color: #95a5a6; font-size: 12px; text-align: center;">If you didn't request this code, please ignore this email.</p>
                </div>
            </body>
        </html>
        """

        # Add the text and HTML parts to the MIMEMultipart message
        part1 = MIMEText(text, 'plain')
        part2 = MIMEText(html, 'html')
        msg.attach(part1)
        msg.attach(part2)

        try:
            # Create SMTP session for sending the mail
            server = smtplib.SMTP('smtp.gmail.com', 587)
            server.starttls()  # Enable TLS
            
            # Print debug info
            print(f"Attempting to login with GMAIL_USER: {GMAIL_USER}")
            
            # Login to the server
            server.login(GMAIL_USER, GMAIL_APP_PASSWORD)
            
            # Send email
            server.send_message(msg)
            
            # Close the connection
            server.quit()
            
            print(f"Verification email sent successfully to {to_email}")
            return True
            
        except Exception as smtp_error:
            print(f"SMTP Error: {smtp_error}")
            print(f"Gmail User: {GMAIL_USER}")
            print("Please check your Gmail credentials and make sure you're using an App Password")
            return False
            
    except Exception as e:
        print(f"General Error sending email: {e}")
        # For development/testing purposes, print the code
        print(f"Development mode: Verification code is: {verification_code}")
        return False

@app.route('/registerUser', methods=['POST'])
def register_user():
    data = request.json

    # Set defaults if any value is None
    username = data.get('username')
    email = data.get('email')
    password = data.get('password')
    favorite_genre = data.get('favoriteGenre') or ''
    favorite_artist = data.get('favoriteArtist') or ''
    bio = data.get('bio') or ''
    avatar = data.get('avatar')  # Can be None if your DB allows it

    try:
        # Generate verification code
        verification_code = generate_verification_token()
        verification_expires = datetime.datetime.utcnow() + datetime.timedelta(minutes=10)

        cursor.execute(""" 
            INSERT INTO users (username, email, password, favorite_genre, favorite_artist, bio, avatar,
                             email_verified, two_factor_enabled, two_factor_token, two_factor_expires)
            VALUES (?, ?, ?, ?, ?, ?, ?, 0, 0, ?, ?)""",
            username, email, password,
            favorite_genre, favorite_artist,
            bio, avatar, verification_code, verification_expires)
        conn.commit()

        # Send verification email
        if send_verification_email(email, verification_code):
            return jsonify({
                'message': 'Registration successful. Please check your email for verification code.',
                'email': email
            }), 200
        else:
            return jsonify({'error': 'Failed to send verification email'}), 500

    except Exception as e:
        print("Error inserting user:", e)
        return jsonify({'error': str(e)}), 500

@app.route('/verify-email', methods=['POST'])
def verify_email():
    data = request.json
    email = data.get('email')
    code = data.get('code')
    
    if not email or not code:
        return jsonify({'error': 'Email and verification code are required'}), 400
        
    try:
        cursor.execute("""
            SELECT two_factor_token, two_factor_expires
            FROM users
            WHERE email = ? AND email_verified = 0
        """, (email,))
        row = cursor.fetchone()
        
        if not row:
            return jsonify({'error': 'Invalid email or already verified'}), 400
            
        stored_code, expiration = row
        
        if datetime.datetime.utcnow() > expiration:
            return jsonify({'error': 'Verification code has expired'}), 400
            
        if code != stored_code:
            return jsonify({'error': 'Invalid verification code'}), 400
            
        # Mark email as verified and clear verification code
        cursor.execute("""
            UPDATE users
            SET email_verified = 1,
                two_factor_token = NULL,
                two_factor_expires = NULL
            WHERE email = ?
        """, (email,))
        conn.commit()
        
        return jsonify({'message': 'Email verified successfully'}), 200
        
    except Exception as e:
        print(f"Error verifying email: {e}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/updateUserProfile', methods=['POST'])
def update_user_profile():
    data = request.json

    # Debugging: Log the incoming data
    print("Received data for update_user_profile:", data)

    # Validate input data
    required_fields = ['password', 'favoriteGenre', 'favoriteArtist', 'bio', 'avatar', 'email']
    for field in required_fields:
        if field not in data:
            return jsonify({"error": f"Missing field: {field}"}), 400

    try:
        # Update user profile without modifying the username
        cursor.execute("""
            UPDATE users SET password = ?, favorite_genre = ?, favorite_artist = ?, bio = ?, avatar = ?
            WHERE email = ?""",
            data['password'], data['favoriteGenre'],
            data['favoriteArtist'], data['bio'], data['avatar'], data['email']
        )
        conn.commit()
        return '', 204
    except Exception as e:
        print("Error updating user profile:", e)

# ------------------------------- SONGS ENDPOINTS -------------------------------

#pagination
#improve performance by using indexes on the columns used in the WHERE clause and JOIN conditions
#fetch all songs that u want
@app.route('/getAllSongs', methods=['GET'])
def get_all_songs():
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute("""
            SELECT track_id, track_name, artist_name, album_name, album_image, genres, rating
            FROM songs WITH (INDEX(idx_track_name))
            ORDER BY track_name
        """)
        rows = cursor.fetchall()
        columns = [col[0] for col in cursor.description]
        songs = [dict(zip(columns, row)) for row in rows]

        return jsonify(songs), 200
    except Exception as e:
        print("Error fetching songs:", e)
        return jsonify({"error": "Failed to fetch songs"}), 500
    finally:
        cursor.close()
        conn.close()

@app.route('/getSongById/<int:song_id>', methods=['GET'])
def get_song_by_id(song_id):
    print(f"⚠️ getSongById called with ID: {song_id}")
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM songs WHERE track_id = ?", song_id)  # Updated column name to 'track_id'
    row = cursor.fetchone()
    conn.close()

    if row:
        columns = [col[0] for col in cursor.description]
        return jsonify(dict(zip(columns, row)))
    return jsonify({}), 404

@app.route('/api/searchSongs/<query>', methods=['GET'])
def search_songs(query):
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute("""
            SELECT track_id, track_name, artist_name, album_name, album_image, genres
            FROM songs WITH (INDEX(idx_track_name))
            WHERE track_name LIKE ? OR artist_name LIKE ?
        """, (f"%{query}%", f"%{query}%"))
        rows = cursor.fetchall()
        columns = [col[0] for col in cursor.description]
        songs = [dict(zip(columns, row)) for row in rows]

        return jsonify(songs), 200
    except Exception as e:
        print("Error searching songs:", e)
        return jsonify({"error": "Failed to search songs"}), 500
    finally:
        cursor.close()
        conn.close()

@app.route('/api/addReview', methods=['POST'])
def add_review():
    try:
        # Log the request to help with debugging
        print(f"Received review request at: {request.path}")
        
        # Ensure the request has JSON data
        if not request.is_json:
            print("ERROR: Request Content-Type is not application/json")
            return jsonify({"error": "Content-Type must be application/json"}), 400
            
        data = request.json
        if not data:
            print("ERROR: No JSON data received")
            return jsonify({"error": "No data provided"}), 400
            
        print(f"Received review data: {data}")
        
        # Validate required fields
        email = data.get('userId')  # userId here is actually the email
        if not email:
            print("ERROR: No email provided in userId field")
            return jsonify({"error": "Email is required"}), 400
            
        track_id = data.get('trackId')
        if not track_id:
            print("ERROR: No track ID provided")
            return jsonify({"error": "Track ID is required"}), 400
            
        comment = data.get('comment', '')  # Default to empty string if not provided
        rating = data.get('rating')
        
        print(f"Processing review - Email: {email}, Track ID: {track_id}, Rating: {rating}, Has Comment: {bool(comment)}")

        # 🔍 Look up user ID by email
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT id FROM users WHERE email = ?", (email,))
        user = cursor.fetchone()
        if not user:
            print(f"ERROR: No user found for email: {email}")
            return jsonify({"error": f"No user found with email: {email}"}), 404

        user_id = user[0]  # Extract the ID from the query result
        print("Resolved user_id:", user_id)

        try:
            # Insert comment if provided
            if comment and comment.strip():
                cursor.execute("""
                    INSERT INTO comments (user_id, track_id, comment_text)
                    VALUES (?, ?, ?)
                """, (user_id, track_id, comment))

            # Insert or update the rating if provided
            if rating is not None:
                # Ensure rating is a number in acceptable range (1-5)
                try:
                    rating_value = float(rating)
                    if not (1 <= rating_value <= 5):
                        return jsonify({"error": "Rating must be between 1 and 5"}), 400
                except (ValueError, TypeError):
                    return jsonify({"error": "Rating must be a number"}), 400
                    
                cursor.execute("""
                    MERGE ratings AS target
                    USING (SELECT ? AS user_id, ? AS track_id, ? AS rating) AS source
                    ON target.user_id = source.user_id AND target.track_id = source.track_id
                    WHEN MATCHED THEN
                        UPDATE SET rating = source.rating, created_at = GETDATE()
                    WHEN NOT MATCHED THEN
                        INSERT (user_id, track_id, rating, created_at)
                        VALUES (source.user_id, source.track_id, source.rating, GETDATE());
                """, (user_id, track_id, rating_value))
                
                # Recalculate the average rating for the song
                cursor.execute("""
                    UPDATE songs
                    SET rating = (SELECT AVG(rating) FROM ratings WHERE track_id = ?)
                    WHERE track_id = ?;
                """, (track_id, track_id))
                
            conn.commit()
            conn.close()
            
            print("Review added successfully")
            return jsonify({"message": "Review added successfully"}), 200
            
        except Exception as db_error:
            conn.rollback()
            print(f"Database error: {db_error}")
            return jsonify({"error": "Database error", "details": str(db_error)}), 500
            
    except ValueError as ve:
        print(f"Validation error in review submission: {ve}")
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(ve)}), 400
    except Exception as e:
        print("Error adding review:", e)
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e) or "Failed to add review", "type": type(e).__name__}), 500


@app.route('/api/addComment', methods=['POST'])
@app.route('/addComment', methods=['POST'])  # Add this alias route to ensure compatibility
def add_comment():
    try:
        # Log the request to help with debugging
        print(f"Received comment request at: {request.path}")
        
        # Ensure the request has JSON data
        if not request.is_json:
            print("ERROR: Request Content-Type is not application/json")
            return jsonify({"error": "Content-Type must be application/json"}), 400
            
        data = request.json
        if not data:
            print("ERROR: No JSON data received")
            return jsonify({"error": "No data provided"}), 400
        
        print(f"Received comment data: {data}")
        
        # Validate required fields
        email = data.get('userId')  # userId is email in this context
        if not email:
            print("ERROR: No email provided in userId field")
            return jsonify({"error": "Email is required"}), 400
            
        track_id = data.get('trackId')
        if not track_id:
            print("ERROR: No track ID provided")
            return jsonify({"error": "Track ID is required"}), 400
            
        comment = data.get('comment')
        if not comment or not comment.strip():
            print("ERROR: Empty comment received")
            return jsonify({"error": "Comment cannot be empty"}), 400

        print(f"Processing comment - Email: {email}, Track ID: {track_id}")

        # Look up user ID by email
        try:
            conn = get_db_connection()
            cursor = conn.cursor()
            cursor.execute("SELECT id FROM users WHERE email = ?", (email,))
            user = cursor.fetchone()
            if not user:
                print(f"ERROR: No user found for email: {email}")
                return jsonify({"error": f"No user found with email: {email}"}), 404
                
            user_id = user[0]  # Extract the ID from the query result
            print("Resolved user_id:", user_id)

            cursor.execute("""
                INSERT INTO comments (user_id, track_id, comment_text)
                VALUES (?, ?, ?)
            """, (user_id, track_id, comment))
            
            conn.commit()
            conn.close()
            print("Comment added successfully")
            return jsonify({"message": "Comment added successfully"}), 200
        except Exception as db_error:
            if conn:
                conn.rollback()
            print(f"Database error: {db_error}")
            return jsonify({"error": "Database error", "details": str(db_error)}), 500
    except ValueError as ve:
        print(f"Validation error in comment submission: {ve}")
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(ve)}), 400
    except Exception as e:
        print("Error adding comment:", e)
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e) or "Failed to add comment", "type": type(e).__name__}), 500

@app.route('/api/getSongDetails/<int:track_id>', methods=['GET'])
def get_song_details(track_id):
    try:
        # Calculate the average rating for the song
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
            SELECT AVG(rating) AS average_rating
            FROM ratings
            WHERE track_id = ?
        """, track_id)
        avg_rating_row = cursor.fetchone()
        average_rating = avg_rating_row[0] if avg_rating_row[0] is not None else 0

        # Fetch the last 10 comments for the song
        cursor.execute("""
            SELECT users.username, comments.comment_text, comments.created_at
            FROM comments
            JOIN users ON comments.user_id = users.id
            WHERE comments.track_id = ?
            ORDER BY comments.created_at DESC
            OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
        """, track_id)
        rows = cursor.fetchall()
        columns = [col[0] for col in cursor.description]
        comments = [dict(zip(columns, row)) for row in rows]

        conn.close()
        return jsonify({
            "average_rating": average_rating,
            "comments": comments
        }), 200
    except Exception as e:
        print("Error fetching song details:", e)
        return jsonify({"error": "Failed to fetch song details"}), 500
    
@app.route('/api/addToLiked', methods=['POST'])
def add_to_liked():
    try:
        data = request.json
        email = data.get('userId')  # userId here is actually the email
        track_id = data.get('trackId')

        # 🔍 Look up user ID by email
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT id FROM users WHERE email = ?", (email,))
        user = cursor.fetchone()
        if not user:
            raise ValueError("No user found with that email")

        user_id = user[0]  # Extract the ID from the query result
        print("Resolved user_id:", user_id)

        # Insert into liked_songs table
        cursor.execute("""
            INSERT INTO liked_songs (user_id, track_id)
            VALUES (?, ?)
        """, (user_id, track_id))

        conn.commit()
        conn.close()
        return jsonify({"message": "Song added to liked list successfully"}), 200

    except Exception as e:
        print("Error adding to liked list:", e)
        return jsonify({"error": "Failed to add to liked list"}), 500
    
@app.route('/api/getLikedSongs', methods=['POST'])
def get_liked_songs():
    try:
        print("Flask: Received request to /api/getLikedSongs")
        print("Flask: Request data:", request.get_data())
        print("Flask: Request JSON:", request.json)
        
        data = request.json
        if not data or 'email' not in data:
            print("No email provided in request")
            return jsonify([])

        email = data['email']
        print(f"Flask: Processing getLikedSongs for email: {email}")
        
        # Get user ID first
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT id FROM users WHERE email = ?", (email,))
        user = cursor.fetchone()
        
        if not user:
            print(f"No user found for email: {email}")
            conn.close()
            return jsonify([])

        user_id = user[0]
        print(f"Found user ID: {user_id}")

        # Get liked songs with the user's specific rating
        cursor.execute("""
            SELECT 
                s.track_id,
                s.track_name,
                s.artist_name,
                s.album_name,
                s.album_image,
                s.audio_url,
                COALESCE(r.rating, 0) AS rating
            FROM songs s
            INNER JOIN liked_songs ls ON s.track_id = ls.track_id
            LEFT JOIN ratings r ON s.track_id = r.track_id AND r.user_id = ?
            WHERE ls.user_id = ?
        """, (user_id, user_id))

        # Convert rows to list of dictionaries
        columns = ['track_id', 'track_name', 'artist_name', 'album_name', 'album_image', 'audio_url', 'rating']
        liked_songs = []

        for row in cursor.fetchall():
            song = {}
            for i, col in enumerate(columns):
                song[col] = row[i] if row[i] is not None else ''
            liked_songs.append(song)

        print(f"Found {len(liked_songs)} liked songs for user ID {user_id}")
        conn.close()
        return jsonify(liked_songs)

    except Exception as e:
        print(f"Error in get_liked_songs for email {data.get('email', 'N/A')}: {str(e)}")
        if 'conn' in locals():
            conn.close()
        return jsonify({"error": "Internal server error"}), 500
    

#-------Admin---------

@app.route('/api/admin/login', methods=['POST'])
def admin_login():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        data = request.json
        email = data.get('email')
        password = data.get('password')
        
        if not email or not password:
            return jsonify({"error": "Email and password are required"}), 400
        
        cursor.execute("SELECT id, email, password FROM Admin WHERE email = ?", (email,))
        row = cursor.fetchone()
        
        if not row:
            return jsonify({"error": "Admin not found"}), 404
        
        stored_password = row[2]  # Password is the third column
        if password != stored_password:  # In production, use proper password hashing
            return jsonify({"error": "Invalid password"}), 401
            
        # Generate token
        token = generate_admin_token(row[0], row[1])  # Pass admin_id and email
        
        return jsonify({
            "message": "Login successful",
            "token": token,
            "admin": {
                "id": row[0],
                "email": row[1]
            }
        }), 200
    except Exception as e:
        print("Error fetching admin:", e)
        return jsonify({"error": "Failed to fetch admin"}), 500
    finally:
        cursor.close()
        conn.close()

@app.route('/api/mostCommonGenre/<int:rating>', methods=['GET'])
def get_most_common_genre(rating):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        # Use the idx_genre_rating index to optimize the query
        # Use TOP 1 WITH TIES to fetch all genres with the same highest count
        if rating == 1:  # Low ratings (<= 2)
            cursor.execute("""
                SELECT TOP 1 
                FROM songs
                WHERE rating <= 2 AND genres IS NOT NULL AND genres != ''
                GROUP BY genres
                ORDER BY COUNT(*) DESC
            """)
        elif rating == 2:  # Medium ratings (= 3)
            cursor.execute("""
                SELECT TOP 1 WITH TIES genres
                FROM songs WITH (INDEX(idx_genre_rating))
                WHERE rating = 3 AND genres IS NOT NULL AND genres != ''
                GROUP BY genres
                ORDER BY COUNT(*) DESC
            """)
        elif rating == 3:  # High ratings (>= 4)
            cursor.execute("""
                SELECT TOP 1 WITH TIES genres
                FROM songs WITH (INDEX(idx_genre_rating))
                WHERE rating >= 4 AND genres IS NOT NULL AND genres != ''
                GROUP BY genres
                ORDER BY COUNT(*) DESC
            """)
        else:
            return jsonify({"error": "Invalid rating range"}), 400

        row = cursor.fetchone()
        print("Query result for rating", rating, ":", row)  # Log the query result
        conn.close()

        if row:
            return jsonify({"most_common_genre": row[0]}), 200
        else:
            return jsonify({"most_common_genre": "none"}), 200

    except Exception as e:
        print("Error fetching most common genre:", e)
        return jsonify({"error": "Failed to fetch most common genre"}), 500
    
@app.route('/api/getMonitoredUsers', methods=['GET'])
@admin_token_required
def get_monitored_users():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM monitored_users")
        rows = cursor.fetchall()
        columns = [col[0] for col in cursor.description]
        monitored_users = [dict(zip(columns, row)) for row in rows]

        return jsonify(monitored_users), 200
    except Exception as e:
        print("Error fetching monitored users:", e)
        return jsonify({"error": "Failed to fetch monitored users"}), 500
    finally:
        cursor.close()
        conn.close()

@app.route('/api/songs/delete/<int:song_id>', methods=['DELETE'])
@admin_token_required
def delete_song(song_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # First check if the song exists
        cursor.execute("SELECT track_id FROM songs WHERE track_id = ?", (song_id,))
        if not cursor.fetchone():
            return jsonify({"error": "Song not found"}), 404

        # Delete related records first (maintain referential integrity)
        cursor.execute("DELETE FROM comments WHERE track_id = ?", (song_id,))
        cursor.execute("DELETE FROM ratings WHERE track_id = ?", (song_id,))
        cursor.execute("DELETE FROM liked_songs WHERE track_id = ?", (song_id,))
        
        # Finally delete the song
        cursor.execute("DELETE FROM songs WHERE track_id = ?", (song_id,))
        
        conn.commit()
        return jsonify({"message": "Song deleted successfully"}), 200
    except Exception as e:
        print("Error deleting song:", e)
        return jsonify({"error": "Failed to delete song"}), 500
    finally:
        cursor.close()
        conn.close()

@app.route('/api/spngs/add', methods=['POST'])
@admin_token_required
def add_song():
    try:
        data = request.json
        track_name = data.get('trackName')
        artist_name = data.get('artistName')
        album_name = data.get('albumName')
        album_image = data.get('albumImage')
        rating = data.get('rating')
        genres = data.get('genres')
        audio_url = data.get('audioUrl')

        conn = get_db_connection()
        cursor = conn.cursor()

        # Insert the new song into the database
        cursor.execute("""
            INSERT INTO songs (track_name, artist_name, album_name, album_image, rating, genres, audio_url)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (track_name, artist_name, album_name, album_image, rating, genres, audio_url))

        conn.commit()
        return jsonify({"message": "Song added successfully"}), 200
    except Exception as e:
        print("Error adding song:", e)
        return jsonify({"error": "Failed to add song"}), 500
    finally:
        cursor.close()
        conn.close()

@app.route('/api/songs/update/<int:song_id>', methods=['PUT'])
@admin_token_required
def update_song(song_id):
    try:
        print("Received update request for song_id:", song_id)
        print("Request Content-Type:", request.headers.get('Content-Type'))
        if request.headers.get('Content-Type', '').startswith('multipart/form-data'):
            data = request.form
            files = request.files
            print("Form data:", data)
            print("Files:", files)
        else:
            data = request.json
            print("JSON data:", data)

        # Get the values, defaulting to the existing values if not provided
        conn = get_db_connection()
        cursor = conn.cursor()

        # First get existing song data
        cursor.execute("SELECT * FROM songs WHERE track_id = ?", (song_id,))
        existing_song = cursor.fetchone()
        if not existing_song:
            return jsonify({"error": "Song not found"}), 404
        
        # Convert row to dict for easier access
        columns = [col[0] for col in cursor.description]
        existing_song = dict(zip(columns, existing_song))

        # Use new values if provided, otherwise keep existing ones
        track_name = data.get('trackName', existing_song['track_name'])
        artist_name = data.get('artistName', existing_song['artist_name'])
        album_name = data.get('albumName', existing_song['album_name'])
        genres = data.get('genres', existing_song['genres'])
        
        # Handle file uploads if present
        album_image = data.get('albumImage', existing_song['album_image'])
        audio_url = data.get('audioUrl', existing_song['audio_url'])

        # Update the song in the database
        cursor.execute("""
            UPDATE songs
            SET track_name = ?, artist_name = ?, album_name = ?, album_image = ?, genres = ?, audio_url = ?
            WHERE track_id = ?
        """, (track_name, artist_name, album_name, album_image, genres, audio_url, song_id))

        conn.commit()
        return jsonify({"message": "Song updated successfully"}), 200
    except Exception as e:
        print("Error updating song:", e)
        return jsonify({"error": "Failed to update song"}), 500
    finally:
        cursor.close()
        conn.close()


# Admin verify token endpoint
@app.route('/api/admin/verify', methods=['GET'])
def verify_admin_token():
    token = request.headers.get('Authorization')
    if not token:
        return jsonify({'error': 'Token is missing!'}), 401

    try:
        if token.startswith('Bearer '):
            token = token.split('Bearer ')[1]
        data = pyjwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])
        return jsonify({'message': 'Valid token', 'admin': data}), 200
    except pyjwt.ExpiredSignatureError:
        return jsonify({'error': 'Token has expired!'}), 401
    except pyjwt.InvalidTokenError:
        return jsonify({'error': 'Invalid token!'}), 401


@app.route('/api/user/getLikedSongs', methods=['POST'])
def get_user_liked_songs():
    try:
        data = request.json
        if not data or 'email' not in data:
            print("No email provided in request")
            return jsonify([])

        email = data['email']
        print(f"Fetching liked songs for email: {email}")
        
        # Get user ID first
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT id FROM users WHERE email = ?", (email,))
        user = cursor.fetchone()
        
        if not user:
            print(f"No user found for email: {email}")
            conn.close()
            return jsonify([])

        user_id = user[0]
        print(f"Found user ID: {user_id}")        # Get liked songs with the user's specific rating
        cursor.execute("""
            SELECT 
                s.track_id,
                s.track_name,
                s.artist_name,
                s.album_name,
                s.album_image,
                s.audio_url,
                COALESCE(r.rating, 0) AS rating
            FROM songs s
            INNER JOIN liked_songs ls ON s.track_id = ls.track_id
            LEFT JOIN ratings r ON s.track_id = r.track_id AND r.user_id = ?
            WHERE ls.user_id = ?
        """, (user_id, user_id))

        # Convert rows to list of dictionaries
        columns = ['track_id', 'track_name', 'artist_name', 'album_name', 'album_image', 'audio_url', 'rating']
        liked_songs = []

        for row in cursor.fetchall():
            song = {}
            for i, col in enumerate(columns):
                song[col] = row[i] if row[i] is not None else ''
            liked_songs.append(song)

        print(f"Found {len(liked_songs)} liked songs for user ID {user_id}")
        conn.close()
        return jsonify(liked_songs)

    except Exception as e:
        print(f"Error in get_user_liked_songs for email {data.get('email', 'N/A')}: {str(e)}")
        if 'conn' in locals():
            conn.close()
        return jsonify({"error": "Internal server error"}), 500
    

if __name__ == '__main__':
    try:
        # Get port from environment variable for Railway
        port = int(os.environ.get("PORT", 5000))
        
        if use_https and os.path.exists(CERT_FILE) and os.path.exists(KEY_FILE):
            # Use HTTPS configuration with certificates
            context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
            context.load_cert_chain(CERT_FILE, KEY_FILE)
            app.run(host='0.0.0.0', port=port, ssl_context=context, debug=False)
        else:
            # Standard configuration
            app.run(host='0.0.0.0', port=port, debug=False)
            
        # Start the monitor thread if not in Railway
        if not os.getenv('RAILWAY_ENVIRONMENT'):
            monitor_comments(conn)
    except Exception as e:
        print(f"Error starting Flask application: {e}")