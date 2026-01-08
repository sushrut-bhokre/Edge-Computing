#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "🚀 Starting Deployment: Edge Frontend & Backend (using NPM)"

# 1. System Updates & Node.js Installation
echo "------- Installing Dependencies -------"
sudo apt update
sudo apt install -y git curl build-essential

# Install Node.js (LTS) if not present
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt install -y nodejs
fi

# 2. Setup Backend (Node.js)
echo "------- Setting up Backend -------"
if [ ! -d "edge_backend" ]; then
    git clone https://github.com/Palash-Tinkhede/edge_backend.git
fi
cd edge_backend

# Install dependencies using npm
npm install

# Capture the absolute path for systemd
BACKEND_PATH=$(pwd)

# Create Systemd Service for Backend
# EnvironmentFile reads your existing .env file automatically
sudo bash -c "cat <<EOT > /etc/systemd/system/edge-backend.service
[Unit]
Description=Edge Backend Service
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$BACKEND_PATH
ExecStart=/usr/bin/node app.js
Restart=always
Environment=NODE_ENV=production
EnvironmentFile=$BACKEND_PATH/.env

[Install]
WantedBy=multi-user.target
EOT"

cd ..

# 3. Setup Frontend (Next.js)
echo "------- Setting up Frontend -------"
if [ ! -d "edge_frontend" ]; then
    git clone https://github.com/Palash-Tinkhede/edge_frontend.git
fi
cd edge_frontend

# Install dependencies and build using npm
npm install
npm run build

# Capture the absolute path
FRONTEND_PATH=$(pwd)

# Create Systemd Service for Frontend
sudo bash -c "cat <<EOT > /etc/systemd/system/edge-frontend.service
[Unit]
Description=Edge Frontend Service
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$FRONTEND_PATH
Environment=PORT=3001
ExecStart=/usr/bin/npm start
Restart=always
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOT"

# 4. Activation
echo "------- Activating Services -------"
sudo systemctl daemon-reload
sudo systemctl enable edge-backend edge-frontend
sudo systemctl restart edge-backend edge-frontend

echo "------------------------------------------------"
echo "✅ Deployment Successful!"
echo "Check Backend Status: sudo systemctl status edge-backend"
echo "Check Frontend Status: sudo systemctl status edge-frontend"
echo "------------------------------------------------"

