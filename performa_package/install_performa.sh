#!/bin/bash
set -e

################################################################################
#                             Performa Installer                               #
#                Installs Node.js, Performa, and systemd service                #
################################################################################

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------
INSTALL_DIR="/opt/performa"
ORG_DIR="$(pwd)"

BIN_PATH="${INSTALL_DIR}/satellite.bin"
LOCAL_CONFIG="performa_package/config.json"

NODE_MAJOR="22"
DOWNLOAD_URL="https://github.com/jhuckaby/performa-satellite/releases/latest/download/performa-satellite-linux-x64"

LOG_DIR="/var/log/performa"
LOG_FILE="${LOG_DIR}/install-$(date +%Y%m%d-%H%M%S).log"

# ------------------------------------------------------------------------------
# Formatting helpers
# ------------------------------------------------------------------------------
BOLD="\e[1m"
GREEN="\e[32m"
RED="\e[31m"
BLUE="\e[34m"
RESET="\e[0m"

section() {
  echo -e "\n${BOLD}${BLUE}==================== $1 ====================${RESET}"
}

success() {
  echo -e "${GREEN}✔ $1${RESET}"
}

fail() {
  echo -e "${RED}✖ $1${RESET}"
  echo -e "${RED}See log file: ${LOG_FILE}${RESET}"
  exit 1
}

# ------------------------------------------------------------------------------
# Root check
# ------------------------------------------------------------------------------
if [ "$EUID" -ne 0 ]; then
  fail "ERROR: Please run this script as root (sudo)."
  exit 1
fi

# ------------------------------------------------------------------------------
# Logging setup
# ------------------------------------------------------------------------------
mkdir -p "${LOG_DIR}"
touch "${LOG_FILE}"
chmod 600 "${LOG_FILE}"

# Redirect all output to log file
exec > >(tee -a "${LOG_FILE}") 2>&1

# ------------------------------------------------------------------------------
# Error handling
# ------------------------------------------------------------------------------
trap 'fail "Installation failed"' ERR

# ------------------------------------------------------------------------------
# Start installation
# ------------------------------------------------------------------------------
success "==== Performa Satellite Installation Started ===="
echo "Log file: ${LOG_FILE}"

################################################################################
# 1. Node.js Installation
################################################################################
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

echo "Node Version : $(node -v)"
echo "NPM Version  : $(npm -v)"

################################################################################
# 2. Performa Setup
################################################################################
section "Performa Setup"

mkdir -p "${INSTALL_DIR}"
cd /opt/performa

git clone https://github.com/Palash-Tinkhede/performa.git .
success "cloning complete"
success "installing dependencies"
npm install
node bin/build.js dist
/opt/performa/bin/control.sh setup

################################################################################
# 3. Service Installation (systemd)
################################################################################
section "Service Installation"

SERVICE_NAME="performa"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
PERFORMA_DIR="/opt/performa"
CONTROL_SCRIPT="${PERFORMA_DIR}/bin/control.sh"

success "Configuring systemd service..."

# Validate control script
if [ ! -f "${CONTROL_SCRIPT}" ]; then
  fail "ERROR: control.sh not found at ${CONTROL_SCRIPT}"
  exit 1
fi

# Ensure executable
chmod +x "${CONTROL_SCRIPT}"

# Create systemd service file
cat <<EOF > "${SERVICE_FILE}"
[Unit]
Description=Performa Service
After=network.target
Wants=network.target

[Service]
Type=forking
ExecStart=${CONTROL_SCRIPT} start
ExecStop=${CONTROL_SCRIPT} stop
ExecReload=${CONTROL_SCRIPT} restart
WorkingDirectory=${PERFORMA_DIR}
User=root
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

success "Service file created at ${SERVICE_FILE}"

# Reload and enable service
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable "${SERVICE_NAME}.service"
systemctl start "${SERVICE_NAME}.service"

echo
success "==================== Service Status ===================="
systemctl status "${SERVICE_NAME}.service" --no-pager

################################################################################
# Completion
################################################################################
echo
success "==== Installation completed successfully ===="
echo "Log file saved at: ${LOG_FILE}"

echo "------------------------------------------------"
success "Installation Complete! (Performa + Satellite)"
success "Master UI: http://$(hostname -I | awk '{print $1}'):5511"
echo "------------------------------------------------"
