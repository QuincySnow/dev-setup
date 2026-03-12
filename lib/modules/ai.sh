#!/usr/bin/env bash
# =============================================================================
# modules/ai.sh - AI tools installation module
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
# Check if Ollama is installed
# -----------------------------------------------------------------------------
check_ollama_installed() {
    if cmd_exists ollama; then
        local version
        version=$(ollama --version 2>/dev/null || echo "unknown")
        log_info "Ollama already installed: $version"
        return 0
    fi
    return 1
}

# -----------------------------------------------------------------------------
# Install Ollama on Linux
# -----------------------------------------------------------------------------
install_ollama_linux() {
    log_step "Installing Ollama on Linux..."
    
    # Install curl if not available
    require_cmd curl
    
    # Download and install Ollama
    curl -fsSL https://ollama.ai/install.sh | $SUDO sh
    
    if cmd_exists ollama; then
        log_success "Ollama installed successfully"
    else
        log_error "Failed to install Ollama"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Install Ollama on macOS
# -----------------------------------------------------------------------------
install_ollama_macos() {
    log_step "Installing Ollama on macOS..."
    
    # Ollama on macOS is installed via curl
    curl -fsSL https://ollama.ai/install.sh | sh
    
    if cmd_exists ollama; then
        log_success "Ollama installed successfully"
    else
        log_error "Failed to install Ollama"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Download default Ollama model
# -----------------------------------------------------------------------------
download_ollama_model() {
    local model="${1:-llama2}"
    
    if ! cmd_exists ollama; then
        log_warn "Ollama not installed, skipping model download"
        return 0
    fi
    
    if ask_confirmation "Download default Ollama model ($model)?" "y"; then
        log_step "Downloading Ollama model: $model..."
        ollama pull "$model"
        log_success "Model downloaded"
    fi
}

# -----------------------------------------------------------------------------
# Configure Ollama for remote access
# -----------------------------------------------------------------------------
configure_ollama() {
    if ! cmd_exists ollama; then
        return 0
    fi
    
    log_step "Configuring Ollama..."
    
    # Set environment variables for remote access
    local ollama_env="
# Ollama configuration
export OLLAMA_HOST=0.0.0.0:11434
export OLLAMA_MODELS=\"\$HOME/.ollama/models\"
"
    
    # Add to shell config
    if [[ -f "${HOME}/.zshrc" ]] && ! grep -q "OLLAMA_HOST" "${HOME}/.zshrc"; then
        echo "$ollama_env" >> "${HOME}/.zshrc"
    fi
    
    if [[ -f "${HOME}/.config/fish/config.fish" ]] && ! grep -q "OLLAMA_HOST" "${HOME}/.config/fish/config.fish"; then
        echo "$ollama_env" >> "${HOME}/.config/fish/config.fish"
    fi
    
    log_success "Ollama configured"
}

# -----------------------------------------------------------------------------
# Install Open WebUI (optional)
# -----------------------------------------------------------------------------
install_open_webui() {
    if ! cmd_exists docker; then
        log_warn "Docker not found. Skipping Open WebUI installation."
        return 0
    fi
    
    if ask_confirmation "Install Open WebUI (Docker)?" "n"; then
        log_step "Installing Open WebUI..."
        
        docker run -d --network=host \
            --name open-webui \
            --restart always \
            -v ollama-webui:/app/backend/data \
            --add-host=host.docker.internal:host-gateway \
            ghcr.io/open-webui/open-webui:main
        
        log_success "Open WebUI installed"
        log_info "Access Open WebUI at: http://localhost:8080"
    fi
}

# -----------------------------------------------------------------------------
# Main AI tools installation function
# -----------------------------------------------------------------------------
install_ai_tools() {
    if check_ollama_installed; then
        log_info "AI tools already installed"
        return 0
    fi
    
    log_step "Starting AI tools installation..."
    
    # Install Ollama based on OS
    case "$OS_TYPE" in
        macos)
            install_ollama_macos
            ;;
        linux)
            install_ollama_linux
            ;;
    esac
    
    # Download default model
    download_ollama_model "llama2"
    
    # Configure Ollama
    configure_ollama
    
    # Verify installation
    if cmd_exists ollama; then
        log_success "AI tools installation completed"
        log_info "Ollama version: $(ollama --version)"
        log_info "Run 'ollama serve' to start the server"
    else
        log_error "AI tools installation failed"
        return 1
    fi
}
