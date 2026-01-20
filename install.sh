#!/bin/bash
set +e

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
fail() {
  echo -e "${RED}✖ $1${RESET}"
  echo -e "${RED}See log file: ${LOG_FILE}${RESET}"
  exit 1
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

section "network connectivity"




# Check if default gateway exist
ip route | grep -q default

if [ $? -ne 0 ]; then
    fail "FAIL: No default route. Network is down."
    exit 1
fi

# Check TCP connectivity (DNS port)
timeout 5 bash -c "</dev/tcp/8.8.8.8/53" >/dev/null 2>&1

if [ $? -eq 0 ]; then
    success "PASS: Internet connectivity is available."
    
else
    fail  "FAIL: No internet connectivity."
    exit 1
fi


section "Dependency Check: RAM"



# Required RAM in KB (3 GB = 3 * 1024 * 1024)
REQUIRED_RAM_KB=$((2 * 1024 * 1024))

# Read available memory from /proc/meminfo
AVAILABLE_RAM_KB=$(grep MemAvailable /proc/meminfo | awk '{print $2}')

if [ "$AVAILABLE_RAM_KB" -ge "$REQUIRED_RAM_KB" ]; then
   success "PASS: Available RAM is sufficient ($(($AVAILABLE_RAM_KB / 1024)) MB)."
   
else
   fail "FAIL: Available RAM is insufficient ($(($AVAILABLE_RAM_KB / 1024)) MB). At least 2 GB required."
   exit 1
fi
section "Disk Space check"
REQUIRED_SPACE_KB=$((10 * 1024 * 1024))

# Get available space on root filesystem in KB
AVAILABLE_SPACE_KB=$(df --output=avail / | tail -n 1)

if [ "$AVAILABLE_SPACE_KB" -ge "$REQUIRED_SPACE_KB" ]; then
    success  "PASS: Available disk space is sufficient ($(($AVAILABLE_SPACE_KB / 1024 / 1024)) GB)."
    
else
    fail "FAIL: Available disk space is insufficient ($(($AVAILABLE_SPACE_KB / 1024 / 1024)) GB). At least 30 GB required."

fi
section "CPU Virtualization Check"

if ! lscpu | grep -Eiq 'vmx|svm'; then
  fail "CPU does not support hardware virtualization"
  

else
   success "CPU support virtualization"
   
fi


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

  section "Web dashboard Intergation"
run_step "Setting executable permission" \
  "chmod +x install_webUI.sh"
run_step "Installing web ui " \
  "./install_webUI.sh"


 section "Adding node to the system"
run_step "Setting executable permission" \
  "chmod +x node_detect.sh"
run_step "setting it in environment" \
  "./node_detect.sh"


section "Final Check for cluster"
SUDOERS_FILE="/etc/sudoers.d/edge-backend-pcs"
RULE="sysadmin ALL=(root) NOPASSWD: /usr/sbin/pcs status xml"



# -----------------------------
# Create sudoers rule
# -----------------------------
echo "Adding sudoers rule for pcs status xml..."

echo "$RULE" > "$SUDOERS_FILE"

# Correct permissions (MANDATORY)
chmod 440 "$SUDOERS_FILE"
chown root:root "$SUDOERS_FILE"

# -----------------------------
# Validate sudoers syntax
# -----------------------------
if visudo -cf "$SUDOERS_FILE"; then
  success "Sudoers rule installed and validated successfully."
else
  fail "ERROR: Sudoers validation failed. Rolling back."
  rm -f "$SUDOERS_FILE"
  exit 1
fi


section "INSTALLATION COMPLETE"
success "All components installed successfully"

sudo reboot


