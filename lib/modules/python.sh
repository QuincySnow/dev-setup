#!/usr/bin/env bash
# =============================================================================
# modules/python.sh - Python tools installation module
# =============================================================================

# Source dependencies
if [[ -n "${LIB_DIR:-}" ]]; then
    source "${LIB_DIR}/core.sh"
    source "${LIB_DIR}/detect_os.sh"
else
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    source "${SCRIPT_DIR}/lib/core.sh"
    source "${SCRIPT_DIR}/lib/detect_os.sh"
fi

# -----------------------------------------------------------------------------
# Check if uv is installed
# -----------------------------------------------------------------------------
check_uv_installed() {
    if cmd_exists uv; then
        local version
        version=$(uv --version 2>/dev/null || echo "unknown")
        log_info "uv already installed: $version"
        return 0
    fi
    return 1
}

# -----------------------------------------------------------------------------
# Check if pipx is installed
# -----------------------------------------------------------------------------
check_pipx_installed() {
    if cmd_exists pipx; then
        local version
        version=$(pipx --version 2>/dev/null || echo "unknown")
        log_info "pipx already installed: $version"
        return 0
    fi
    return 1
}

# -----------------------------------------------------------------------------
# Check if rye is installed
# -----------------------------------------------------------------------------
check_rye_installed() {
    if cmd_exists rye; then
        local version
        version=$(rye --version 2>/dev/null || echo "unknown")
        log_info "rye already installed: $version"
        return 0
    fi
    return 1
}

# -----------------------------------------------------------------------------
# Install uv
# -----------------------------------------------------------------------------
install_uv() {
    if check_uv_installed; then
        return 0
    fi
    
    log_step "Installing uv..."
    
    # Install via official script
    curl -LsSf https://astral.sh/uv/install.sh | sh
    
    # Add to PATH
    local uv_bin="${HOME}/.local/bin"
    if [[ ":$PATH:" != *":${uv_bin}:"* ]]; then
        export PATH="${uv_bin}:$PATH"
        
        # Add to shell config
        case "${TARGET_SHELL:-bash}" in
            fish)
                if [[ -f "${HOME}/.config/fish/config.fish" ]]; then
                    if ! grep -q ".local/bin" "${HOME}/.config/fish/config.fish"; then
                        echo "fish_add_path ${uv_bin}" >> "${HOME}/.config/fish/config.fish"
                    fi
                fi
                ;;
            zsh|bash)
                if [[ -f "${HOME}/.zshrc" ]]; then
                    if ! grep -q ".local/bin" "${HOME}/.zshrc"; then
                        echo "export PATH=\"${uv_bin}:\$PATH\"" >> "${HOME}/.zshrc"
                    fi
                elif [[ -f "${HOME}/.bashrc" ]]; then
                    if ! grep -q ".local/bin" "${HOME}/.bashrc"; then
                        echo "export PATH=\"${uv_bin}:\$PATH\"" >> "${HOME}/.bashrc"
                    fi
                fi
                ;;
        esac
    fi
    
    if cmd_exists uv; then
        log_success "uv installed successfully"
    else
        log_error "Failed to install uv"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Install pipx
# -----------------------------------------------------------------------------
install_pipx() {
    if check_pipx_installed; then
        return 0
    fi
    
    log_step "Installing pipx..."
    
    # Install pipx via pip
    python3 -m pip install --user pipx
    
    # Ensure pipx is in PATH
    local pipx_bin="${HOME}/.local/bin"
    if [[ ":$PATH:" != *":${pipx_bin}:"* ]]; then
        export PATH="${pipx_bin}:$PATH"
    fi
    
    # Run pipx ensurepath
    pipx ensurepath >/dev/null 2>&1 || true
    
    if cmd_exists pipx; then
        log_success "pipx installed successfully"
    else
        log_error "Failed to install pipx"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Install rye
# -----------------------------------------------------------------------------
install_rye() {
    if check_rye_installed; then
        return 0
    fi
    
    log_step "Installing rye..."
    
    # Install via official script
    curl -LsSf https://rye.astral.sh/install.sh | sh
    
    # Add to PATH
    local rye_shims="${HOME}/.rye/shims"
    if [[ -d "$rye_shims" ]] && [[ ":$PATH:" != *":${rye_shims}:"* ]]; then
        export PATH="${rye_shims}:$PATH"
        
        # Add to shell config
        case "${TARGET_SHELL:-bash}" in
            fish)
                if [[ -f "${HOME}/.config/fish/config.fish" ]]; then
                    if ! grep -q ".rye/shims" "${HOME}/.config/fish/config.fish"; then
                        echo "fish_add_path ${rye_shims}" >> "${HOME}/.config/fish/config.fish"
                    fi
                fi
                ;;
            zsh|bash)
                if [[ -f "${HOME}/.zshrc" ]]; then
                    if ! grep -q ".rye/shims" "${HOME}/.zshrc"; then
                        echo "export PATH=\"${rye_shims}:\$PATH\"" >> "${HOME}/.zshrc"
                    fi
                fi
                ;;
        esac
    fi
    
    # Initialize rye
    if cmd_exists rye; then
        rye self update >/dev/null 2>&1 || true
        log_success "rye installed successfully"
    else
        log_error "Failed to install rye"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Install Python development tools
# -----------------------------------------------------------------------------
install_python_tools() {
    log_step "Installing Python tools..."
    
    # Install uv (primary)
    install_uv
    
    # Install pipx (for CLI tools)
    install_pipx
    
    # Install rye (optional)
    if ask_confirmation "Install rye (Python version manager)?" "n"; then
        install_rye
    fi
    
    log_success "Python tools installation completed"
    
    # Print summary
    echo ""
    log_info "Installed Python tools:"
    if cmd_exists uv; then
        log_info "  - uv: $(uv --version)"
    fi
    if cmd_exists pipx; then
        log_info "  - pipx: $(pipx --version)"
    fi
    if cmd_exists rye; then
        log_info "  - rye: $(rye --version)"
    fi
}
