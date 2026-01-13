#!/bin/bash
set -e

# ==================================================
# CONFIGURATION
# ==================================================
MONGO_URI="mongodb+srv://palashtinkhede8124_db_user:Pass%40mong%40123@edgeauth.nabl7hf.mongodb.net/"
PYTHON_SCRIPT="/usr/local/bin/node_inventory_to_mongo.py"
SERVICE_FILE="/etc/systemd/system/node-inventory.service"
IP_ADDRESS="$(hostname -I | awk '{print $1}')"

echo "Starting node inventory installation..."

# ==================================================
# INSTALL SYSTEM DEPENDENCIES
# ==================================================
echo "Installing system dependencies..."

apt install -y python3 python3-pip python3-psutil python3-pymongo

# ==================================================
# CREATE PYTHON INVENTORY SCRIPT
# ==================================================
echo "Creating node inventory Python script..."

cat << EOF > "$PYTHON_SCRIPT"
#!/usr/bin/env python3

import socket
import psutil
import datetime
from pymongo import MongoClient

client = MongoClient("$MONGO_URI")

db = client["test"]
collection = db["nodes"]

hostname = socket.gethostname()
ip_address = "$IP_ADDRESS"
cpu_cores = psutil.cpu_count(logical=True)
memory_gb = round(psutil.virtual_memory().total / (1024 ** 3), 2)

document = {
    "node_name": hostname,
    "ip_address": ip_address,
    "cpu_cores": cpu_cores,
    "memory_gb": memory_gb,
    "last_updated": datetime.datetime.utcnow()
}

# Upsert based on IP address
collection.update_one(
    {"ip_address": ip_address},
    {"\$set": document},
    upsert=True
)

client.close()
EOF

chmod +x "$PYTHON_SCRIPT"

# ==================================================
# CREATE SYSTEMD SERVICE
# ==================================================
echo "Creating systemd service..."

cat << EOF > "$SERVICE_FILE"
[Unit]
Description=One-time Node Inventory Registration to MongoDB
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/python3 $PYTHON_SCRIPT
RemainAfterExit=no

[Install]
WantedBy=multi-user.target
EOF

# ==================================================
# ENABLE AND RUN SERVICE
# ==================================================
echo "Reloading systemd..."
systemctl daemon-reload

echo "Starting node-inventory service..."
systemctl start node-inventory.service

echo "Checking service status..."

echo "Node inventory successfully written (insert or update) to MongoDB."

