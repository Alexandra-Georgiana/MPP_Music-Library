# Backend service
FROM node:18-slim

# Create app directory
WORKDIR /app/backend

# Set environment variables
ENV NODE_ENV=production
ENV FLASK_API_URL=http://flask-backend:5000
ENV NODE_API_URL=http://node-backend:3000

# Copy backend files
WORKDIR /app/frontend/backend

# Copy backend package files first
COPY frontend/backend/package*.json ./

# Install backend dependencies (only need to do this once)
RUN npm install

# Copy the backend application
COPY frontend/backend/ .

# Create uploads directory
RUN mkdir -p uploads

# Expose the port the app runs on
EXPOSE 3000

# Command to run the application
CMD ["node", "server.js"]
