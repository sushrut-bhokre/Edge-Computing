#!/bin/bash
set -e

# -----------------------------
# Color & formatting helpers
# -----------------------------
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"
BOLD="\e[1m"
RESET="\e[0m"

timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}

log() {
  echo -e "${CYAN}[$(timestamp)]${RESET} $1"
}

success() {
  echo -e "${GREEN}✔ $1${RESET}"
}

error() {
  echo -e "${RED}✖ $1${RESET}"
}

section() {
  echo
  echo -e "${BOLD}${BLUE}============================================================${RESET}"
  echo -e "${BOLD}${BLUE} $1${RESET}"
  echo -e "${BOLD}${BLUE}============================================================${RESET}"
  echo
}

run_step() {
  local description="$1"
  local command="$2"

  log "$description"
  if eval "$command"; then
    success "$description completed"
  else
    error "$description failed"
    exit 1
  fi
}

# -----------------------------
# Root check
# -----------------------------
if [ "$EUID" -ne 0 ]; then
  error "Run this script as root (sudo)."
  exit 1
fi

# -----------------------------
# Execution starts
# -----------------------------
section "EDGE SOLUTION INITIALIZATION"

section "Monitoring Solution"
run_step "Setting executable permission" \
  "chmod +x performa_package/install_performa.sh"
run_step "Installing Performa" \
  "./performa_package/install_performa.sh"

section "Remote Access Solution"
run_step "Setting executable permission" \
  "chmod +x wetty_package/install_wetty.sh"
run_step "Installing Wetty" \
  "./wetty_package/install_wetty.sh"

section "Virtualization Solution"
run_step "Setting executable permission" \
  "chmod +x wok_package/install_wok.sh"
run_step "Installing Wok" \
  "./wok_package/install_wok.sh"

section "Cluster Management Solution"
run_step "Setting executable permission" \
  "chmod +x install_clusterlabs.sh"
run_step "Installing ClusterLabs" \
  "./install_clusterlabs.sh"

section "INSTALLATION COMPLETE"
success "All components installed successfully"

sudo reboot
