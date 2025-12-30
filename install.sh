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


# -----------------------------
# Git dependency check
# -----------------------------
section "Dependency Check: Git"

if command -v git >/dev/null 2>&1; then
  success "Git is already installed ($(git --version))"
else
  log "Git not found. Installing Git..."

  if command -v apt >/dev/null 2>&1; then
    run_step "Updating package index" "apt update -y"
    run_step "Installing Git" "apt install -y git"
  else
    error "Unsupported package manager. Install Git manually."
    exit 1
  fi

  success "Git installed successfully ($(git --version))"
fi

# -----------------------------
# pip3 dependency check (>=23)
# -----------------------------
section "Dependency Check: pip3"

if ! command -v pip3 >/dev/null 2>&1; then
  sudo apt install python3-pip -y
  
fi

PIP_VERSION_RAW=$(pip3 --version | awk '{print $2}')
PIP_MAJOR_VERSION=$(echo "$PIP_VERSION_RAW" | cut -d. -f1)

log "Detected pip3 version: $PIP_VERSION_RAW"

if [ "$PIP_MAJOR_VERSION" -lt 23 ]; then
  log "pip3 version is below 23. Upgrading pip3..."

  if command -v apt >/dev/null 2>&1; then
    run_step "Upgrading pip3 using python3 -m pip" \
      "python3 -m pip install --upgrade pip"
hash -r
  else
    error "Unsupported package manager. Upgrade pip3 manually."
    exit 1
  fi

  NEW_PIP_VERSION=$(pip3 --version | awk '{print $2}')
  NEW_PIP_MAJOR=$(echo "$NEW_PIP_VERSION" | cut -d. -f1)

  if [ "$NEW_PIP_MAJOR" -lt 23 ]; then
    error "pip3 upgrade failed. Required pip >= 23, found $NEW_PIP_VERSION"
    exit 1
  fi

  success "pip3 upgraded successfully to version $NEW_PIP_VERSION"
else
  success "pip3 meets minimum version requirement (>=23)"
fi


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
