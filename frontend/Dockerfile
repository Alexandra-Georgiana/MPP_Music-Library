# Build stage
FROM node:lts-alpine AS build

# Set config
ENV NPM_CONFIG_UPDATE_NOTIFIER=false
ENV NPM_CONFIG_FUND=false

# Create and change to the app directory
WORKDIR /app

# Copy only frontend package files
COPY frontend/package*.json frontend/vite.config.js ./

# Install dependencies
RUN npm ci

# Copy only frontend source files (excluding backend and node_modules)
COPY frontend/src/ ./src/
COPY frontend/public/ ./public/
COPY frontend/index.html ./

# Build the app
RUN npm run build

# Serve stage
FROM caddy:alpine

# Create and change to the app directory
WORKDIR /app

# Copy Caddyfile to the container image
COPY frontend/Caddyfile ./

# Format Caddyfile
RUN caddy fmt --overwrite Caddyfile

# Copy built files from build stage
COPY --from=build /app/dist ./dist

# Expose port
EXPOSE 80

# Start Caddy
CMD ["caddy", "run", "--config", "Caddyfile", "--adapter", "caddyfile"]
