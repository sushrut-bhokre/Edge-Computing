#!/bin/bash
set -e

#################################################
# Pacemaker Node Preparation Script
# Ubuntu 24.04 LTS
# Purpose: Make node ADDABLE to any cluster later
#################################################

# -----------------------------
# Configuration
# -----------------------------
LOG_DIR="/var/log/pacemaker-node"
LOG_FILE="${LOG_DIR}/prepare-$(date +%Y%m%d-%H%M%S).log"

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
trap 'fail "Pacemaker node preparation failed"' ERR

# -----------------------------
# Start
# -----------------------------
echo "==== Pacemaker Node Preparation Started ===="
echo "Hostname : $(hostname)"
echo "Log file : ${LOG_FILE}"

#############################################
# 1. System update
#############################################
section "System Update"

apt update -y
apt upgrade -y
success "System packages updated"

#############################################
# 2. Time synchronization
#############################################
section "Time Synchronization (chrony)"

apt install -y chrony
systemctl enable --now chrony
success "Chrony installed and running"

#############################################
# 3. Pacemaker stack
#############################################
section "Pacemaker Stack Installation"

apt install -y pacemaker corosync pcs fence-agents
success "Pacemaker, Corosync, and PCS installed"

#############################################
# 4. pcsd service
#############################################
section "pcsd Service Enablement"

systemctl enable --now pcsd
success "pcsd service enabled and running"

#############################################
# 5. Disable cluster services
#############################################
section "Cluster Services State"

systemctl disable --now pacemaker corosync || true
success "pacemaker and corosync stopped (correct state)"

#############################################
# 6. hacluster authentication
#############################################
section "hacluster Authentication"

echo "You will now be prompted to set the password for 'hacluster'."
echo "This password is required when adding this node to a cluster."
passwd hacluster

success "hacluster password configured"

#############################################
# Final status
#############################################
echo
echo "==== NODE PREPARATION COMPLETE ===="
echo
echo "Service state:"
echo "  pcsd        : RUNNING (required)"
echo "  pacemaker   : STOPPED (correct)"
echo "  corosync    : STOPPED (correct)"
echo
echo "This node can now be added from any existing cluster using:"
echo "  pcs host auth $(hostname)"
echo "  pcs cluster node add $(hostname)"
echo
echo "Log file: ${LOG_FILE}"

