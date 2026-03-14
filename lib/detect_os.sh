#!/usr/bin/env bash
# =============================================================================
# detect_os.sh - OS detection module
# =============================================================================

# Source core functions
if [[ -n ${LIB_DIR:-} ]]; then
  source "${LIB_DIR}/core.sh"
else
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source "${SCRIPT_DIR}/core.sh"
fi

# Global variables
export OS_TYPE=""
export OS_DISTRO=""
export OS_VERSION=""
export PACKAGE_MANAGER=""
export IS_WSL=false

# -----------------------------------------------------------------------------
# Detect OS type
# -----------------------------------------------------------------------------
detect_os() {
  log_step "Detecting operating system..."

  # Check WSL
  if [[ -f /proc/version ]] && grep -qi "microsoft\|wsl" /proc/version 2>/dev/null; then
    IS_WSL=true
    log_info "Running under WSL"
  fi

  # Detect OS
  if [[ $OSTYPE == "dar"* ]]; then
    OS_TYPE="macos"
    detect_macos
  elif [[ $OSTYPE == "linux-gnu"* ]]; then
    OS_TYPE="linux"
    detect_linux
  else
    log_error "Unsupported OS: $OSTYPE"
    exit 1
  fi

  log_success "Detected: ${OS_DISTRO} ${OS_VERSION} (${PACKAGE_MANAGER})"
}

# -----------------------------------------------------------------------------
# Detect macOS details
# -----------------------------------------------------------------------------
detect_macos() {
  OS_DISTRO="macos"

  # Get macOS version
  if cmd_exists sw_vers; then
    OS_VERSION=$(sw_vers -productVersion)
  else
    OS_VERSION="unknown"
  fi

  # Determine package manager
  if cmd_exists brew; then
    PACKAGE_MANAGER="brew"
  elif cmd_exists port; then
    PACKAGE_MANAGER="macports"
  else
    PACKAGE_MANAGER="brew"
    log_warn "Homebrew not found, will attempt to install"
  fi
}

# -----------------------------------------------------------------------------
# Detect Linux details
# -----------------------------------------------------------------------------
detect_linux() {
  # Check /etc/os-release first (modern distros)
  if [[ -f /etc/os-release ]]; then
    source /etc/os-release

    case "$ID" in
    ubuntu)
      OS_DISTRO="ubuntu"
      OS_VERSION="$VERSION_ID"
      ;;
    debian)
      OS_DISTRO="debian"
      OS_VERSION="$VERSION_ID"
      ;;
    fedora)
      OS_DISTRO="fedora"
      OS_VERSION="$VERSION_ID"
      ;;
    arch)
      OS_DISTRO="arch"
      OS_VERSION="rolling"
      ;;
    opensuse | sles)
      OS_DISTRO="opensuse"
      OS_VERSION="$VERSION_ID"
      ;;
    alpine)
      OS_DISTRO="alpine"
      OS_VERSION="$VERSION_ID"
      ;;
    *)
      OS_DISTRO="$ID"
      OS_VERSION="${VERSION_ID:-unknown}"
      ;;
    esac
  else
    # Fallback for older distros
    if [[ -f /etc/centos-release ]]; then
      OS_DISTRO="centos"
      OS_VERSION=$(grep -oE '[0-9]+\.[0-9]+' /etc/centos-release | head -1)
    elif [[ -f /etc/redhat-release ]]; then
      OS_DISTRO="rhel"
      OS_VERSION=$(grep -oE '[0-9]+\.[0-9]+' /etc/redhat-release | head -1)
    elif [[ -f /etc/debian_version ]]; then
      OS_DISTRO="debian"
      OS_VERSION=$(cat /etc/debian_version)
    else
      OS_DISTRO="unknown"
      OS_VERSION="unknown"
    fi
  fi

  # Determine package manager
  if cmd_exists apt-get; then
    PACKAGE_MANAGER="apt"
  elif cmd_exists dnf; then
    PACKAGE_MANAGER="dnf"
  elif cmd_exists pacman; then
    PACKAGE_MANAGER="pacman"
  elif cmd_exists zypper; then
    PACKAGE_MANAGER="zypper"
  elif cmd_exists apk; then
    PACKAGE_MANAGER="apk"
  else
    log_error "No supported package manager found"
    exit 1
  fi
}

# -----------------------------------------------------------------------------
# Check if running as root
# -----------------------------------------------------------------------------
is_root() {
  [[ $EUID -eq 0 ]]
}

# -----------------------------------------------------------------------------
# Get sudo privilege
# -----------------------------------------------------------------------------
get_sudo() {
  if is_root; then
    SUDO=""
    return 0
  fi

  if cmd_exists sudo; then
    SUDO="sudo"
  elif cmd_exists doas; then
    SUDO="doas"
  else
    log_error "Neither sudo nor doas available"
    exit 1
  fi
}

# -----------------------------------------------------------------------------
# Export detection results
# -----------------------------------------------------------------------------
export_os_info() {
  export OS_TYPE
  export OS_DISTRO
  export OS_VERSION
  export PACKAGE_MANAGER
  export IS_WSL

  log_debug "OS_TYPE=$OS_TYPE"
  log_debug "OS_DISTRO=$OS_DISTRO"
  log_debug "OS_VERSION=$OS_VERSION"
  log_debug "PACKAGE_MANAGER=$PACKAGE_MANAGER"
  log_debug "IS_WSL=$IS_WSL"
}
