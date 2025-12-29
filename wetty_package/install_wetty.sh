#!/bin/bash
set -e

# -----------------------------
# Configuration
# -----------------------------
WETTY_REPO="https://github.com/PalashTinkhede/wetty.git"
INSTALL_DIR="$(pwd)"
WETTY_PORT=3000
SSH_PORT=22
NODE_MAJOR="22"

LOG_DIR="/var/log/wetty"
LOG_FILE="${LOG_DIR}/install-$(date +%Y%m%d-%H%M%S).log"

# -----------------------------
# Derived values
# -----------------------------
USER_NAME="$(logname 2>/dev/null || echo root)"
HOME_DIR="$(eval echo "~$USER_NAME")"
NODE_BIN="/usr/bin/node"
IP_ADDRESS="$(hostname -I | awk '{print $1}')"
SERVICE_FILE="/etc/systemd/system/wetty.service"

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
# Logging setup
# -----------------------------
mkdir -p "${LOG_DIR}"
touch "${LOG_FILE}"
chmod 600 "${LOG_FILE}"

exec > >(tee -a "${LOG_FILE}") 2>&1
trap 'fail "WeTTY installation failed"' ERR

# -----------------------------
# Start
# -----------------------------
echo "==== WeTTY Installation Started ===="
echo "User       : ${USER_NAME}"
echo "IP Address : ${IP_ADDRESS}"
echo "Log file   : ${LOG_FILE}"

########################################
# System update & base packages
########################################
section "System Preparation"

apt update
apt install -y curl git build-essential
success "Base packages installed"

########################################
# SSH setup
########################################
section "SSH Configuration"

if ! command -v sshd >/dev/null 2>&1; then
  apt install -y openssh-server
fi

systemctl enable ssh
systemctl start ssh

if ! ss -tln | grep -q ":${SSH_PORT}"; then
  fail "SSH is not listening on port ${SSH_PORT}"
fi

success "SSH running on port ${SSH_PORT}"

########################################
# Node.js installation
########################################
section "Node.js Installation"

if ! command -v node >/dev/null 2>&1 || ! node -v | grep -q "v${NODE_MAJOR}"; then
  curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash -
  apt install -y nodejs
  success "Node.js v${NODE_MAJOR} installed"
else
  success "Node.js v${NODE_MAJOR} already installed"
fi

echo "Node: $(node -v)"
echo "NPM : $(npm -v)"

########################################
# PNPM
########################################
section "PNPM Installation"

if ! command -v pnpm >/dev/null 2>&1; then
  npm install -g pnpm
fi

success "PNPM ready"

########################################
# Clone & build WeTTY
########################################
section "WeTTY Build"

mkdir -p "${INSTALL_DIR}/wetty_package"
cd "${INSTALL_DIR}/wetty_package"

if [ ! -d wetty ]; then
  git clone "${WETTY_REPO}"
fi
git clone https://github.com/PalashTinkhede/wetty
cd wetty
npm install
npm run build

success "WeTTY built successfully"

########################################
# systemd service
########################################
section "systemd Service Setup"

tee "${SERVICE_FILE}" >/dev/null <<EOF
[Unit]
Description=WeTTY Web Terminal
After=network.target

[Service]
Type=simple
User=${USER_NAME}
WorkingDirectory=${INSTALL_DIR}/wetty_package/wetty
ExecStart=${NODE_BIN} ${INSTALL_DIR}/wetty_package/wetty/build/main.js --port ${WETTY_PORT} --ssh-host ${IP_ADDRESS} --ssh-port ${SSH_PORT}
Restart=always
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable wetty
systemctl restart wetty

success "WeTTY service started"

########################################
# Done
########################################
echo
echo "==== WeTTY Installation Completed Successfully ===="
echo "Access URL : http://${IP_ADDRESS}:${WETTY_PORT}"
echo "Log file   : ${LOG_FILE}"

