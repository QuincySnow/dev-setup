#!/usr/bin/env bash
# =============================================================================
# shell_setup.sh - Shell installation and configuration
# =============================================================================

# Source dependencies
if [[ -n "${LIB_DIR:-}" ]]; then
    source "${LIB_DIR}/core.sh"
    source "${LIB_DIR}/detect_os.sh"
    source "${LIB_DIR}/install_pkg.sh"
else
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${SCRIPT_DIR}/core.sh"
    source "${SCRIPT_DIR}/detect_os.sh"
    source "${SCRIPT_DIR}/install_pkg.sh"
fi

# Initialize language messages if not already done
if [[ -z "${LANGUAGE:-}" ]]; then
    LANGUAGE="en"
fi
if [[ -z "${MSG[welcome]:-}" ]]; then
    init_messages
fi

# Global variables
export TARGET_SHELL="${TARGET_SHELL:-}"
export SHELL_INSTALL_PATH=""

# -----------------------------------------------------------------------------
# Install Fish Shell
# -----------------------------------------------------------------------------
install_fish() {
    if cmd_exists fish; then
        log_info "Fish shell already installed: $(fish --version)"
        SHELL_INSTALL_PATH=$(which fish)
        return 0
    fi
    
    log_step "Installing Fish shell..."
    
    case "$PACKAGE_MANAGER" in
        apt)
            # Add Fish repository for newer version
            $SUDO apt-add-repository ppa:fish-shell/release-3 -y 2>/dev/null || true
            apt_update
            apt_install fish
            ;;
        brew)
            brew_install fish
            ;;
        dnf)
            $SUDO dnf install -y fish
            ;;
        pacman)
            $SUDO pacman -S --noconfirm fish
            ;;
    esac
    
    if cmd_exists fish; then
        SHELL_INSTALL_PATH=$(which fish)
        log_success "Fish installed: $(fish --version)"
    else
        log_error "Failed to install Fish"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Install Zsh
# -----------------------------------------------------------------------------
install_zsh() {
    if cmd_exists zsh; then
        log_info "Zsh already installed: $(zsh --version)"
        SHELL_INSTALL_PATH=$(which zsh)
        return 0
    fi
    
    log_step "Installing Zsh..."
    
    case "$PACKAGE_MANAGER" in
        apt)
            apt_install zsh
            ;;
        brew)
            brew_install zsh
            ;;
        dnf)
            $SUDO dnf install -y zsh
            ;;
        pacman)
            $SUDO pacman -S --noconfirm zsh
            ;;
    esac
    
    if cmd_exists zsh; then
        SHELL_INSTALL_PATH=$(which zsh)
        log_success "Zsh installed: $(zsh --version)"
    else
        log_error "Failed to install Zsh"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Install Oh My Zsh
# -----------------------------------------------------------------------------
install_oh_my_zsh() {
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log_info "Oh My Zsh already installed"
        return 0
    fi
    
    log_step "Installing Oh My Zsh..."
    
    # Install Oh My Zsh (non-interactive)
    export RUNZSH=no
    export CHSH=no
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log_success "Oh My Zsh installed"
    else
        log_error "Failed to install Oh My Zsh"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Install Fisher (Fish plugin manager)
# -----------------------------------------------------------------------------
install_fisher() {
    if cmd_exists fisher; then
        log_info "Fisher already installed"
        return 0
    fi
    
    log_step "Installing Fisher..."
    
    # Install fisher
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | fish
    
    if cmd_exists fisher; then
        log_success "Fisher installed"
    else
        log_error "Failed to install Fisher"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Install Zsh plugins
# -----------------------------------------------------------------------------
install_zsh_plugins() {
    local zsh_custom="${HOME}/.oh-my-zsh/custom"
    
    log_step "Installing Zsh plugins..."
    
    # zsh-autosuggestions
    if [[ ! -d "${zsh_custom}/plugins/zsh-autosuggestions" ]]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions \
            "${zsh_custom}/plugins/zsh-autosuggestions"
    fi
    
    # zsh-syntax-highlighting
    if [[ ! -d "${zsh_custom}/plugins/zsh-syntax-highlighting" ]]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
            "${zsh_custom}/plugins/zsh-syntax-highlighting"
    fi
    
    # zsh-history-substring-search
    if [[ ! -d "${zsh_custom}/plugins/zsh-history-substring-search" ]]; then
        git clone https://github.com/zsh-users/zsh-history-substring-search \
            "${zsh_custom}/plugins/zsh-history-substring-search"
    fi
    
    log_success "Zsh plugins installed"
}

# -----------------------------------------------------------------------------
# Install Fish plugins
# -----------------------------------------------------------------------------
install_fish_plugins() {
    log_step "Installing Fish plugins via Fisher..."
    
    # Wait for fisher to be available in fish shell
    fish -c "fisher install jethrokuan/z"
    fish -c "fisher install PatrickF1/fzf.fish"
    fish -c "fisher install jorgebucaran/fisher"
    fish -c "fisher install edc/bass"
    fish -c "fisher install skywind3000/z.lua"
    
    log_success "Fish plugins installed"
}

# -----------------------------------------------------------------------------
# Set default shell
# -----------------------------------------------------------------------------
set_default_shell() {
    local shell_path="$1"
    local shell_name="$2"
    
    if [[ "$(get_current_shell)" == "$shell_name" ]]; then
        log_info "Already using $shell_name as current shell"
        return 0
    fi
    
    # Add to /etc/shells if needed
    if ! grep -q "^${shell_path}$" /etc/shells 2>/dev/null; then
        log_step "Adding $shell_path to /etc/shells"
        echo "$shell_path" | $SUDO tee -a /etc/shells >/dev/null
    fi
    
    # Change default shell
    if ask_confirmation "Set $shell_name as default shell?" "y"; then
        $SUDO chsh -s "$shell_path"
        log_success "Default shell set to $shell_name"
    else
        log_info "Skipped setting default shell"
    fi
}

# -----------------------------------------------------------------------------
# Prompt shell selection
# -----------------------------------------------------------------------------
prompt_shell_selection() {
    cat << EOF

${MSG[select_shell]}

  [1] ${MSG[shell_fish]}
  [2] ${MSG[shell_zsh]}

EOF

    local choice
    echo -ne "${COLOR_CYAN}${MSG[enter_choice]}${COLOR_RESET} "
    read -r choice
    
    case "$choice" in
        1)
            TARGET_SHELL="fish"
            ;;
        2)
            TARGET_SHELL="zsh"
            ;;
        *)
            log_error "Invalid choice"
            return 1
            ;;
    esac
    
    log_info "${MSG[selected_shell]}$TARGET_SHELL"
}

# -----------------------------------------------------------------------------
# Prompt container runtime selection
# -----------------------------------------------------------------------------
prompt_container_selection() {
    cat << EOF

${MSG[select_container]}

  [1] ${MSG[container_docker]}
  [2] ${MSG[container_podman]}

EOF

    local choice
    echo -ne "${COLOR_CYAN}${MSG[enter_container]}${COLOR_RESET} "
    read -r choice
    
    case "$choice" in
        1)
            INSTALL_DOCKER=true
            INSTALL_PODMAN=false
            ;;
        2)
            INSTALL_DOCKER=false
            INSTALL_PODMAN=true
            ;;
        *)
            log_error "Invalid choice, defaulting to Docker"
            INSTALL_DOCKER=true
            INSTALL_PODMAN=false
            ;;
    esac
}

# -----------------------------------------------------------------------------
# Main shell setup function
# -----------------------------------------------------------------------------
setup_shell() {
    local shell_type="${1:-}"
    
    # Determine shell type
    if [[ -z "${shell_type:-}" ]]; then
        if [[ -n "${TARGET_SHELL:-}" ]]; then
            log_info "Using shell from argument: $TARGET_SHELL"
        else
            prompt_shell_selection
        fi
    else
        TARGET_SHELL="$shell_type"
    fi
    
    # Install selected shell
    case "$TARGET_SHELL" in
        fish)
            install_fish
            install_starship
            install_fzf
            install_tmux
            install_fisher
            install_fish_plugins
            set_default_shell "$SHELL_INSTALL_PATH" "fish"
            ;;
        zsh)
            install_zsh
            install_oh_my_zsh
            install_starship
            install_fzf
            install_tmux
            install_zsh_plugins
            set_default_shell "$SHELL_INSTALL_PATH" "zsh"
            ;;
        *)
            log_error "Invalid shell type: $TARGET_SHELL"
            return 1
            ;;
    esac
    
    log_success "Shell setup completed: $TARGET_SHELL"
}
