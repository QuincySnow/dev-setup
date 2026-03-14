#!/usr/bin/env bash
# =============================================================================
# install_pkg.sh - Package manager wrapper
# =============================================================================

# Source dependencies
if [[ -n ${LIB_DIR:-} ]]; then
  source "${LIB_DIR}/core.sh"
  source "${LIB_DIR}/detect_os.sh"
else
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source "${SCRIPT_DIR}/core.sh"
  source "${SCRIPT_DIR}/detect_os.sh"
fi

# -----------------------------------------------------------------------------
# Install Homebrew (macOS/Linux)
# -----------------------------------------------------------------------------
install_homebrew() {
  if cmd_exists brew; then
    log_info "Homebrew already installed"
    return 0
  fi

  log_step "Installing Homebrew..."

  if [[ $OS_TYPE == "macos" ]]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    # Linux
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add to PATH
    if [[ -f /etc/profile.d/brew.sh ]]; then
      source /etc/profile.d/brew.sh
    fi
  fi

  # Verify installation
  if cmd_exists brew; then
    log_success "Homebrew installed successfully"
  else
    log_error "Failed to install Homebrew"
    return 1
  fi
}

# -----------------------------------------------------------------------------
# Update package lists (apt)
# -----------------------------------------------------------------------------
apt_update() {
  log_step "Updating package lists..."
  export DEBIAN_FRONTEND=noninteractive
  $SUDO apt-get update -qq
  log_success "Package lists updated"
}

# -----------------------------------------------------------------------------
# Install packages using apt
# -----------------------------------------------------------------------------
apt_install() {
  local packages=("$@")
  local to_install=()

  # Check which packages are not installed
  for pkg in "${packages[@]}"; do
    if ! dpkg -l "$pkg" >/dev/null 2>&1; then
      to_install+=("$pkg")
    else
      log_debug "$pkg already installed, skipping"
    fi
  done

  if [[ ${#to_install[@]} -eq 0 ]]; then
    log_info "All packages already installed"
    return 0
  fi

  log_step "Installing packages: ${to_install[*]}"
  export DEBIAN_FRONTEND=noninteractive
  if ! $SUDO apt-get install -y -qq "${to_install[@]}"; then
    log_error "apt-get install failed, re-running without -qq to show full error:"
    $SUDO apt-get install -y "${to_install[@]}" || true
    for pkg in "${to_install[@]}"; do
      if ! dpkg -l "$pkg" >/dev/null 2>&1; then
        log_error "Failed to install: $pkg"
        return 1
      fi
    done
  fi

  # Verify installation
  for pkg in "${to_install[@]}"; do
    if dpkg -l "$pkg" >/dev/null 2>&1; then
      log_success "Installed: $pkg"
    else
      log_error "Failed to install: $pkg (apt output above)"
      return 1
    fi
  done
}

# -----------------------------------------------------------------------------
# Install packages using brew
# -----------------------------------------------------------------------------
brew_install() {
  local packages=("$@")
  local to_install=()

  # Check which packages are not installed
  for pkg in "${packages[@]}"; do
    if ! brew list "$pkg" >/dev/null 2>&1; then
      to_install+=("$pkg")
    else
      log_debug "$pkg already installed, skipping"
    fi
  done

  if [[ ${#to_install[@]} -eq 0 ]]; then
    log_info "All packages already installed"
    return 0
  fi

  log_step "Installing packages: ${to_install[*]}"
  brew install "${to_install[@]}"

  # Verify installation
  for pkg in "${to_install[@]}"; do
    if brew list "$pkg" >/dev/null 2>&1; then
      log_success "Installed: $pkg"
    else
      log_error "Failed to install: $pkg"
      return 1
    fi
  done
}

# -----------------------------------------------------------------------------
# Generic install function
# -----------------------------------------------------------------------------
install_packages() {
  local packages=("$@")

  case "$PACKAGE_MANAGER" in
  apt)
    apt_install "${packages[@]}"
    ;;
  brew)
    # Ensure brew is installed first
    if ! cmd_exists brew; then
      install_homebrew
    fi
    brew_install "${packages[@]}"
    ;;
  dnf)
    $SUDO dnf install -y "${packages[@]}"
    ;;
  pacman)
    $SUDO pacman -S --noconfirm "${packages[@]}"
    ;;
  *)
    log_error "Unsupported package manager: $PACKAGE_MANAGER"
    return 1
    ;;
  esac
}

# -----------------------------------------------------------------------------
# Install essential tools
# -----------------------------------------------------------------------------
install_essentials() {
  log_step "Installing essential tools..."

  local essentials
  case "$PACKAGE_MANAGER" in
  apt)
    essentials=(git curl wget unzip build-essential ca-certificates lsb-release)
    ;;
  brew)
    essentials=(git curl wget unzip)
    ;;
  dnf)
    essentials=(git curl wget unzip gcc gcc-c++ make)
    ;;
  pacman)
    essentials=(git curl wget unzip base-devel)
    ;;
  *)
    log_error "Unsupported package manager"
    return 1
    ;;
  esac

  install_packages "${essentials[@]}"
}

# -----------------------------------------------------------------------------
# Install development tools
# -----------------------------------------------------------------------------
install_dev_tools() {
  log_step "Installing development tools..."

  local dev_tools
  case "$PACKAGE_MANAGER" in
  apt)
    dev_tools=(neovim tmux htop bat exa fd-find ripgrep fzf)
    ;;
  brew)
    dev_tools=(neovim tmux htop bat exa fd ripgrep fzf)
    ;;
  dnf)
    dev_tools=(neovim tmux htop bat exa fd-find ripgrep fzf)
    ;;
  pacman)
    dev_tools=(neovim tmux htop bat exa fd ripgrep fzf)
    ;;
  esac

  install_packages "${dev_tools[@]}"
}

# -----------------------------------------------------------------------------
# Install starship prompt
# -----------------------------------------------------------------------------
install_starship() {
  if cmd_exists starship; then
    log_info "Starship already installed"
    return 0
  fi

  log_step "Installing Starship prompt..."

  # Install starship
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y

  if cmd_exists starship; then
    log_success "Starship installed successfully"
  else
    log_error "Failed to install Starship"
    return 1
  fi
}

# -----------------------------------------------------------------------------
# Install fzf (if not available)
# -----------------------------------------------------------------------------
install_fzf() {
  if cmd_exists fzf; then
    log_info "fzf already installed"
    return 0
  fi

  log_step "Installing fzf..."

  case "$PACKAGE_MANAGER" in
  apt)
    apt_install fzf
    ;;
  brew)
    brew_install fzf
    ;;
  *)
    # Manual installation
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all --no-bash --no-zsh
    ;;
  esac
}

# -----------------------------------------------------------------------------
# Install tmux (if not available)
# -----------------------------------------------------------------------------
install_tmux() {
  if cmd_exists tmux; then
    log_info "tmux already installed"
    return 0
  fi

  log_step "Installing tmux..."

  case "$PACKAGE_MANAGER" in
  apt)
    apt_install tmux
    ;;
  brew)
    brew_install tmux
    ;;
  esac
}
