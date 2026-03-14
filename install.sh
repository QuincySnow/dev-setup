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
export INSTALL_SHELL_TOOLS=false
export INSTALL_UV=false
export INSTALL_BUN=false
export INSTALL_FNM=false
export INSTALL_GO=false
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
  if [[ ${LANGUAGE:-} == "zh" ]] || [[ ${1:-} == "zh" ]]; then
    is_zh=true
  fi

  if [[ $is_zh == "true" ]]; then
    cat <<'EOF'
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
    --with-shell-tools    安装 Shell 工具 (shfmt, shellcheck)
    --with-uv            安装 UV (Python 包管理器)
    --with-bun           安装 Bun (JavaScript 运行时)
    --with-fnm           安装 FNM (Node.js 版本管理)
    --with-go            安装 Go (Golang)
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
    cat <<'EOF'
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
    --with-shell-tools    Install Shell tools (shfmt, shellcheck)
    --with-uv            Install UV (Python package manager)
    --with-bun           Install Bun (JavaScript runtime)
    --with-fnm           Install FNM (Node.js version manager)
    --with-go            Install Go (Golang)
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
    --with-shell-tools)
      INSTALL_SHELL_TOOLS=true
      shift
      ;;
    --with-uv)
      INSTALL_UV=true
      shift
      ;;
    --with-bun)
      INSTALL_BUN=true
      shift
      ;;
    --with-fnm)
      INSTALL_FNM=true
      shift
      ;;
    --with-go)
      INSTALL_GO=true
      shift
      ;;
    --yes | -y)
      YES_MODE=true
      shift
      ;;
    --skip-modules)
      SKIP_MODULES=true
      shift
      ;;
    --help | -h)
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
# Interactive module selection (when no --with-* provided)
# =============================================================================
any_modules_selected() {
  [[ "$INSTALL_DOCKER" == "true" ]] && return 0
  [[ "$INSTALL_PODMAN" == "true" ]] && return 0
  [[ "$INSTALL_AI" == "true" ]] && return 0
  [[ "$INSTALL_PYTHON" == "true" ]] && return 0
  [[ "$INSTALL_SHELL_TOOLS" == "true" ]] && return 0
  [[ "$INSTALL_UV" == "true" ]] && return 0
  [[ "$INSTALL_BUN" == "true" ]] && return 0
  [[ "$INSTALL_FNM" == "true" ]] && return 0
  [[ "$INSTALL_GO" == "true" ]] && return 0
  return 1
}

prompt_module_selection() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Select modules to install (space-separated numbers)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  [1] Container runtime: Docker"
  echo "  [2] Container runtime: Podman"
  echo "  [3] AI tools (Ollama)"
  echo "  [4] Python tools (uv, pipx)"
  echo "  [5] Shell tools (shfmt, shellcheck)"
  echo "  [6] UV (Python package manager)"
  echo "  [7] Bun (JavaScript runtime)"
  echo "  [8] FNM (Node.js version manager)"
  echo "  [9] Go (Golang)"
  echo ""
  echo "  Examples:"
  echo "    - Install uv + bun + fnm: 6 7 8"
  echo "    - Install Docker + AI: 1 3"
  echo "    - Skip all: (press Enter)"
  echo ""
  echo -ne "${COLOR_CYAN}Enter your choice:${COLOR_RESET} "

  local input
  read -r input || true
  input="$(echo "$input" | tr ',;' ' ' | xargs || true)"
  [[ -z "$input" ]] && return 0

  local c
  for c in $input; do
    case "$c" in
      1)
        INSTALL_DOCKER=true
        INSTALL_PODMAN=false
        CONTAINER_RUNTIME="docker"
        ;;
      2)
        INSTALL_PODMAN=true
        INSTALL_DOCKER=false
        CONTAINER_RUNTIME="podman"
        ;;
      3) INSTALL_AI=true ;;
      4) INSTALL_PYTHON=true ;;
      5) INSTALL_SHELL_TOOLS=true ;;
      6) INSTALL_UV=true ;;
      7) INSTALL_BUN=true ;;
      8) INSTALL_FNM=true ;;
      9) INSTALL_GO=true ;;
      *) ;;
    esac
  done
}

# =============================================================================
# Print summary
# =============================================================================
print_summary() {
  cat <<'EOF'

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

  if [[ $SKIP_MODULES == "true" ]]; then
    echo -e "    - (skipped)"
  else
    echo -e "    - Docker:    $([ "$INSTALL_DOCKER" == "true" ] && echo "${COLOR_GREEN}✓${COLOR_RESET}" || echo "${COLOR_GRAY}✗${COLOR_RESET}")"
    echo -e "    - Podman:    $([ "$INSTALL_PODMAN" == "true" ] && echo "${COLOR_GREEN}✓${COLOR_RESET}" || echo "${COLOR_GRAY}✗${COLOR_RESET}")"
    echo -e "    - AI Tools:  $([ "$INSTALL_AI" == "true" ] && echo "${COLOR_GREEN}✓${COLOR_RESET}" || echo "${COLOR_GRAY}✗${COLOR_RESET}")"
    echo -e "    - Python:    $([ "$INSTALL_PYTHON" == "true" ] && echo "${COLOR_GREEN}✓${COLOR_RESET}" || echo "${COLOR_GRAY}✗${COLOR_RESET}")"
    echo -e "    - Shell:     $([ "$INSTALL_SHELL_TOOLS" == "true" ] && echo "${COLOR_GREEN}✓${COLOR_RESET}" || echo "${COLOR_GRAY}✗${COLOR_RESET}")"
    echo -e "    - UV:        $([ "$INSTALL_UV" == "true" ] && echo "${COLOR_GREEN}✓${COLOR_RESET}" || echo "${COLOR_GRAY}✗${COLOR_RESET}")"
    echo -e "    - Bun:       $([ "$INSTALL_BUN" == "true" ] && echo "${COLOR_GREEN}✓${COLOR_RESET}" || echo "${COLOR_GRAY}✗${COLOR_RESET}")"
    echo -e "    - FNM:       $([ "$INSTALL_FNM" == "true" ] && echo "${COLOR_GREEN}✓${COLOR_RESET}" || echo "${COLOR_GRAY}✗${COLOR_RESET}")"
    echo -e "    - Go:        $([ "$INSTALL_GO" == "true" ] && echo "${COLOR_GREEN}✓${COLOR_RESET}" || echo "${COLOR_GRAY}✗${COLOR_RESET}")"
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
  if [[ $INSTALL_DOCKER == "true" ]] && cmd_exists docker; then
    log_success "docker: $(docker --version)"
  fi

  # Check Ollama
  if [[ $INSTALL_AI == "true" ]] && cmd_exists ollama; then
    log_success "ollama: $(ollama --version)"
  fi

  # Check Python tools
  if [[ $INSTALL_PYTHON == "true" ]]; then
    if cmd_exists uv; then
      log_success "uv: $(uv --version)"
    fi
    if cmd_exists pipx; then
      log_success "pipx: $(pipx --version)"
    fi
  fi

  # Check Shell tools
  if [[ $INSTALL_SHELL_TOOLS == "true" ]]; then
    if cmd_exists shellcheck; then
      log_success "shellcheck: $(shellcheck --version | head -1)"
    fi
    if cmd_exists shfmt; then
      log_success "shfmt: $(shfmt --version)"
    fi
  fi

  # Check UV
  if [[ $INSTALL_UV == "true" ]]; then
    if cmd_exists uv; then
      log_success "uv: $(uv --version)"
    fi
  fi

  # Check Bun
  if [[ $INSTALL_BUN == "true" ]]; then
    if cmd_exists bun; then
      log_success "bun: $(bun --version)"
    fi
  fi

  # Check FNM
  if [[ $INSTALL_FNM == "true" ]]; then
    if cmd_exists fnm; then
      log_success "fnm: $(fnm --version)"
    fi
  fi

  # Check Go
  if [[ $INSTALL_GO == "true" ]]; then
    if cmd_exists go; then
      log_success "go: $(go version)"
    fi
  fi

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# =============================================================================
# Print welcome message
# =============================================================================
print_welcome() {
  cat <<EOF

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

  # If user didn't specify any optional modules, allow interactive selection.
  # In --yes mode, keep non-interactive behavior (don't prompt).
  if [[ "${SKIP_MODULES:-false}" != "true" ]] && [[ "${YES_MODE:-false}" != "true" ]]; then
    if ! any_modules_selected; then
      prompt_module_selection
    fi
  fi

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
  if [[ $SKIP_MODULES == "false" ]] && [[ $INSTALL_PYTHON == "true" ]]; then
    source "${LIB_DIR}/modules/python.sh"
    install_python_tools
  fi

  # Install Shell tools
  if [[ $SKIP_MODULES == "false" ]] && [[ $INSTALL_SHELL_TOOLS == "true" ]]; then
    log_step "Installing Shell tools..."
    if [[ "$PACKAGE_MANAGER" == "brew" ]]; then
      brew install shellcheck shfmt
    elif [[ "$PACKAGE_MANAGER" == "apk" ]]; then
      apk add --no-cache shellcheck shfmt
    elif [[ "$PACKAGE_MANAGER" == "pacman" ]]; then
      pacman -S --noconfirm shellcheck shfmt
    elif [[ "$PACKAGE_MANAGER" == "apt" ]]; then
      apt-get update && apt-get install -y shellcheck
      if ! cmd_exists shfmt; then
        if cmd_exists go; then
          go install mvdan.cc/sh/v3/cmd/shfmt@latest
        else
          apt-get install -y golang-go
          go install mvdan.cc/sh/v3/cmd/shfmt@latest
        fi
        ln -sf "$HOME/go/bin/shfmt" /usr/local/bin/shfmt 2>/dev/null || true
      fi
    elif [[ "$PACKAGE_MANAGER" == "dnf" ]] || [[ "$PACKAGE_MANAGER" == "yum" ]]; then
      dnf install -y shellcheck
      if ! cmd_exists shfmt; then
        local shfmt_version="v3.8.0"
        local shfmt_url="https://github.com/mvdan/sh/releases/download/${shfmt_version}/shfmt_${shfmt_version}_linux_amd64"
        curl -sSL "$shfmt_url" -o /usr/local/bin/shfmt
        chmod +x /usr/local/bin/shfmt
      fi
    else
      curl -sSL https://raw.githubusercontent.com/koalaman/shellcheck/master/install.sh | sudo bash || true
      local shfmt_version="v3.8.0"
      curl -sSL "https://github.com/mvdan/sh/releases/download/${shfmt_version}/shfmt_${shfmt_version}_linux_amd64" -o /usr/local/bin/shfmt
      chmod +x /usr/local/bin/shfmt
    fi
    log_success "Shell tools installed!"
  fi

  # Install UV
  if [[ $SKIP_MODULES == "false" ]] && [[ $INSTALL_UV == "true" ]]; then
    log_step "Installing UV..."
    if [[ "$PACKAGE_MANAGER" == "brew" ]]; then
      brew install uv
    elif [[ "$PACKAGE_MANAGER" == "pacman" ]]; then
      pacman -S --noconfirm uv
    elif [[ "$PACKAGE_MANAGER" == "apk" ]]; then
      apk add --no-cache uv
    elif [[ "$PACKAGE_MANAGER" == "apt" ]] || [[ "$PACKAGE_MANAGER" == "dnf" ]] || [[ "$PACKAGE_MANAGER" == "yum" ]]; then
      curl -LsSf --connect-timeout 15 --max-time 120 https://astral.sh/uv/install.sh | sh
    else
      curl -LsSf --connect-timeout 15 --max-time 120 https://astral.sh/uv/install.sh | sh
    fi
  fi

  # Install Bun（联网超时避免长时间卡住）
  if [[ $SKIP_MODULES == "false" ]] && [[ $INSTALL_BUN == "true" ]]; then
    log_step "Installing Bun..."
    if [[ "$PACKAGE_MANAGER" == "brew" ]]; then
      brew install bun
    elif [[ "$PACKAGE_MANAGER" == "pacman" ]]; then
      pacman -S --noconfirm bun
    elif [[ "$PACKAGE_MANAGER" == "apt" ]] || [[ "$PACKAGE_MANAGER" == "dnf" ]] || [[ "$PACKAGE_MANAGER" == "yum" ]]; then
      curl -fsSL --connect-timeout 15 --max-time 120 https://bun.sh/install | bash
    else
      curl -fsSL --connect-timeout 15 --max-time 120 https://bun.sh/install | bash
    fi
  fi

  # Install FNM
  if [[ $SKIP_MODULES == "false" ]] && [[ $INSTALL_FNM == "true" ]]; then
    log_step "Installing FNM..."
    if [[ "$PACKAGE_MANAGER" == "brew" ]]; then
      brew install fnm
    elif [[ "$PACKAGE_MANAGER" == "pacman" ]]; then
      pacman -S --noconfirm fnm
    elif [[ "$PACKAGE_MANAGER" == "apt" ]] || [[ "$PACKAGE_MANAGER" == "dnf" ]] || [[ "$PACKAGE_MANAGER" == "yum" ]]; then
      # 联网超时避免长时间卡住；vercel 不可用时回退到 GitHub release
      local curl_opt="--connect-timeout 15 --max-time 60"
      if ! curl -fsSL $curl_opt https://fnm.vercel.app/install | bash; then
        log_warn "FNM installer via fnm.vercel.app failed, falling back to GitHub release..."
        if [[ "$PACKAGE_MANAGER" == "apt" ]]; then
          DEBIAN_FRONTEND=noninteractive apt-get update -qq
          DEBIAN_FRONTEND=noninteractive apt-get install -y -qq unzip ca-certificates >/dev/null 2>&1
          update-ca-certificates 2>/dev/null || true
        fi
        local fnm_dir="${HOME}/.local/share/fnm"
        mkdir -p "$fnm_dir"
        local tmp_zip="/tmp/fnm-linux.zip"
        if curl -fsSL $curl_opt "https://github.com/Schniz/fnm/releases/latest/download/fnm-linux.zip" -o "$tmp_zip" && [[ -f "$tmp_zip" ]]; then
          unzip -o "$tmp_zip" -d "$fnm_dir" >/dev/null 2>&1
          chmod +x "${fnm_dir}/fnm" 2>/dev/null || true
        fi
      fi
    else
      local curl_opt="--connect-timeout 15 --max-time 60"
      if ! curl -fsSL $curl_opt https://fnm.vercel.app/install | bash; then
        log_warn "FNM installer via fnm.vercel.app failed, falling back to GitHub release..."
        local fnm_dir="${HOME}/.local/share/fnm"
        mkdir -p "$fnm_dir"
        local tmp_zip="/tmp/fnm-linux.zip"
        if curl -fsSL $curl_opt "https://github.com/Schniz/fnm/releases/latest/download/fnm-linux.zip" -o "$tmp_zip" && [[ -f "$tmp_zip" ]] && command -v unzip >/dev/null 2>&1; then
          unzip -o "$tmp_zip" -d "$fnm_dir" >/dev/null 2>&1
          chmod +x "${fnm_dir}/fnm" 2>/dev/null || true
        fi
      fi
    fi
  fi

  # Install Go
  if [[ $SKIP_MODULES == "false" ]] && [[ $INSTALL_GO == "true" ]]; then
    log_step "Installing Go..."
    if [[ "$PACKAGE_MANAGER" == "brew" ]]; then
      brew install go
    elif [[ "$PACKAGE_MANAGER" == "apk" ]]; then
      apk add --no-cache go
    elif [[ "$PACKAGE_MANAGER" == "pacman" ]]; then
      pacman -S --noconfirm go
    elif [[ "$PACKAGE_MANAGER" == "apt" ]]; then
      # Ensure package index is available in minimal images
      DEBIAN_FRONTEND=noninteractive apt-get update -qq
      DEBIAN_FRONTEND=noninteractive apt-get install -y golang-go
    elif [[ "$PACKAGE_MANAGER" == "dnf" ]] || [[ "$PACKAGE_MANAGER" == "yum" ]]; then
      dnf install -y golang
    else
      curl -sSL https://go.dev/dl/go1.21.0.linux-amd64.tar.gz | tar -C /usr/local -xzf -
    fi
  fi

  # Prompt for container runtime if neither Docker nor Podman is selected
  if [[ $SKIP_MODULES == "false" ]] && [[ $INSTALL_DOCKER == "false" ]] && [[ $INSTALL_PODMAN == "false" ]]; then
    if ask_confirmation "Install container runtime (Docker/Podman)?" "n"; then
      source "${LIB_DIR}/shell_setup.sh"
      prompt_container_selection
    fi
  fi

  # Install Docker
  if [[ $SKIP_MODULES == "false" ]] && [[ $INSTALL_DOCKER == "true" ]]; then
    source "${LIB_DIR}/modules/docker.sh"
    install_docker
  fi

  # Install Podman
  if [[ $SKIP_MODULES == "false" ]] && [[ $INSTALL_PODMAN == "true" ]]; then
    source "${LIB_DIR}/modules/docker.sh"
    install_podman
  fi

  # Install AI tools
  if [[ $SKIP_MODULES == "false" ]] && [[ $INSTALL_AI == "true" ]]; then
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

  # Final message (re-init messages so MSG is set e.g. after sourcing os-release)
  init_messages
  cat <<EOF

╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   ${MSG[completed]}                                           ║
║                                                               ║
║   ${MSG[next_steps]}                                          ║
║   ${MSG[restart_terminal]}                                    ║
║   ${MSG[run_shell]}                                           ║
║                                                               ║
║   ${MSG[configure_git]}                                       ║
║                                                               ║
║   ${MSG[blog]}                                                ║
║   ${MSG[repo]}                                                ║
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
