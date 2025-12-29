#!/bin/bash
set -e

#################################################
# Kimchi + KVM + Libvirt Installer (Ubuntu 24.04)
#################################################

# -----------------------------
# Configuration
# -----------------------------
USER_NAME="$(logname 2>/dev/null || echo root)"
EDGE_BASE="/home/${USER_NAME}/Downloads/Edge-Computing-main"
WOK_CUSTOM_UI="${EDGE_BASE}/wok_package/wok"

LOG_DIR="/var/log/kimchi-wok"
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
trap 'fail "Kimchi + KVM installation failed"' ERR

# -----------------------------
# Start
# -----------------------------
echo "==== Kimchi + KVM + Wok Installation Started ===="
echo "User     : ${USER_NAME}"
echo "Log file : ${LOG_FILE}"

############################################
# 1. UI repositories
############################################
section "Custom UI Preparation"

mkdir -p "${EDGE_BASE}/wok_package"
cd "${EDGE_BASE}/wok_package"

mkdir -p wok
cd wok

git clone https://github.com/PalashTinkhede/ui.git
git clone https://github.com/PalashTinkhede/plugins.git

success "Custom UI repositories cloned"

############################################
# 2. CPU Virtualization Check
############################################
section "CPU Virtualization Check"

if ! lscpu | grep -Eiq 'vmx|svm'; then
  fail "CPU does not support hardware virtualization"
fi

success "Hardware virtualization supported"

############################################
# 3. Node.js
############################################
section "Node.js Installation"

if ! command -v node >/dev/null 2>&1; then
  curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
  apt install -y nodejs
fi

echo "Node: $(node -v)"
echo "NPM : $(npm -v)"
success "Node.js ready"

############################################
# 4. System Update
############################################
section "System Update"

apt update -y
apt upgrade -y
success "System updated"

############################################
# 5. KVM + Libvirt
############################################
section "KVM & Libvirt Installation"

apt install -y \
  qemu-kvm \
  libvirt-daemon-system \
  libvirt-clients \
  bridge-utils \
  virtinst \
  cpu-checker

systemctl enable --now libvirtd

if ! kvm-ok >/dev/null 2>&1; then
  fail "KVM is not available on this system"
fi

success "KVM and Libvirt operational"

############################################
# 6. User group permissions
############################################
section "User Permissions"

if [ -n "$SUDO_USER" ]; then
  usermod -aG libvirt,kvm "$SUDO_USER"
fi

success "User added to libvirt and kvm groups"

############################################
# 7. Build & auxiliary tools
############################################
section "Build Dependencies"

apt install -y \
  git wget curl sudo \
  build-essential autoconf automake libtool pkg-config \
  gettext autopoint autoconf-archive \
  libxml2-dev libxslt1-dev libssl-dev \
  xsltproc docbook-xsl \
  ca-certificates nginx

success "Build dependencies installed"

############################################
# 8. Python runtime dependencies
############################################
section "Python Dependencies"

apt install -y \
  python3 python3-dev python3-setuptools python3-wheel \
  python3-libvirt python3-cherrypy3 python3-jsonschema \
  python3-lxml python3-psutil python3-six python3-openssl \
  python3-routes python3-websockify python3-parted \
  python3-guestfs python3-ldap python3-pam \
  libguestfs-tools spice-html5 novnc websockify

success "Python runtime dependencies installed"

############################################
# 9. Install Wok
############################################
section "Wok Installation"

cd /opt
[ ! -d wok ] && git clone https://github.com/kimchi-project/wok.git
cd wok
./autogen.sh --system
make
make install

success "Wok installed"

############################################
# 10. Install Kimchi
############################################
section "Kimchi Installation"

cd /opt
[ ! -d kimchi ] && git clone https://github.com/kimchi-project/kimchi.git
cd kimchi

apt install -y gcc make autoconf automake git python3-pip gettext pkgconf xsltproc python3-dev
pip3 install -r requirements-dev.txt --break-system-packages
apt install -y python3-configobj python3-lxml python3-magic python3-paramiko python3-ldap \
  spice-html5 novnc qemu-kvm python3-libvirt python3-parted python3-ethtool \
  python3-guestfs python3-pil python3-cherrypy3 nfs-common sosreport open-iscsi \
  libguestfs-tools libnl-route-3-dev

pip3 install -r requirements-UBUNTU.txt --break-system-packages
./autogen.sh --system
make
make install

success "Kimchi installed"

############################################
# 11. Python 3.12 SafeConfigParser patch
############################################
section "Python 3.12 Compatibility Patch"

SEARCH="from configparser import SafeConfigParser"
REPLACE="from configparser import ConfigParser as SafeConfigParser"
DIRS="/usr/lib/python3/dist-packages"

grep -Rl "$SEARCH" $DIRS | while read -r file; do
  cp "$file" "$file.bak"
  sed -i "s|$SEARCH|$REPLACE|" "$file"
done

success "SafeConfigParser patched"

############################################
# 12. Enable Kimchi plugin
############################################
section "Kimchi Plugin Linking"

PLUGIN_DIR="/usr/share/wok/plugins"
KIMCHI_PY="/usr/lib/python3/dist-packages/wok/plugins/kimchi"

mkdir -p "$PLUGIN_DIR"
rm -rf "$PLUGIN_DIR/kimchi"

if [ -d "$KIMCHI_PY" ]; then
  ln -s "$KIMCHI_PY" "$PLUGIN_DIR/kimchi"
else
  fail "Kimchi plugin not found at ${KIMCHI_PY}"
fi

apt install -y python3-ldap python3-pam python3-cheetah
success "Kimchi plugin enabled"

############################################
# 13. Apply custom UI and start wokd
############################################
section "Custom UI & Service Start"
cd $WOK_CUSTOM_UI
git clone https://github.com/PalashTinkhede/ui
git clone https://github.com/PalashTinkhede/plugins
rm -rf /usr/share/wok
mv "${WOK_CUSTOM_UI}" /usr/share/

systemctl daemon-reload
systemctl enable wokd
systemctl restart wokd

success "wokd started"

############################################
# 14. Final status
############################################
IP="$(hostname -I | awk '{print $1}')"

echo
echo "==== INSTALLATION COMPLETED SUCCESSFULLY ===="
echo "Web UI        : https://${IP}:8001"
echo "VM Console WS : ws://${IP}:6080"
echo "Log file      : ${LOG_FILE}"

