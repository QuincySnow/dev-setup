#!/usr/bin/env bash
# =============================================================================
# dev-setup - Development Environment Setup
# =============================================================================
# A one-click script to set up your development environment on macOS/Linux
# 
# Usage:
#   ./install.sh [OPTIONS]
#
# Options:
#   --shell {fish|zsh}     Select shell (default: interactive)
#   --with-docker          Install Docker
#   --with-ai            Install AI tools (Ollama)
#   --with-python         Install Python tools (uv, pipx)
#   --yes, -y             Skip confirmation
#   --help                Show this help message
#
# Blog: https://skippingpetticoatconvent.github.io/
# Repo: https://github.com/SKIPPINGpetticoatconvent/dev-setup
# =============================================================================

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"

# Source core functions
source "${LIB_DIR}/core.sh"

# =============================================================================
# Global variables
# =============================================================================
export TARGET_SHELL=""
export INSTALL_DOCKER=false
export INSTALL_PODMAN=false
export INSTALL_AI=false
export INSTALL_PYTHON=false
export YES_MODE=false
export SKIP_MODULES=false
export LANGUAGE="en"
export CONTAINER_RUNTIME="docker"

# =============================================================================
# Usage
# =============================================================================
usage() {
    # Check if language is set to Chinese
    local is_zh=false
    if [[ "${LANGUAGE:-}" == "zh" ]] || [[ "${1:-}" == "zh" ]]; then
        is_zh=true
    fi
    
    if [[ "$is_zh" == "true" ]]; then
        cat << 'EOF'
dev-setup - 开发环境一键配置脚本

在 macOS/Linux 上快速搭建开发环境

用法:
    ./install.sh [选项]

选项:
    --shell {fish|zsh}     选择 Shell (默认: 交互式选择)
    --lang {en|zh}        语言: English 或 Chinese (默认: en)
    --container {docker|podman|both}
                          容器运行时 (默认: docker)
    --with-docker          安装 Docker (已废弃，请使用 --container)
    --with-podman          安装 Podman
    --with-ai            安装 AI 工具 (Ollama)
    --with-python         安装 Python 工具 (uv, pipx)
    --yes, -y             跳过所有确认
    --skip-modules        跳过可选模块
    --help                显示帮助

示例:
    # 交互式安装 (英文)
    ./install.sh

    # 中文安装
    ./install.sh --lang zh

    # 安装 Fish + Docker + AI
    ./install.sh --shell fish --container docker --with-ai

    # 安装 Zsh + Podman
    ./install.sh --shell zsh --container podman

    # 非交互式安装
    ./install.sh --shell zsh --with-python --yes

    # 管道安装 (curl)
    curl -sSL https://raw.githubusercontent.com/SKIPPINGpetticoatconvent/dev-setup/main/install.sh | bash

更多信息:
    https://github.com/SKIPPINGpetticoatconvent/dev-setup
EOF
    else
        cat << 'EOF'
dev-setup - Development Environment Setup

A one-click script to set up your development environment on macOS/Linux

Usage:
    ./install.sh [OPTIONS]

Options:
    --shell {fish|zsh}     Select shell (default: interactive selection)
    --lang {en|zh}        Language: English or Chinese (default: en)
    --container {docker|podman|both}
                          Container runtime to install (default: docker)
    --with-docker          Install Docker (deprecated, use --container)
    --with-podman          Install Podman
    --with-ai            Install AI tools (Ollama)
    --with-python         Install Python tools (uv, pipx)
    --yes, -y             Skip all confirmations
    --skip-modules        Skip optional modules (docker, ai, python)
    --help                Show this help message

Examples:
    # Interactive installation (English)
    ./install.sh

    # Chinese installation
    ./install.sh --lang zh

    # Install Fish + Docker + AI
    ./install.sh --shell fish --container docker --with-ai

    # Install Zsh + Podman
    ./install.sh --shell zsh --container podman

    # Non-interactive installation
    ./install.sh --shell zsh --with-python --yes

    # Pipe installation (for curl)
    curl -sSL https://raw.githubusercontent.com/SKIPPINGpetticoatconvent/dev-setup/main/install.sh | bash

For more information, visit:
    https://github.com/SKIPPINGpetticoatconvent/dev-setup
EOF
    fi
    exit 0
}

# =============================================================================
# Parse arguments
# =============================================================================
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --shell)
                TARGET_SHELL="$2"
                shift 2
                ;;
            --lang)
                LANGUAGE="$2"
                init_messages
                shift 2
                ;;
            --container)
                case "$2" in
                    docker)
                        INSTALL_DOCKER=true
                        INSTALL_PODMAN=false
                        ;;
                    podman)
                        INSTALL_DOCKER=false
                        INSTALL_PODMAN=true
                        ;;
                    both)
                        INSTALL_DOCKER=true
                        INSTALL_PODMAN=true
                        ;;
                    *)
                        log_error "Invalid container option: $2"
                        echo "Use docker, podman, or both"
                        exit 1
                        ;;
                esac
                shift 2
                ;;
            --with-docker)
                INSTALL_DOCKER=true
                CONTAINER_RUNTIME="docker"
                shift
                ;;
            --with-podman)
                INSTALL_PODMAN=true
                CONTAINER_RUNTIME="podman"
                shift
                ;;
            --with-ai)
                INSTALL_AI=true
                shift
                ;;
            --with-python)
                INSTALL_PYTHON=true
                shift
                ;;
            --yes|-y)
                YES_MODE=true
                shift
                ;;
            --skip-modules)
                SKIP_MODULES=true
                shift
                ;;
            --help|-h)
                usage
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# =============================================================================
# Print summary
# =============================================================================
print_summary() {
    cat << 'EOF'

╔═══════════════════════════════════════════════════════════════╗
║                   Installation Summary                        ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    
    echo ""
    echo -e "  ${COLOR_CYAN}OS:${COLOR_RESET}          ${OS_DISTRO} ${OS_VERSION} (${PACKAGE_MANAGER})"
    echo -e "  ${COLOR_CYAN}Language:${COLOR_RESET}    ${LANGUAGE}"
    echo -e "  ${COLOR_CYAN}Shell:${COLOR_RESET}       ${TARGET_SHELL:-interactive}"
    echo ""
    echo -e "  ${COLOR_CYAN}Modules:${COLOR_RESET}"
    
    if [[ "$SKIP_MODULES" == "true" ]]; then
        echo -e "    - (skipped)"
    else
        echo -e "    - Docker:    $([ "$INSTALL_DOCKER" == "true" ] && echo "${COLOR_GREEN}✓${COLOR_RESET}" || echo "${COLOR_GRAY}✗${COLOR_RESET}")"
        echo -e "    - Podman:    $([ "$INSTALL_PODMAN" == "true" ] && echo "${COLOR_GREEN}✓${COLOR_RESET}" || echo "${COLOR_GRAY}✗${COLOR_RESET}")"
        echo -e "    - AI Tools:  $([ "$INSTALL_AI" == "true" ] && echo "${COLOR_GREEN}✓${COLOR_RESET}" || echo "${COLOR_GRAY}✗${COLOR_RESET}")"
        echo -e "    - Python:    $([ "$INSTALL_PYTHON" == "true" ] && echo "${COLOR_GREEN}✓${COLOR_RESET}" || echo "${COLOR_GRAY}✗${COLOR_RESET}")"
    fi
    
    echo ""
    echo -e "  ${COLOR_CYAN}Dotfiles:${COLOR_RESET}     ${SCRIPT_DIR}/dotfiles/"
    echo ""
}

# =============================================================================
# Post-install checks
# =============================================================================
post_install_checks() {
    log_step "Running post-install checks..."
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Installed Tools"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Check core tools
    local tools=("git" "curl" "wget" "unzip")
    for tool in "${tools[@]}"; do
        if cmd_exists "$tool"; then
            local version
            version=$("$tool" --version 2>/dev/null | head -1 || echo "installed")
            log_success "$tool: $version"
        else
            log_warn "$tool: not found"
        fi
    done
    
    # Check shell
    if cmd_exists "$TARGET_SHELL"; then
        local shell_version
        shell_version=$("$TARGET_SHELL" --version 2>/dev/null | head -1 || echo "installed")
        log_success "$TARGET_SHELL: $shell_version"
    fi
    
    # Check starship
    if cmd_exists starship; then
        log_success "starship: $(starship --version)"
    fi
    
    # Check fzf
    if cmd_exists fzf; then
        log_success "fzf: installed"
    fi
    
    # Check tmux
    if cmd_exists tmux; then
        log_success "tmux: installed"
    fi
    
    # Check Docker
    if [[ "$INSTALL_DOCKER" == "true" ]] && cmd_exists docker; then
        log_success "docker: $(docker --version)"
    fi
    
    # Check Ollama
    if [[ "$INSTALL_AI" == "true" ]] && cmd_exists ollama; then
        log_success "ollama: $(ollama --version)"
    fi
    
    # Check Python tools
    if [[ "$INSTALL_PYTHON" == "true" ]]; then
        if cmd_exists uv; then
            log_success "uv: $(uv --version)"
        fi
        if cmd_exists pipx; then
            log_success "pipx: $(pipx --version)"
        fi
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# =============================================================================
# Print welcome message
# =============================================================================
print_welcome() {
    cat << EOF

╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   ${MSG[welcome]}                                   ║
║                                                               ║
║   ${MSG[welcome_sub]}                         ║
║                                                               ║
║   ${MSG[blog]}    ║
║   ${MSG[repo]}   ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝

EOF
}

# =============================================================================
# Main function
# =============================================================================
main() {
    # Parse arguments
    parse_args "$@"
    
    # Initialize language messages
    init_messages
    
    # Export language for subshells
    export LANGUAGE
    
    # Print banner
    print_banner
    print_welcome
    
    # Detect OS
    source "${LIB_DIR}/detect_os.sh"
    get_sudo
    detect_os
    export_os_info
    
    # Setup shell
    source "${LIB_DIR}/shell_setup.sh"
    setup_shell "${TARGET_SHELL:-}"
    
    # Install Python tools
    if [[ "$SKIP_MODULES" == "false" ]] && [[ "$INSTALL_PYTHON" == "true" ]]; then
        source "${LIB_DIR}/modules/python.sh"
        install_python_tools
    fi
    
    # Prompt for container runtime if neither Docker nor Podman is selected
    if [[ "$SKIP_MODULES" == "false" ]] && [[ "$INSTALL_DOCKER" == "false" ]] && [[ "$INSTALL_PODMAN" == "false" ]]; then
        if ask_confirmation "Install container runtime (Docker/Podman)?" "n"; then
            source "${LIB_DIR}/shell_setup.sh"
            prompt_container_selection
        fi
    fi
    
    # Install Docker
    if [[ "$SKIP_MODULES" == "false" ]] && [[ "$INSTALL_DOCKER" == "true" ]]; then
        source "${LIB_DIR}/modules/docker.sh"
        install_docker
    fi
    
    # Install Podman
    if [[ "$SKIP_MODULES" == "false" ]] && [[ "$INSTALL_PODMAN" == "true" ]]; then
        source "${LIB_DIR}/modules/docker.sh"
        install_podman
    fi
    
    # Install AI tools
    if [[ "$SKIP_MODULES" == "false" ]] && [[ "$INSTALL_AI" == "true" ]]; then
        source "${LIB_DIR}/modules/ai.sh"
        install_ai_tools
    fi
    
    # Setup dotfiles
    source "${LIB_DIR}/dotfiles.sh"
    setup_dotfiles "$TARGET_SHELL"
    
    # Print summary
    print_summary
    
    # Post-install checks
    post_install_checks
    
    # Final message
    cat << EOF

╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   ${MSG[completed]}                                  ║
║                                                               ║
║   ${MSG[next_steps]}                                          ║
║   ${MSG[restart_terminal]}                            ║
║   ${MSG[run_shell]}                                    ║
║                                                               ║
║   ${MSG[configure_git]}                              ║
║                                                               ║
║   ${MSG[blog]}   ║
║   ${MSG[repo]}  ║
║                                                               ║
║   🎉 Installation completed!                                  ║
║                                                               ║
║   Next steps:                                                 ║
║   1. Restart your terminal or open a new shell               ║
║   2. Run the shell (fish/zsh) to initialize                   ║
║   3. Enjoy your new development environment!                 ║
║                                                               ║
║   Don't forget to configure your dotfiles:                    ║
║   - Edit ~/.gitconfig with your name and email               ║
║   - Customize your shell plugins if needed                   ║
║                                                               ║
║   Blog: https://skippingpetticoatconvent.github.io/          ║
║   Repo: https://github.com/SKIPPINGpetticoatconvent/dev-setup║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝

EOF
}

# Run main function
main "$@"
