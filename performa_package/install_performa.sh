#!/bin/bash
set -e

# -----------------------------
# Configuration
# -----------------------------
INSTALL_DIR="/opt/performa"
BIN_PATH="${INSTALL_DIR}/satellite.bin"
LOCAL_CONFIG="performa_package/config.json"
NODE_MAJOR="22"
DOWNLOAD_URL="https://github.com/jhuckaby/performa-satellite/releases/latest/download/performa-satellite-linux-x64"

LOG_DIR="/var/log/performa"
LOG_FILE="${LOG_DIR}/install-$(date +%Y%m%d-%H%M%S).log"

# -----------------------------
# Formatting helpers
# -----------------------------
BOLD="\e[1m"
GREEN="\e[32m"
RED="\e[31m"
BLUE="\e[34m"
RESET="\e[0m"

section() {
  echo -e "\n${BOLD}${BLUE}=== $1 ===${RESET}"
}

success() {
  echo -e "${GREEN}✔ $1${RESET}"
}

fail() {
  echo -e "${RED}✖ $1${RESET}"
  echo -e "${RED}See log file: ${LOG_FILE}${RESET}"
  exit 1
}

# -----------------------------
# Root check
# -----------------------------
if [ "$EUID" -ne 0 ]; then
  echo "ERROR: Please run this script as root (sudo)."
  exit 1
fi

# -----------------------------
# Prepare logging
# -----------------------------
mkdir -p "${LOG_DIR}"
touch "${LOG_FILE}"
chmod 600 "${LOG_FILE}"

# Redirect ALL output to log file
exec > >(tee -a "${LOG_FILE}") 2>&1

# -----------------------------
# Trap errors
# -----------------------------
trap 'fail "Installation failed"' ERR

# -----------------------------
# Start installation
# -----------------------------
echo "==== Performa Satellite Installation Started ===="
echo "Log file: ${LOG_FILE}"

########################################
# 1. Install Node.js v22
########################################
section "Node.js Installation"

if ! command -v node >/dev/null 2>&1 || ! node -v | grep -q "v${NODE_MAJOR}"; then
  apt-get update
  apt-get install -y ca-certificates curl gnupg
  curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash -
  apt-get install -y nodejs
  success "Node.js v${NODE_MAJOR} installed"
else
  success "Node.js v${NODE_MAJOR} already present"
fi

echo "Node: $(node -v)"
echo "NPM : $(npm -v)"

########################################
# 2. Install Performa Satellite
########################################
section "Performa  Setup"

cd /opt
git clone https://github.com/Palash-Tinkhede/performa.git
cd performa	
npm install
node bin/build.js dist
/opt/performa/bin/control.sh setup
/opt/performa/bin/control.sh start



echo "------------------------------------------------"
echo "Installation Complete!"
echo "Master UI: http://$(hostname -I | awk '{print $1}'):5511"
echo "------------------------------------------------"

