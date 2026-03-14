#!/usr/bin/env bash
# =============================================================================
# modules/docker.sh - Docker installation module
# =============================================================================

# Source dependencies
if [[ -n ${LIB_DIR:-} ]]; then
  source "${LIB_DIR}/core.sh"
  source "${LIB_DIR}/detect_os.sh"
  source "${LIB_DIR}/install_pkg.sh"
else
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  source "${SCRIPT_DIR}/lib/core.sh"
  source "${SCRIPT_DIR}/lib/detect_os.sh"
  source "${SCRIPT_DIR}/lib/install_pkg.sh"
fi

# -----------------------------------------------------------------------------
# Check if Docker is already installed
# -----------------------------------------------------------------------------
check_docker_installed() {
  if cmd_exists docker; then
    local version
    version=$(docker --version 2>/dev/null || echo "unknown")
    log_info "Docker already installed: $version"
    return 0
  fi
  return 1
}

# -----------------------------------------------------------------------------
# Remove old Docker installations
# -----------------------------------------------------------------------------
cleanup_old_docker() {
  log_step "Cleaning up old Docker installations..."

  case "$PACKAGE_MANAGER" in
  apt)
    # 与本站博客《Debian 和 Ubuntu 上安装 Docker Engine》一致：彻底清理旧配置
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
      $SUDO apt-get remove --purge -y $pkg 2>/dev/null || true
    done
    $SUDO rm -f /etc/apt/sources.list.d/docker.list
    $SUDO rm -f /etc/apt/sources.list.d/docker.sources
    $SUDO rm -f /etc/apt/sources.list.d/*docker*
    $SUDO rm -f /etc/apt/keyrings/docker*
    $SUDO rm -f /usr/share/keyrings/docker*
    $SUDO rm -f /usr/share/keyrings/*docker*
    $SUDO apt-get clean
    apt_update
    ;;
  brew)
    brew uninstall docker 2>/dev/null || true
    ;;
  esac

  log_success "Cleanup completed"
}

# -----------------------------------------------------------------------------
# Install Docker on Debian/Ubuntu
# -----------------------------------------------------------------------------
install_docker_apt() {
  log_step "Installing Docker on Debian/Ubuntu..."

  # Install prerequisites
  $SUDO apt-get install -y ca-certificates curl gnupg lsb-release

  # Create keyrings directory
  $SUDO install -m 0755 -d /etc/apt/keyrings

  # Add Docker GPG key
  if [[ $OS_DISTRO == "ubuntu" ]]; then
    $SUDO curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
      -o /etc/apt/keyrings/docker.asc
  else
    $SUDO curl -fsSL https://download.docker.com/linux/debian/gpg \
      -o /etc/apt/keyrings/docker.asc
  fi

  $SUDO chmod a+r /etc/apt/keyrings/docker.asc

  # 与本站博客一致：使用 deb822 格式仓库（/etc/apt/sources.list.d/docker.sources）
  _tee_sudo() { if [[ -n "${SUDO:-}" ]]; then $SUDO tee "$@"; else tee "$@"; fi; }
  if [[ $OS_DISTRO == "ubuntu" ]]; then
    _tee_sudo /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(lsb_release -cs 2>/dev/null || true)
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
Architectures: $(dpkg --print-architecture)
EOF
  else
    local codename
    codename=$( ( . /etc/os-release 2>/dev/null && echo "${VERSION_CODENAME:-bookworm}" ) || echo "bookworm" )
    _tee_sudo /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: ${codename}
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
Architectures: $(dpkg --print-architecture)
EOF
  fi
  unset -f _tee_sudo

  # Install Docker
  apt_update
  $SUDO apt-get install -y docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin

  log_success "Docker installed successfully"
}

# -----------------------------------------------------------------------------
# Install Docker on macOS
# -----------------------------------------------------------------------------
install_docker_macos() {
  log_step "Installing Docker on macOS..."

  if ! cmd_exists brew; then
    log_error "Homebrew not found. Please install Homebrew first."
    return 1
  fi

  brew_install docker

  log_success "Docker installed. Please start Docker Desktop from Applications."
}

# -----------------------------------------------------------------------------
# Configure Docker (免 sudo)
# -----------------------------------------------------------------------------
configure_docker() {
  log_step "Configuring Docker..."

  if is_root; then
    log_info "Running as root, skipping sudo configuration"
    return 0
  fi

  # Create docker group if not exists
  if ! getent group docker >/dev/null 2>&1; then
    $SUDO groupadd docker
  fi

  # Add current user to docker group
  $SUDO usermod -aG docker "$USER"

  log_success "Docker configured. Please log out and log back in for changes to take effect."
}

# -----------------------------------------------------------------------------
# Install Docker Compose (standalone)
# -----------------------------------------------------------------------------
install_docker_compose() {
  if cmd_exists docker-compose; then
    log_info "Docker Compose already installed"
    return 0
  fi

  log_step "Installing Docker Compose..."

  local version="2.24.0"
  local arch
  arch=$(uname -m)
  case "$arch" in
  x86_64) arch="x86_64" ;;
  aarch64 | arm64) arch="aarch64" ;;
  *)
    log_warn "Unknown architecture: $arch"
    return 1
    ;;
  esac

  $SUDO curl -fsSL "https://github.com/docker/compose/releases/download/v${version}/docker-compose-linux-${arch}" \
    -o /usr/local/bin/docker-compose

  $SUDO chmod +x /usr/local/bin/docker-compose

  log_success "Docker Compose installed"
}

# -----------------------------------------------------------------------------
# Main Docker installation function
# -----------------------------------------------------------------------------
install_docker() {
  if check_docker_installed; then
    log_info "Docker is already installed"
    return 0
  fi

  log_step "Starting Docker installation..."

  # Cleanup old installations
  cleanup_old_docker

  # Install Docker based on OS
  case "$OS_TYPE" in
  macos)
    install_docker_macos
    ;;
  linux)
    install_docker_apt
    configure_docker
    ;;
  esac

  # Verify installation
  if cmd_exists docker; then
    log_success "Docker installation completed"
    log_info "Docker version: $(docker --version)"
  else
    log_error "Docker installation failed"
    return 1
  fi
}

# -----------------------------------------------------------------------------
# Check if Podman is installed
# -----------------------------------------------------------------------------
check_podman_installed() {
  if cmd_exists podman; then
    local version
    version=$(podman --version 2>/dev/null || echo "unknown")
    log_info "Podman already installed: $version"
    return 0
  fi
  return 1
}

# -----------------------------------------------------------------------------
# Install Podman on Debian/Ubuntu
# -----------------------------------------------------------------------------
install_podman_apt() {
  log_step "Installing Podman on Debian/Ubuntu..."

  # Add Podman repository
  OS_VERSION=$(lsb_release -rs)

  # Install prerequisites
  $SUDO apt-get update -qq
  $SUDO apt-get install -y curl wget gnupg2

  # Add Podman repository
  echo "deb https://download.opensuse.org/repositories/deb:/podman:/stable/xUbuntu_${OS_VERSION}/ /" |
    $SUDO tee /etc/apt/sources.list.d/podman.list >/dev/null

  # Add GPG key
  $SUDO curl -L "https://download.opensuse.org/repositories/deb:/podman:/stable/xUbuntu_${OS_VERSION}/Release.key" |
    $SUDO apt-key add - >/dev/null 2>&1

  # Install Podman
  apt_update
  $SUDO apt-get install -y podman

  log_success "Podman installed successfully"
}

# -----------------------------------------------------------------------------
# Install Podman on macOS
# -----------------------------------------------------------------------------
install_podman_macos() {
  log_step "Installing Podman on macOS..."

  # Podman on macOS requires running a VM
  if ! cmd_exists brew; then
    log_error "Homebrew not found. Please install Homebrew first."
    return 1
  fi

  brew_install podman

  log_success "Podman installed"
  log_info "Run 'podman machine init' to set up the Podman VM"
}

# -----------------------------------------------------------------------------
# Install Podman on Fedora/RHEL
# -----------------------------------------------------------------------------
install_podman_fedora() {
  log_step "Installing Podman on Fedora/RHEL..."

  $SUDO dnf install -y podman

  log_success "Podman installed successfully"
}

# -----------------------------------------------------------------------------
# Main Podman installation function
# -----------------------------------------------------------------------------
install_podman() {
  if check_podman_installed; then
    log_info "Podman is already installed"
    return 0
  fi

  log_step "Starting Podman installation..."

  # Install Podman based on OS
  case "$OS_TYPE" in
  macos)
    install_podman_macos
    ;;
  linux)
    case "$OS_DISTRO" in
    fedora | rhel | centos)
      install_podman_fedora
      ;;
    ubuntu | debian)
      install_podman_apt
      ;;
    *)
      log_error "Unsupported distro for Podman: $OS_DISTRO"
      return 1
      ;;
    esac
    ;;
  esac

  # Verify installation
  if cmd_exists podman; then
    log_success "Podman installation completed"
    log_info "Podman version: $(podman --version)"
  else
    log_error "Podman installation failed"
    return 1
  fi
}
