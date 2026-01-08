#!/bin/bash
set -e

#################################################
# Pacemaker Node & Web UI Preparation Script
# Ubuntu 24.04 LTS
# Purpose: Prepare node and install modern Web UI
#################################################

# -----------------------------
# Configuration
# -----------------------------
LOG_DIR="/var/log/pacemaker-node"
LOG_FILE="${LOG_DIR}/prepare-$(date +%Y%m%d-%H%M%S).log"
BUILD_DIR="/tmp/pcs-web-ui-build"

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
  echo "ERROR: Run this script as root (sudo)."
  exit 1
fi

# -----------------------------
# Logging setup
# -----------------------------
mkdir -p "${LOG_DIR}"
touch "${LOG_FILE}"
chmod 600 "${LOG_FILE}"

exec > >(tee -a "${LOG_FILE}") 2>&1
trap 'fail "Script execution interrupted or failed unexpectedly"' ERR

# -----------------------------
# Start
# -----------------------------
section "Initialization"
success "Pacemaker Node + Web UI Preparation Started"
success "Hostname : $(hostname)"

#############################################
# 1. System update
#############################################
section "System Update"
apt update -y && apt upgrade -y || fail "Failed to update system packages"
success "System packages updated"

#############################################
# 2. Time synchronization
#############################################
section "Time Synchronization (chrony)"
apt install -y chrony || fail "Failed to install chrony"
systemctl enable --now chrony || fail "Failed to start chrony"
success "Chrony installed and running"

#############################################
# 3. Pacemaker stack
#############################################
section "Pacemaker Stack Installation"
apt install -y pacemaker corosync pcs fence-agents || fail "Failed to install Pacemaker stack"
success "Pacemaker, Corosync, and PCS installed"

#############################################
# 4. pcsd service
#############################################
section "pcsd Service Enablement"
systemctl enable --now pcsd || fail "Failed to enable/start pcsd"
success "pcsd service enabled and running"

#############################################
# 5. Disable cluster services
#############################################
section "Cluster Services State"
systemctl disable --now pacemaker corosync || success "Services already stopped"
success "pacemaker and corosync set to stopped (correct initial state)"

#############################################
# 6. Build & Install Web UI
#############################################
section "Web UI Build Dependencies"
apt install -y git autoconf automake make pkg-config npm nodejs || fail "Failed to install build dependencies"
success "Dependencies installed"

section "Cloning and Building PCS Web UI"
rm -rf "$BUILD_DIR"
git clone https://github.com/ClusterLabs/pcs-web-ui.git "$BUILD_DIR" || fail "Failed to clone repository"
cd "$BUILD_DIR"

./autogen.sh || fail "autogen.sh failed"
./configure --disable-cockpit --with-pcsd-webui-dir=/usr/share/pcsd/public/ui || fail "Configuration failed"
make || fail "Build (make) failed"
make install || fail "Installation (make install) failed"
success "Web UI built and installed to /usr/share/pcsd/public/ui"

#############################################
# 7. hacluster authentication
#############################################
section "hacluster Authentication"
echo -e "${BOLD}Action Required:${RESET} Set the password for 'hacluster' (UI login)"
read -rs -p "Enter password: " HA_PASS
echo
echo "hacluster:$HA_PASS" | chpasswd || fail "Failed to set password for hacluster"
success "hacluster password configured"

systemctl restart pcsd || fail "Failed to restart pcsd after UI installation"
success "pcsd restarted successfully"

#############################################
# Cleanup & Final status
#############################################
section "Cleanup"
rm -rf "$BUILD_DIR"
success "Temporary build files removed"

IP_ADDR=$(hostname -I | awk '{print $1}')

echo -e "\n${BOLD}${GREEN}==== PREPARATION COMPLETE ====${RESET}"
echo "Node Status:"
echo "  pcsd (API/UI) : RUNNING"
echo "  pacemaker     : STOPPED"
echo "  corosync      : STOPPED"
echo
echo "Access Information:"
echo "  URL           : https://${IP_ADDR}:2224"
echo "  Username      : hacluster"
echo
success "Node is ready to be added to a cluster"
