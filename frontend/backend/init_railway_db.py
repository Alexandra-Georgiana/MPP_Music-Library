#!/usr/bin/env python

import os
import time
import pyodbc
import subprocess

def wait_for_db():
    """Wait for the SQL Server database to become available"""
    print("Waiting for SQL Server to be ready...")
    max_retries = 30
    retry_count = 0
    
    while retry_count < max_retries:
        try:
            conn_str = "Driver={ODBC Driver 17 for SQL Server};Server=sqlserver;Database=master;UID=sa;PWD=StrongPassword123!"
            conn = pyodbc.connect(conn_str)
            conn.close()
            print("SQL Server is ready!")
            return True
        except:
            retry_count += 1
            print(f"SQL Server not ready yet. Retrying in 5 seconds... (Attempt {retry_count} of {max_retries})")
            time.sleep(5)
    
    print("Failed to connect to SQL Server after multiple attempts.")
    return False

def init_database():
    """Initialize the database with schema and data"""
    
    # Create database
    try:
        conn_str = "Driver={ODBC Driver 17 for SQL Server};Server=sqlserver;Database=master;UID=sa;PWD=StrongPassword123!"
        conn = pyodbc.connect(conn_str)
        cursor = conn.cursor()
        print("Creating MusicLibrary database...")
        cursor.execute("IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'MusicLibrary') CREATE DATABASE MusicLibrary")
        conn.commit()
        conn.close()
        
        # Apply schema from init.sql
        print("Applying database schema...")
        with open("init.sql", "r") as sql_file:
            sql_script = sql_file.read()
            
        conn = pyodbc.connect(f"{conn_str.replace('Database=master', 'Database=MusicLibrary')}")
        cursor = conn.cursor()
        
        # Split and execute SQL commands
        for command in sql_script.split(';'):
            if command.strip():
                cursor.execute(command)
        conn.commit()
        
        # Apply stored procedures
        print("Applying stored procedures...")
        with open("data/ProceduresMusicLib.sql", "r") as proc_file:
            proc_script = proc_file.read()
            
        for command in proc_script.split('GO'):
            if command.strip():
                cursor.execute(command)
        conn.commit()
        conn.close()
        
        # Populate sample data
        print("Populating sample data...")
        import populate_songs  # Import and run the populate script
        
        print("Database initialization completed successfully!")
        return True
    except Exception as e:
        print(f"Database initialization failed: {str(e)}")
        return False

if __name__ == "__main__":
    if wait_for_db():
        init_database()
