# Setup script for SQL Server in Railway

Write-Host "`n===============================================" -ForegroundColor Cyan
Write-Host "  Music Player Project - Railway SQL Server Setup" -ForegroundColor Cyan
Write-Host "===============================================`n" -ForegroundColor Cyan

# Step 1: Check if Railway CLI is available
try {
    $railwayVersion = npx railway --version
    Write-Host "Railway CLI found: $railwayVersion" -ForegroundColor Green
}
catch {
    Write-Host "Railway CLI not found. Please install it with 'npm i -g @railway/cli'" -ForegroundColor Red
    exit 1
}

# Step 2: Add SQL Server as a service
Write-Host "`nStep 2: Adding SQL Server as a service..." -ForegroundColor Yellow
npx railway add --plugin postgresql

Write-Host "`nSQL Server connection info will be available as environment variables:" -ForegroundColor Green
Write-Host "  - PGHOST: The PostgreSQL host" -ForegroundColor White
Write-Host "  - PGDATABASE: The PostgreSQL database name" -ForegroundColor White
Write-Host "  - PGUSER: The PostgreSQL user" -ForegroundColor White
Write-Host "  - PGPASSWORD: The PostgreSQL password" -ForegroundColor White
Write-Host "  - DATABASE_URL: The PostgreSQL connection string" -ForegroundColor White

# Step 3: Adapt our service to use PostgreSQL instead of SQL Server
Write-Host "`nStep 3: Adapting services to use PostgreSQL..." -ForegroundColor Yellow

Write-Host "`nCreating database adapter script..." -ForegroundColor Yellow
$adapterContent = @'
# Database adapter for Railway PostgreSQL
import os
import sys
import time
import psycopg2
from psycopg2 import sql
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT

def wait_for_db():
    """Wait for PostgreSQL to be ready"""
    print("Waiting for PostgreSQL to be ready...")
    max_retries = 30
    retry_count = 0
    
    # Get connection details from environment variables
    host = os.environ.get('PGHOST', 'localhost')
    dbname = os.environ.get('PGDATABASE', 'postgres')
    user = os.environ.get('PGUSER', 'postgres')
    password = os.environ.get('PGPASSWORD', 'postgres')
    
    while retry_count < max_retries:
        try:
            # Try to connect to PostgreSQL
            conn = psycopg2.connect(
                host=host,
                dbname=dbname,
                user=user,
                password=password
            )
            conn.close()
            print("PostgreSQL is ready!")
            return True
        except Exception as e:
            retry_count += 1
            print(f"PostgreSQL not ready yet. Retrying in 5 seconds... (Attempt {retry_count} of {max_retries})")
            print(f"Error: {str(e)}")
            time.sleep(5)
    
    print("Failed to connect to PostgreSQL after multiple attempts.")
    return False

def init_database():
    """Initialize the database schema for PostgreSQL"""
    try:
        # Get connection details from environment variables
        host = os.environ.get('PGHOST', 'localhost')
        dbname = os.environ.get('PGDATABASE', 'postgres')
        user = os.environ.get('PGUSER', 'postgres')
        password = os.environ.get('PGPASSWORD', 'postgres')
        
        # Connect to PostgreSQL
        conn = psycopg2.connect(
            host=host,
            dbname=dbname,
            user=user,
            password=password
        )
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        cursor = conn.cursor()
        
        # Create tables similar to SQL Server schema
        print("Creating tables...")
        
        # Songs table
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS Songs (
            id SERIAL PRIMARY KEY,
            title VARCHAR(255) NOT NULL,
            artist VARCHAR(255) NOT NULL,
            album VARCHAR(255),
            year INT,
            genre VARCHAR(100),
            duration INT,
            file_path VARCHAR(500),
            album_artwork VARCHAR(500),
            is_public BOOLEAN DEFAULT TRUE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
        ''')
        
        # Users table
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS Users (
            id SERIAL PRIMARY KEY,
            username VARCHAR(50) UNIQUE NOT NULL,
            email VARCHAR(100) UNIQUE NOT NULL,
            password VARCHAR(255) NOT NULL,
            is_admin BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
        ''')
        
        # Playlists table
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS Playlists (
            id SERIAL PRIMARY KEY,
            title VARCHAR(255) NOT NULL,
            user_id INT REFERENCES Users(id),
            is_public BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
        ''')
        
        # PlaylistSongs table
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS PlaylistSongs (
            id SERIAL PRIMARY KEY,
            playlist_id INT REFERENCES Playlists(id) ON DELETE CASCADE,
            song_id INT REFERENCES Songs(id) ON DELETE CASCADE,
            position INT DEFAULT 0,
            UNIQUE (playlist_id, song_id)
        )
        ''')
        
        # Reviews table
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS Reviews (
            id SERIAL PRIMARY KEY,
            song_id INT REFERENCES Songs(id) ON DELETE CASCADE,
            user_id INT REFERENCES Users(id) ON DELETE SET NULL,
            rating INT CHECK (rating BETWEEN 1 AND 5),
            comment TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
        ''')
        
        # Insert sample data
        print("Inserting sample data...")
        
        # Sample admin user (password: admin123)
        cursor.execute('''
        INSERT INTO Users (username, email, password, is_admin) 
        VALUES (%s, %s, %s, %s) 
        ON CONFLICT (email) DO NOTHING
        ''', ('admin', 'admin@example.com', '$2a$10$dHK.pJRBLV8mfP9ilkQeB.JoJ3TWOARQRvQLgx.6wAcAYbQJwJ5Uy', True))
        
        # Sample regular user (password: user123)
        cursor.execute('''
        INSERT INTO Users (username, email, password) 
        VALUES (%s, %s, %s) 
        ON CONFLICT (email) DO NOTHING
        ''', ('user', 'user@example.com', '$2a$10$dHK.pJRBLV8mfP9ilkQeB.5LAFJfS/dutKrde5cnVgYOVPiDBAJAC'))
        
        # Sample songs
        songs = [
            ("Bohemian Rhapsody", "Queen", "A Night at the Opera", 1975, "Rock", 354, "/uploads/bohemian.mp3", "/uploads/queen_album.jpg"),
            ("Billie Jean", "Michael Jackson", "Thriller", 1983, "Pop", 294, "/uploads/billie_jean.mp3", "/uploads/thriller.jpg"),
            ("Hotel California", "Eagles", "Hotel California", 1977, "Rock", 391, "/uploads/hotel_california.mp3", "/uploads/hotel_california.jpg")
        ]
        
        for song in songs:
            cursor.execute('''
            INSERT INTO Songs (title, artist, album, year, genre, duration, file_path, album_artwork)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            ''', song)
        
        # Commit changes and close connection
        conn.commit()
        cursor.close()
        conn.close()
        
        print("Database initialized successfully!")
        return True
    except Exception as e:
        print(f"Database initialization failed: {str(e)}")
        return False

if __name__ == "__main__":
    if wait_for_db():
        init_database()
'@

$adapterContent | Out-File -FilePath "./frontend/backend/pg_adapter.py" -Encoding utf8

# Step 4: Setting up environment variables for our application
Write-Host "`nStep 4: Setting up environment variables..." -ForegroundColor Yellow
npx railway variables set DB_TYPE=postgresql
npx railway variables set USE_PG_ADAPTER=true
npx railway variables set FLASK_ENV=production
npx railway variables set NODE_ENV=production
npx railway variables set JWT_SECRET_KEY=$(Get-Random)

Write-Host "`nUpdating requirements.txt to include PostgreSQL support..." -ForegroundColor Yellow
Add-Content -Path "./frontend/backend/requirements.txt" -Value "psycopg2-binary==2.9.9"

# Step 5: Update the deployment settings
Write-Host "`nStep 5: Updating deployment configuration..." -ForegroundColor Yellow
npx railway up

Write-Host "`n===============================================" -ForegroundColor Green
Write-Host "  Railway SQL Server Setup Complete!" -ForegroundColor Green
Write-Host "===============================================`n" -ForegroundColor Green

Write-Host "To initialize the database, run:" -ForegroundColor Cyan
Write-Host "  npx railway run python frontend/backend/pg_adapter.py" -ForegroundColor White
Write-Host "`nTo view your deployment, run:" -ForegroundColor Cyan
Write-Host "  npx railway open" -ForegroundColor White
