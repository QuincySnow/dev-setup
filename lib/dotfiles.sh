#!/usr/bin/env bash
# =============================================================================
# dotfiles.sh - Dotfiles management
# =============================================================================

# Source dependencies
if [[ -n "${LIB_DIR:-}" ]]; then
    source "${LIB_DIR}/core.sh"
    source "${LIB_DIR}/detect_os.sh"
else
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${SCRIPT_DIR}/core.sh"
    source "${SCRIPT_DIR}/detect_os.sh"
fi

# Global variables
export DOTFILES_DIR=""

# -----------------------------------------------------------------------------
# Initialize dotfiles directory
# -----------------------------------------------------------------------------
init_dotfiles() {
    DOTFILES_DIR="${SCRIPT_DIR}/../dotfiles"
    
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        log_error "Dotfiles directory not found: $DOTFILES_DIR"
        return 1
    fi
    
    log_debug "Dotfiles directory: $DOTFILES_DIR"
}

# -----------------------------------------------------------------------------
# Link Fish configuration
# -----------------------------------------------------------------------------
link_fish_config() {
    local config_dir="${HOME}/.config/fish"
    local source_dir="${DOTFILES_DIR}/fish"
    
    if [[ ! -d "$source_dir" ]]; then
        log_warn "Fish config source not found: $source_dir"
        return 0
    fi
    
    log_step "Setting up Fish configuration..."
    
    # Backup existing config
    if [[ -d "$config_dir" ]]; then
        backup_dir "$config_dir"
    fi
    
    # Create config directory
    ensure_dir "$config_dir"
    
    # Link fish config
    safe_symlink "${source_dir}/config.fish" "${config_dir}/config.fish"
    
    # Link functions
    if [[ -d "${source_dir}/functions" ]]; then
        ensure_dir "${config_dir}/functions"
        for func in "${source_dir}/functions"/*; do
            if [[ -f "$func" ]]; then
                local func_name
                func_name=$(basename "$func")
                safe_symlink "$func" "${config_dir}/functions/${func_name}"
            fi
        done
    fi
    
    log_success "Fish configuration linked"
}

# -----------------------------------------------------------------------------
# Link Zsh configuration
# -----------------------------------------------------------------------------
link_zsh_config() {
    local source_dir="${DOTFILES_DIR}/zsh"
    
    if [[ ! -d "$source_dir" ]]; then
        log_warn "Zsh config source not found: $source_dir"
        return 0
    fi
    
    log_step "Setting up Zsh configuration..."
    
    # Backup existing .zshrc
    backup_file "${HOME}/.zshrc"
    
    # Link .zshrc
    safe_symlink "${source_dir}/.zshrc" "${HOME}/.zshrc"
    
    # Link .p10k.zsh if exists
    if [[ -f "${source_dir}/.p10k.zsh" ]]; then
        safe_symlink "${source_dir}/.p10k.zsh" "${HOME}/.p10k.zsh"
    fi
    
    log_success "Zsh configuration linked"
}

# -----------------------------------------------------------------------------
# Link Starship configuration
# -----------------------------------------------------------------------------
link_starship_config() {
    local source_file="${DOTFILES_DIR}/starship/starship.toml"
    local target_dir="${HOME}/.config/starship"
    
    if [[ ! -f "$source_file" ]]; then
        log_warn "Starship config not found: $source_file"
        return 0
    fi
    
    log_step "Setting up Starship configuration..."
    
    ensure_dir "$target_dir"
    safe_symlink "$source_file" "${target_dir}/config.toml"
    
    log_success "Starship configuration linked"
}

# -----------------------------------------------------------------------------
# Link fzf configuration
# -----------------------------------------------------------------------------
link_fzf_config() {
    local source_dir="${DOTFILES_DIR}/fzf"
    
    if [[ ! -d "$source_dir" ]]; then
        log_debug "fzf config not found, skipping"
        return 0
    fi
    
    log_step "Setting up fzf configuration..."
    
    # Link keybindings
    local shell_type="${1:-fish}"
    local keybindings_file=""
    
    case "$shell_type" in
        fish)
            keybindings_file="keybindings.fish"
            ;;
        zsh)
            keybindings_file="keybindings.zsh"
            ;;
    esac
    
    if [[ -n "$keybindings_file" ]] && [[ -f "${source_dir}/${keybindings_file}" ]]; then
        ensure_dir "${HOME}/.config/fzf"
        safe_symlink "${source_dir}/${keybindings_file}" "${HOME}/.config/fzf/${keybindings_file}"
    fi
    
    log_success "fzf configuration linked"
}

# -----------------------------------------------------------------------------
# Link tmux configuration
# -----------------------------------------------------------------------------
link_tmux_config() {
    local source_file="${DOTFILES_DIR}/tmux/tmux.conf"
    local target_file="${HOME}/.tmux.conf"
    
    if [[ ! -f "$source_file" ]]; then
        log_warn "tmux config not found: $source_file"
        return 0
    fi
    
    log_step "Setting up tmux configuration..."
    
    backup_file "$target_file"
    safe_symlink "$source_file" "$target_file"
    
    log_success "tmux configuration linked"
}

# -----------------------------------------------------------------------------
# Link Git configuration
# -----------------------------------------------------------------------------
link_git_config() {
    local source_file="${DOTFILES_DIR}/gitconfig"
    local target_file="${HOME}/.gitconfig"
    
    if [[ ! -f "$source_file" ]]; then
        log_warn "gitconfig not found: $source_file"
        return 0
    fi
    
    log_step "Setting up Git configuration..."
    
    backup_file "$target_file"
    safe_symlink "$source_file" "$target_file"
    
    log_success "Git configuration linked"
}

# -----------------------------------------------------------------------------
# Link Vim configuration
# -----------------------------------------------------------------------------
link_vim_config() {
    local source_file="${DOTFILES_DIR}/vimrc"
    local target_file="${HOME}/.vimrc"
    
    if [[ ! -f "$source_file" ]]; then
        log_warn "vimrc not found: $source_file"
        return 0
    fi
    
    log_step "Setting up Vim configuration..."
    
    backup_file "$target_file"
    safe_symlink "$source_file" "$target_file"
    
    log_success "Vim configuration linked"
}

# -----------------------------------------------------------------------------
# Main dotfiles setup function
# -----------------------------------------------------------------------------
setup_dotfiles() {
    local shell_type="${1:-fish}"
    
    init_dotfiles
    
    log_step "Setting up dotfiles..."
    
    # Link all configurations
    case "$shell_type" in
        fish)
            link_fish_config
            ;;
        zsh)
            link_zsh_config
            ;;
    esac
    
    link_starship_config
    link_fzf_config "$shell_type"
    link_tmux_config
    link_git_config
    link_vim_config
    
    log_success "Dotfiles setup completed"
}
