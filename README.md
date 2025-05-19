# Music Player Project

## Railway Deployment

This project is configured for deployment on Railway. The main components are:

- Flask API backend (Python)
- Node.js API backend (JavaScript)
- React frontend (JavaScript)
- SQL Server database

## Start Commands

The service is started using the following commands:

```bash
# Flask API (main web process)
cd frontend/backend && python Repository.py

# Node.js API (worker process)
cd frontend/backend && node server.js
```

## Database Initialization

The database is initialized during the release phase:

```bash
cd frontend/backend && python init_railway_db.py
```

## Contact

For any issues, please contact the repository maintainer.
