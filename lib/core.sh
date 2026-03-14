#!/usr/bin/env bash
# =============================================================================
# core.sh - Core functions library for dev-setup
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Colors
# -----------------------------------------------------------------------------
export COLOR_RESET='\033[0m'
export COLOR_RED='\033[0;31m'
export COLOR_GREEN='\033[0;32m'
export COLOR_YELLOW='\033[0;33m'
export COLOR_BLUE='\033[0;34m'
export COLOR_MAGENTA='\033[0;35m'
export COLOR_CYAN='\033[0;36m'
export COLOR_GRAY='\033[0;90m'

# -----------------------------------------------------------------------------
# Language support
# -----------------------------------------------------------------------------
export LANGUAGE="${LANGUAGE:-en}"
export -A MSG=()

init_messages() {
  # Re-read language from environment if set
  if [[ -n ${LANGUAGE:-} ]] && [[ $LANGUAGE != "en" ]]; then
    export LANGUAGE
  fi

  case "$LANGUAGE" in
  zh | cn)
    MSG[welcome]="欢迎使用 dev-setup！🚀"
    MSG[welcome_sub]="本脚本将帮助你配置开发环境"
    MSG[blog]="博客: https://skippingpetticoatconvent.github.io/"
    MSG[repo]="仓库: https://github.com/SKIPPINGpetticoatconvent/dev-setup"
    MSG[os_detected]="检测到系统: "
    MSG[select_shell]="请选择你的首选 Shell:"
    MSG[shell_fish]="Fish Shell (推荐 - 现代、用户友好、开箱即用)"
    MSG[shell_zsh]="Zsh (强大、可扩展，带 Oh My Zsh 框架)"
    MSG[enter_choice]="请输入选项 [1-2]:"
    MSG[selected_shell]="选择的 Shell: "
    MSG[installing_fish]="正在安装 Fish Shell..."
    MSG[installing_zsh]="正在安装 Zsh..."
    MSG[installing_starship]="正在安装 Starship 提示符..."
    MSG[installing_fzf]="正在安装 fzf..."
    MSG[installing_tmux]="正在安装 tmux..."
    MSG[installing_docker]="正在安装 Docker..."
    MSG[installing_podman]="正在安装 Podman..."
    MSG[installing_ai]="正在安装 AI 工具..."
    MSG[installing_python]="正在安装 Python 工具..."
    MSG[setting_dotfiles]="正在配置 Dotfiles..."
    MSG[completed]="🎉 安装完成!"
    MSG[next_steps]="后续步骤:"
    MSG[restart_terminal]="1. 重启终端或打开新的 shell"
    MSG[run_shell]="2. 运行 fish 或 zsh 初始化"
    MSG[configure_git]="3. 别忘了配置 ~/.gitconfig"
    MSG[configuring_docker]="正在配置 Docker..."
    MSG[docker_group]="已将用户添加到 docker 组，请重新登录使更改生效"
    MSG[select_container]="请选择容器运行时:"
    MSG[container_docker]="Docker (推荐)"
    MSG[container_podman]="Podman (无守护进程，更安全)"
    MSG[enter_container]="请输入选项 [1-2]:"
    MSG[checking]="检查..."
    MSG[already_installed]="已安装"
    MSG[installing]="正在安装..."
    MSG[failed]="安装失败"
    MSG[skipping]="跳过"
    MSG[cleanup_old]="正在清理旧安装..."
    MSG[verify_install]="验证安装..."
    ;;
  *)
    MSG[welcome]="Welcome to dev-setup! 🚀"
    MSG[welcome_sub]="This script will set up your development environment"
    MSG[blog]="Blog: https://skippingpetticoatconvent.github.io/"
    MSG[repo]="Repo: https://github.com/SKIPPINGpetticoatconvent/dev-setup"
    MSG[os_detected]="Detected: "
    MSG[select_shell]="Please select your preferred shell:"
    MSG[shell_fish]="Fish Shell (Recommended - Modern, user-friendly, great out-of-box experience)"
    MSG[shell_zsh]="Zsh (Powerful, extensible, with Oh My Zsh framework)"
    MSG[enter_choice]="Enter your choice [1-2]:"
    MSG[selected_shell]="Selected shell: "
    MSG[installing_fish]="Installing Fish Shell..."
    MSG[installing_zsh]="Installing Zsh..."
    MSG[installing_starship]="Installing Starship prompt..."
    MSG[installing_fzf]="Installing fzf..."
    MSG[installing_tmux]="Installing tmux..."
    MSG[installing_docker]="Installing Docker..."
    MSG[installing_podman]="Installing Podman..."
    MSG[installing_ai]="Installing AI tools..."
    MSG[installing_python]="Installing Python tools..."
    MSG[setting_dotfiles]="Setting up dotfiles..."
    MSG[completed]="🎉 Installation completed!"
    MSG[next_steps]="Next steps:"
    MSG[restart_terminal]="1. Restart your terminal or open a new shell"
    MSG[run_shell]="2. Run the shell (fish/zsh) to initialize"
    MSG[configure_git]="3. Don't forget to configure ~/.gitconfig"
    MSG[configuring_docker]="Configuring Docker..."
    MSG[docker_group]="Added user to docker group. Please log out and back in."
    MSG[select_container]="Please select container runtime:"
    MSG[container_docker]="Docker (Recommended)"
    MSG[container_podman]="Podman (Daemonless, more secure)"
    MSG[enter_container]="Enter your choice [1-2]:"
    MSG[checking]="Checking..."
    MSG[already_installed]="already installed"
    MSG[installing]="Installing..."
    MSG[failed]="Failed"
    MSG[skipping]="Skipping"
    MSG[cleanup_old]="Cleaning up old installations..."
    MSG[verify_install]="Verifying installation..."
    ;;
  esac
}

# -----------------------------------------------------------------------------
# Logging functions
# -----------------------------------------------------------------------------
log_info() {
  echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $*"
}

log_success() {
  echo -e "${COLOR_GREEN}[✓]${COLOR_RESET} $*"
}

log_warn() {
  echo -e "${COLOR_YELLOW}[⚠]${COLOR_RESET} $*"
}

log_error() {
  echo -e "${COLOR_RED}[✗]${COLOR_RESET} $*" >&2
}

log_step() {
  echo -e "${COLOR_CYAN}[→]${COLOR_RESET} $*"
}

log_debug() {
  if [[ ${DEBUG:-0} == "1" ]]; then
    echo -e "${COLOR_GRAY}[DEBUG]${COLOR_RESET} $*"
  fi
}

# -----------------------------------------------------------------------------
# Error handling
# -----------------------------------------------------------------------------
trap_err() {
  local lineno=$1
  local msg=$2
  log_error "Error occurred in script at line $lineno: $msg"
  exit 1
}

trap 'trap_err $LINENO "$BASH_COMMAND"' ERR

# -----------------------------------------------------------------------------
# Command existence check
# -----------------------------------------------------------------------------
cmd_exists() {
  command -v "$1" >/dev/null 2>&1
}

require_cmd() {
  if ! cmd_exists "$1"; then
    log_error "Required command '$1' not found. Please install it first."
    return 1
  fi
}

# -----------------------------------------------------------------------------
# Package existence check (installed via brew/apt)
# -----------------------------------------------------------------------------
pkg_installed() {
  local pkg="$1"

  case "${PACKAGE_MANAGER:-}" in
  brew)
    brew list "$pkg" >/dev/null 2>&1
    ;;
  apt)
    dpkg -l "$pkg" >/dev/null 2>&1
    ;;
  *)
    command -v "$pkg" >/dev/null 2>&1
    ;;
  esac
}

# -----------------------------------------------------------------------------
# Backup functions
# -----------------------------------------------------------------------------
backup_file() {
  local file="$1"
  local backup="${file}.bak.$(date +%Y%m%d%H%M%S)"

  if [[ -e $file || -L $file ]]; then
    if [[ -L $file ]]; then
      local target
      target=$(readlink -f "$file")
      log_warn "Removing existing symlink: $file -> $target"
      rm -f "$file"
    else
      log_warn "Backing up existing file: $file -> $backup"
      cp -a "$file" "$backup"
    fi
  fi
  return 0
}

backup_dir() {
  local dir="$1"
  local backup="${dir}.bak.$(date +%Y%m%d%H%M%S)"

  if [[ -d $dir ]]; then
    log_warn "Backing up existing directory: $dir -> $backup"
    mv "$dir" "$backup"
  fi
  return 0
}

# -----------------------------------------------------------------------------
# User confirmation
# -----------------------------------------------------------------------------
ask_confirmation() {
  local prompt="${1:-Continue?}"
  local default="${2:-n}"

  # --yes 时采用默认值，不交互
  if [[ "${YES_MODE:-0}" == "1" || "${YES_MODE:-}" == "true" ]]; then
    [[ "$default" == "y" ]] && return 0 || return 1
  fi

  local yn
  case "$default" in
  y) yn="[Y/n]" ;;
  n) yn="[y/N]" ;;
  *) yn="[y/n]" ;;
  esac

  echo -ne "${COLOR_CYAN}$prompt $yn:${COLOR_RESET} "
  read -r yn

  case "$yn" in
  y | Y | yes | Yes | YES) return 0 ;;
  n | N | no | No | NO)
    if [[ $default == "y" ]]; then
      return 0
    fi
    return 1
    ;;
  *)
    [[ $default == "y" ]] && return 0 || return 1
    ;;
  esac
}

# -----------------------------------------------------------------------------
# Directory creation
# -----------------------------------------------------------------------------
ensure_dir() {
  local dir="$1"
  if [[ ! -d $dir ]]; then
    log_debug "Creating directory: $dir"
    mkdir -p "$dir"
  fi
}

# -----------------------------------------------------------------------------
# File operations
# -----------------------------------------------------------------------------
safe_write() {
  local file="$1"
  local content="$2"
  local mode="${3:-0644}"

  ensure_dir "$(dirname "$file")"
  echo "$content" >"$file"
  chmod "$mode" "$file"
}

# -----------------------------------------------------------------------------
# Symlink operations
# -----------------------------------------------------------------------------
safe_symlink() {
  local target="$1"
  local link="$2"

  if [[ -e $link || -L $link ]]; then
    backup_file "$link"
  fi

  ensure_dir "$(dirname "$link")"
  ln -sf "$target" "$link"
  log_debug "Created symlink: $link -> $target"
}

# -----------------------------------------------------------------------------
# Download functions
# -----------------------------------------------------------------------------
download_file() {
  local url="$1"
  local output="$2"

  if cmd_exists curl; then
    curl -fsSL "$url" -o "$output"
  elif cmd_exists wget; then
    wget -q "$url" -O "$output"
  else
    log_error "Neither curl nor wget available"
    return 1
  fi
}

# -----------------------------------------------------------------------------
# Shell detection
# -----------------------------------------------------------------------------
get_current_shell() {
  if [[ -n ${BASH_VERSION:-} ]]; then
    echo "bash"
  elif [[ -n ${ZSH_VERSION:-} ]]; then
    echo "zsh"
  elif [[ -n ${FISH_VERSION:-} ]]; then
    echo "fish"
  else
    echo "unknown"
  fi
}

# -----------------------------------------------------------------------------
# Version comparison
# -----------------------------------------------------------------------------
version_ge() {
  local v1="$1"
  local v2="$2"

  if [[ $v1 == "$v2" ]]; then
    return 0
  fi

  local IFS=.
  local i ver1=($v1) ver2=($v2)

  for ((i = 0; i < ${#ver1[@]} || i < ${#ver2[@]}; i++)); do
    local num1=${ver1[i]:-0}
    local num2=${ver2[i]:-0}

    if ((10#$num1 > 10#$num2)); then
      return 0
    elif ((10#$num1 < 10#$num2)); then
      return 1
    fi
  done

  return 0
}

# -----------------------------------------------------------------------------
# Progress indicator
# -----------------------------------------------------------------------------
spinner_pid=""
start_spinner() {
  local msg="${1:-Working...}"
  local chars="/-\|"
  local pid=$$

  (
    while kill -0 "$pid" 2>/dev/null; do
      for char in $chars; do
        echo -ne "\r${COLOR_CYAN}$char${COLOR_RESET} $msg"
        sleep 0.1
      done
    done
  ) &
  spinner_pid=$!
}

stop_spinner() {
  if [[ -n $spinner_pid ]]; then
    kill "$spinner_pid" 2>/dev/null || true
    echo -ne "\r${COLOR_GREEN}✓${COLOR_RESET} Done\n"
  fi
}

# -----------------------------------------------------------------------------
# Banner
# -----------------------------------------------------------------------------
print_banner() {
  cat <<'EOF'
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   ██████╗ ███████╗████████╗██████╗  ██████╗                   ║
║   ██╔══██╗██╔════╝╚══██╔══╝██╔══██╗██╔═══██╗                  ║
║   ██████╔╝█████╗     ██║   ██████╔╝██║   ██║                  ║
║   ██╔══██╗██╔══╝     ██║   ██╔══██╗██║   ██║                  ║
║   ██║  ██║███████╗   ██║   ██║  ██║╚██████╔╝                  ║
║   ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝                   ║
║                                                               ║
║              Development Environment Setup                   ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
}
