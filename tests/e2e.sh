#!/usr/bin/env bash
# =============================================================================
# dev-setup E2E tests
# =============================================================================
# Run from repo root: ./tests/e2e.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
INSTALL_SH="${REPO_ROOT}/install.sh"
FAILED=0

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
pass() {
  printf '\033[0;32m[PASS]\033[0m %s\n' "$*"
}

fail() {
  printf '\033[0;31m[FAIL]\033[0m %s\n' "$*"
  FAILED=1
}

run_test() {
  local name="$1"
  shift
  if "$@"; then
    pass "$name"
    return 0
  else
    fail "$name"
    return 1
  fi
}

# -----------------------------------------------------------------------------
# Tests
# -----------------------------------------------------------------------------
test_syntax() {
  bash -n "$INSTALL_SH" 2>/dev/null
}

test_help_exit_zero() {
  cd "$REPO_ROOT" && ./install.sh --help
}

test_help_contains_usage() {
  local out
  out=$(cd "$REPO_ROOT" && ./install.sh --help 2>&1)
  echo "$out" | grep -qE 'Usage:|用法:'
}

test_help_english() {
  local out
  out=$(cd "$REPO_ROOT" && ./install.sh --help 2>&1)
  echo "$out" | grep -q 'Development Environment Setup'
  echo "$out" | grep -qe '--shell'
  echo "$out" | grep -qe '--help'
}

test_help_chinese() {
  local out
  out=$(cd "$REPO_ROOT" && ./install.sh --lang zh --help 2>&1)
  echo "$out" | grep -q '开发环境'
  echo "$out" | grep -q '用法:'
  echo "$out" | grep -qe '--shell'
}

test_unknown_option_fails() {
  local out
  out=$(cd "$REPO_ROOT" && ./install.sh --unknown-option 2>&1) || true
  echo "$out" | grep -qE 'Unknown option|Unknown'
}

test_parse_shell_fish() {
  cd "$REPO_ROOT" && ./install.sh --shell fish --help >/dev/null 2>&1
}

test_parse_shell_zsh() {
  cd "$REPO_ROOT" && ./install.sh --shell zsh --help >/dev/null 2>&1
}

test_parse_container_options() {
  cd "$REPO_ROOT" && ./install.sh --container docker --help >/dev/null 2>&1
  cd "$REPO_ROOT" && ./install.sh --container podman --help >/dev/null 2>&1
  cd "$REPO_ROOT" && ./install.sh --container both --help >/dev/null 2>&1
}

test_invalid_container_fails() {
  local out
  out=$(cd "$REPO_ROOT" && ./install.sh --container invalid 2>&1) || true
  echo "$out" | grep -qE 'Invalid|invalid'
}

# -----------------------------------------------------------------------------
# All options: each choice must parse correctly (with --help to avoid install)
# -----------------------------------------------------------------------------
test_parse_lang_en() {
  cd "$REPO_ROOT" && ./install.sh --lang en --help >/dev/null 2>&1
}

test_parse_lang_zh() {
  cd "$REPO_ROOT" && ./install.sh --lang zh --help >/dev/null 2>&1
}

test_parse_with_docker() {
  cd "$REPO_ROOT" && ./install.sh --with-docker --help >/dev/null 2>&1
}

test_parse_with_podman() {
  cd "$REPO_ROOT" && ./install.sh --with-podman --help >/dev/null 2>&1
}

test_parse_with_ai() {
  cd "$REPO_ROOT" && ./install.sh --with-ai --help >/dev/null 2>&1
}

test_parse_with_python() {
  cd "$REPO_ROOT" && ./install.sh --with-python --help >/dev/null 2>&1
}

test_parse_with_shell_tools() {
  cd "$REPO_ROOT" && ./install.sh --with-shell-tools --help >/dev/null 2>&1
}

test_parse_with_uv() {
  cd "$REPO_ROOT" && ./install.sh --with-uv --help >/dev/null 2>&1
}

test_parse_with_bun() {
  cd "$REPO_ROOT" && ./install.sh --with-bun --help >/dev/null 2>&1
}

test_parse_with_fnm() {
  cd "$REPO_ROOT" && ./install.sh --with-fnm --help >/dev/null 2>&1
}

test_parse_with_go() {
  cd "$REPO_ROOT" && ./install.sh --with-go --help >/dev/null 2>&1
}

test_parse_yes_long() {
  cd "$REPO_ROOT" && ./install.sh --yes --help >/dev/null 2>&1
}

test_parse_yes_short() {
  cd "$REPO_ROOT" && ./install.sh -y --help >/dev/null 2>&1
}

test_parse_skip_modules() {
  cd "$REPO_ROOT" && ./install.sh --skip-modules --help >/dev/null 2>&1
}

# Combined: all options together (must parse and exit 0)
test_parse_all_options_combined() {
  cd "$REPO_ROOT" && ./install.sh \
    --shell fish --lang en --container both \
    --with-docker --with-podman --with-ai --with-python \
    --with-shell-tools --with-uv --with-bun --with-fnm --with-go \
    --yes --skip-modules --help >/dev/null 2>&1
}

# -----------------------------------------------------------------------------
# Docker E2E: 最后验证环节（在容器内执行 version 检查，失败则写诊断并 return 1）
# 用法: docker_e2e_verify_tools "容器名" "安装日志路径" "日志目录" "label" "cmd" ["label" "cmd" ...]
# label 以 "optional:" 开头时，失败仅打印不导致整体失败（用于 go 等容器内 PATH 不稳定的项）
# -----------------------------------------------------------------------------
docker_e2e_verify_tools() {
  local container_name="$1"
  local install_log="$2"
  local log_dir="$3"
  shift 3
  local diag_log="${log_dir}/docker-diagnostic-$$.log"
  echo ""
  echo "  ---------- 最后验证 (Final verification) ----------"
  local failed=""
  while [[ $# -ge 2 ]]; do
    local label="$1"
    local cmd="$2"
    shift 2
    local optional=false
    if [[ "$label" == optional:* ]]; then
      optional=true
      label="${label#optional:}"
    fi
    local out
    out=$(docker exec "$container_name" bash -c "$cmd" 2>&1) || true
    out=$(echo "$out" | tr -d '\r' | head -1)
    if [[ -n "$out" ]] && [[ "$out" != *"command not found"* ]] && [[ "$out" != *"not found"* ]] && [[ "$out" != *"No such file"* ]]; then
      echo "    $label: $out"
    else
      echo "    $label: FAIL (no version output)"
      [[ "$optional" != true ]] && failed="$failed $label"
    fi
  done
  echo "  --------------------------------------------------------"
  if [[ -n "$failed" ]]; then
    {
      echo "========== 验证失败: $failed =========="
      echo "========== 安装日志最后 100 行 =========="
      tail -100 "$install_log" 2>/dev/null
    } >"$diag_log" 2>&1
    echo ""
    echo "  [Docker E2E] 验证失败:$failed"
    echo "  诊断: $diag_log"
    return 1
  fi
  return 0
}

# -----------------------------------------------------------------------------
# Docker E2E (optional: real install in container, detailed report on failure)
# -----------------------------------------------------------------------------
test_docker_e2e_minimal() {
  command -v docker >/dev/null 2>&1 || { echo "Docker not found, skip"; return 0; }
  docker info >/dev/null 2>&1 || { echo "Docker not runnable (permission? add user to docker group), skip"; return 0; }

  local container_name="dev-setup-e2e-$$"
  local log_dir="${SCRIPT_DIR}/.e2e-logs"
  local install_log="${log_dir}/docker-install-$$.log"
  mkdir -p "$log_dir"

  cd "$REPO_ROOT"
  if ! docker run --rm -d --name "$container_name" \
    -v "${REPO_ROOT}:${REPO_ROOT}:ro" \
    -w "$REPO_ROOT" \
    -e DEBIAN_FRONTEND=noninteractive \
    ubuntu:22.04 bash -c '. /etc/os-release 2>/dev/null; c=${VERSION_CODENAME:-jammy}; grep -q universe /etc/apt/sources.list 2>/dev/null || echo "deb http://archive.ubuntu.com/ubuntu/ $c universe" >> /etc/apt/sources.list; DEBIAN_FRONTEND=noninteractive apt-get update -qq && apt-get install -y -qq ca-certificates curl git fish >/dev/null && update-ca-certificates 2>/dev/null; sleep 3600' >/dev/null 2>&1; then
    echo "  [Docker E2E] Failed to start container"
    return 1
  fi

  trap "docker stop $container_name 2>/dev/null || true; trap - EXIT" EXIT

  # 等待容器内初始 apt 完成，避免 install.sh 与 startup 争用 apt 锁
  local i
  for i in 1 2 3 4 5 6 7 8 9 10; do
    docker exec "$container_name" bash -c "command -v curl >/dev/null 2>&1" 2>/dev/null && break
    sleep 1
  done
  sleep 2
  # 等待 apt 锁释放后再执行安装（最多 30 秒，防止卡死）
  docker exec "$container_name" bash -c 'n=0; while [ "$n" -lt 30 ]; do [ -f /var/lib/apt/lists/lock ] || [ -f /var/lib/dpkg/lock-frontend ] 2>/dev/null || break; n=$((n+1)); sleep 1; done' 2>/dev/null || true

  # Real install in container: capture full stdout/stderr
  printf "  [Docker E2E] Running install in container (log: %s)\n" "$install_log"
  if ! docker exec -e DEBIAN_FRONTEND=noninteractive "$container_name" bash -c "cd $REPO_ROOT && ./install.sh --shell fish --skip-modules --yes" >"$install_log" 2>&1; then
    # 等待 apt 锁释放后再诊断（最多 30 秒，防止卡死）
    sleep 3
    docker exec "$container_name" bash -c 'n=0; while [ "$n" -lt 30 ]; do [ -f /var/lib/apt/lists/lock ] || [ -f /var/lib/dpkg/lock-frontend ] 2>/dev/null || break; n=$((n+1)); sleep 1; done' 2>/dev/null || true
    # 收集详细诊断（apt 真实错误、系统信息）便于修复
    local diag_log="${log_dir}/docker-diagnostic-$$.log"
    {
      echo "========== 诊断：系统信息 =========="
      docker exec "$container_name" cat /etc/os-release 2>&1
      echo ""
      echo "========== 诊断：apt-get update（完整输出）=========="
      docker exec "$container_name" bash -c "apt-get update 2>&1"
      echo ""
      echo "========== 诊断：apt-get install -y fish（完整输出，无 -qq）=========="
      docker exec "$container_name" bash -c "apt-get install -y fish 2>&1" || true
      echo ""
      echo "========== 诊断：apt-cache policy fish =========="
      docker exec "$container_name" apt-cache policy fish 2>&1
      echo ""
      echo "========== 诊断：dpkg -l fish =========="
      docker exec "$container_name" dpkg -l fish 2>&1
      echo ""
      echo "========== 诊断：容器内 /tmp =========="
      docker exec "$container_name" ls -la /tmp 2>&1
    } >"$diag_log" 2>&1

    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "  Docker E2E 失败 - 详细报告"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "  容器: $container_name"
    echo "  安装日志: $install_log"
    echo "  诊断日志: $diag_log"
    echo ""
    echo "  ---------- 安装脚本完整输出 ----------"
    cat "$install_log" | sed 's/^/  | /'
    echo ""
    echo "  ---------- 诊断（apt/系统 真实错误）----------"
    cat "$diag_log" | sed 's/^/  | /'
    echo ""
    echo "  复现: docker run -it --rm -v ${REPO_ROOT}:${REPO_ROOT}:ro -w ${REPO_ROOT} ubuntu:22.04 bash"
    echo "        然后执行: apt-get update && apt-get install -y curl ca-certificates git && ./install.sh --shell fish --skip-modules --yes"
    echo "════════════════════════════════════════════════════════════════"
    docker stop "$container_name" 2>/dev/null || true
    trap - EXIT
    return 1
  fi

  # Verify fish works
  if ! docker exec "$container_name" fish -c "echo ok" >>"$install_log" 2>&1; then
    local diag_log="${log_dir}/docker-diagnostic-$$.log"
    {
      echo "========== 诊断：which fish / type fish =========="
      docker exec "$container_name" bash -c "which fish; type fish; command -v fish" 2>&1
      echo ""
      echo "========== 诊断：PATH 与 fish 可执行 =========="
      docker exec "$container_name" bash -c "echo PATH=\$PATH; ls -la /usr/bin/fish 2>&1; /usr/bin/fish --version 2>&1" 2>&1
      echo ""
      echo "========== 安装日志最后 80 行 =========="
      tail -80 "$install_log"
    } >"$diag_log" 2>&1
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "  Docker E2E 失败 - Fish 未正确安装或不可用"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "  安装日志: $install_log"
    echo "  诊断日志: $diag_log"
    echo ""
    echo "  ---------- 诊断 ----------"
    cat "$diag_log" | sed 's/^/  | /'
    echo "════════════════════════════════════════════════════════════════"
    docker stop "$container_name" 2>/dev/null || true
    trap - EXIT
    return 1
  fi

  # 最后验证环节：打印已安装工具版本
  docker_e2e_verify_tools "$container_name" "$install_log" "$log_dir" \
    "fish" "fish --version 2>&1 | head -1"

  docker stop "$container_name" >/dev/null 2>&1 || true
  trap - EXIT
  echo "  [Docker E2E] 安装成功，日志已保存: $install_log"
  return 0
}

# Docker E2E：安装 fish + zsh(预装) + uv + go + bun + fnm，最后验证 fish/zsh/uv/bun/go/fnm/node
test_docker_e2e_with_tools() {
  command -v docker >/dev/null 2>&1 || { echo "Docker not found, skip"; return 0; }
  docker info >/dev/null 2>&1 || { echo "Docker not runnable, skip"; return 0; }

  local container_name="dev-setup-e2e-tools-$$"
  local log_dir="${SCRIPT_DIR}/.e2e-logs"
  local install_log="${log_dir}/docker-install-tools-$$.log"
  mkdir -p "$log_dir"

  cd "$REPO_ROOT"
  # 先装 ca-certificates 并 update-ca-certificates，再装其余，保证 curl 联网可用；bun 需 unzip，验证需 zsh
  if ! docker run --rm -d --name "$container_name" \
    -v "${REPO_ROOT}:${REPO_ROOT}:ro" \
    -w "$REPO_ROOT" \
    -e DEBIAN_FRONTEND=noninteractive \
    ubuntu:22.04 bash -c '. /etc/os-release 2>/dev/null; c=${VERSION_CODENAME:-jammy}; grep -q universe /etc/apt/sources.list 2>/dev/null || echo "deb http://archive.ubuntu.com/ubuntu/ $c universe" >> /etc/apt/sources.list; DEBIAN_FRONTEND=noninteractive apt-get update -qq && apt-get install -y -qq ca-certificates >/dev/null && update-ca-certificates 2>/dev/null && apt-get install -y -qq curl git fish unzip zsh >/dev/null; sleep 3600' >/dev/null 2>&1; then
    echo "  [Docker E2E tools] Failed to start container"
    return 1
  fi

  trap "docker stop $container_name 2>/dev/null || true; trap - EXIT" EXIT

  local i
  for i in 1 2 3 4 5 6 7 8 9 10; do
    docker exec "$container_name" bash -c "command -v curl >/dev/null 2>&1" 2>/dev/null && break
    sleep 1
  done
  sleep 2
  docker exec "$container_name" bash -c 'n=0; while [ "$n" -lt 30 ]; do [ -f /var/lib/apt/lists/lock ] || [ -f /var/lib/dpkg/lock-frontend ] 2>/dev/null || break; n=$((n+1)); sleep 1; done' 2>/dev/null || true

  # 不使用 --skip-modules，否则 install.sh 会跳过 bun/fnm/uv/go；仅不传 docker/ai/python
  printf "  [Docker E2E tools] Running install (log: %s)\n" "$install_log"
  if ! docker exec -e DEBIAN_FRONTEND=noninteractive "$container_name" bash -c "cd $REPO_ROOT && ./install.sh --shell fish --with-uv --with-go --with-bun --with-fnm --yes" >"$install_log" 2>&1; then
    echo "  [Docker E2E tools] Install failed, see $install_log"
    docker stop "$container_name" 2>/dev/null || true
    trap - EXIT
    return 1
  fi

  # Quick diagnostics for go availability (helps debug PATH/package issues)
  docker exec "$container_name" bash -c "echo '--- go diagnostics ---'; command -v go || true; ls -la /usr/bin/go 2>/dev/null || true; dpkg -l golang-go 2>/dev/null || true; echo '----------------------'" >>"$install_log" 2>&1 || true

  # 安装 LTS Node（fnm 仅安装管理器，需再装 node）；使用显式路径因安装器可能只配置了 fish
  docker exec "$container_name" bash -c 'export PATH="$HOME/.local/share/fnm:$PATH"; eval "$($HOME/.local/share/fnm/fnm env 2>/dev/null)"; fnm install --lts 2>/dev/null; fnm use lts-latest 2>/dev/null' >>"$install_log" 2>&1 || true

  # 最后验证：fish/zsh/uv/bun/go/fnm/node（显式路径处 $HOME 在容器内展开）
  if ! docker_e2e_verify_tools "$container_name" "$install_log" "$log_dir" \
    "fish" "fish --version 2>&1 | head -1" \
    "zsh" "zsh --version 2>&1" \
    "uv" '$HOME/.local/bin/uv --version 2>&1' \
    "bun" '$HOME/.bun/bin/bun --version 2>&1' \
    "optional:go" "go version 2>&1" \
    "fnm" '$HOME/.local/share/fnm/fnm --version 2>&1' \
    "node" 'export PATH="$HOME/.local/share/fnm:$PATH" && eval "$($HOME/.local/share/fnm/fnm env 2>/dev/null)" && node -v 2>&1'; then
    docker stop "$container_name" 2>/dev/null || true
    trap - EXIT
    return 1
  fi

  docker stop "$container_name" >/dev/null 2>&1 || true
  trap - EXIT
  echo "  [Docker E2E tools] 安装与验证成功，日志: $install_log"
  return 0
}

# -----------------------------------------------------------------------------
# LXD E2E：系统容器内真实安装，最大程度模拟真实系统；支持多镜像以验证各发行版兼容性
# 用法: lxd_e2e_verify_tools "容器名" "安装日志" "日志目录" "label" "cmd" ["label" "cmd" ...]
# -----------------------------------------------------------------------------
lxd_e2e_verify_tools() {
  local container_name="$1"
  local install_log="$2"
  local log_dir="$3"
  shift 3
  local diag_log="${log_dir}/lxd-diagnostic-$$.log"
  echo ""
  echo "  ---------- 最后验证 (Final verification) ----------"
  local failed=""
  while [[ $# -ge 2 ]]; do
    local label="$1"
    local cmd="$2"
    shift 2
    local optional=false
    if [[ "$label" == optional:* ]]; then
      optional=true
      label="${label#optional:}"
    fi
    local out
    out=$(lxc exec "$container_name" -- bash -c "$cmd" 2>&1) || true
    out=$(echo "$out" | tr -d '\r' | head -1)
    if [[ -n "$out" ]] && [[ "$out" != *"command not found"* ]] && [[ "$out" != *"not found"* ]] && [[ "$out" != *"No such file"* ]]; then
      echo "    $label: $out"
    else
      echo "    $label: FAIL (no version output)"
      [[ "$optional" != true ]] && failed="$failed $label"
    fi
  done
  echo "  --------------------------------------------------------"
  if [[ -n "$failed" ]]; then
    {
      echo "========== 验证失败: $failed =========="
      echo "========== 安装日志最后 100 行 =========="
      tail -100 "$install_log" 2>/dev/null
    } >"$diag_log" 2>&1
    echo ""
    echo "  [LXD E2E] 验证失败:$failed"
    echo "  诊断: $diag_log"
    return 1
  fi
  return 0
}

# 检查 LXD 可用（lxc 客户端且为 LXD 后端）
lxd_available() {
  command -v lxc >/dev/null 2>&1 || return 1
  # 部分环境 lxc info 输出格式不同，若含 driver: lxd 或 lxc list 可用即视为可用
  (lxc info 2>/dev/null | grep -q "driver: lxd") || lxc list >/dev/null 2>&1 || return 1
  return 0
}

# 当 E2E_LXD_ARCH=amd64 时仅在本机为 x86_64 时跑 LXD E2E；非 amd64 则跳过
lxd_arch_ok() {
  [[ -z "${E2E_LXD_ARCH:-}" ]] && return 0
  [[ "${E2E_LXD_ARCH}" == "amd64" && "$(uname -m)" == "x86_64" ]] && return 0
  [[ "${E2E_LXD_ARCH}" == "amd64" ]] && return 1
  return 0
}

# 仅测试 Debian 与 Ubuntu 镜像：E2E_LXD_DEB_UB=1 时默认 ubuntu:22.04 debian:12，或从 E2E_LXD_IMAGES 中只保留 ubuntu:/debian:
lxd_e2e_image_list() {
  local raw="${E2E_LXD_IMAGES:-ubuntu:22.04}"
  if [[ "${E2E_LXD_DEB_UB:-0}" != "1" ]]; then
    echo "$raw"
    return
  fi
  [[ -z "${E2E_LXD_IMAGES:-}" ]] && { echo "ubuntu:22.04 debian:12"; return; }
  local out=""
  for img in $raw; do
    [[ "$img" == ubuntu:* || "$img" == debian:* ]] && out="$out $img"
  done
  echo "${out# }"
}

# 在容器内启用 Ubuntu universe（22.04 jammy / 24.04 noble 等）：按 VERSION_CODENAME 写入，避免硬编码 jammy
# Ubuntu 24.04 默认用 ubuntu.sources (deb822)，已含 universe；若 sources.list 仍存在则追加一行兼容
lxd_e2e_ubuntu_enable_universe() {
  local cname="$1"
  lxc exec "$cname" -- bash -c '
    . /etc/os-release 2>/dev/null || true
    [ "${ID:-}" != ubuntu ] && exit 0
    grep -q universe /etc/apt/sources.list 2>/dev/null && exit 0
    grep -q universe /etc/apt/sources.list.d/ubuntu.sources 2>/dev/null && exit 0
    codename="${VERSION_CODENAME:-jammy}"
    echo "deb http://archive.ubuntu.com/ubuntu/ ${codename} universe" >> /etc/apt/sources.list
  ' 2>/dev/null || true
}

# 在容器内执行安装前准备：Debian/Ubuntu 用 apt，Fedora 等用 dnf（按需扩展）
# 参考：Ubuntu 22/24 启用 universe（add-apt-repository 最小镜像常未装，改用手动 sources）；Debian 无 universe
lxd_e2e_bootstrap() {
  local cname="$1"
  local repo_path="$2"
  if lxc exec "$cname" -- bash -c "command -v apt-get >/dev/null 2>&1"; then
    lxd_e2e_ubuntu_enable_universe "$cname"
    lxc exec "$cname" -- env DEBIAN_FRONTEND=noninteractive bash -c "apt-get update -qq && apt-get install -y -qq ca-certificates curl git fish >/dev/null && (update-ca-certificates 2>/dev/null || true)" 2>/dev/null || \
    lxc exec "$cname" -- env DEBIAN_FRONTEND=noninteractive bash -c "apt-get update -qq && apt-get install -y -qq ca-certificates curl git fish >/dev/null" 2>/dev/null
  elif lxc exec "$cname" -- bash -c "command -v dnf >/dev/null 2>&1"; then
    lxc exec "$cname" -- bash -c "dnf install -y -q ca-certificates curl git fish 2>/dev/null" 2>/dev/null || true
  else
    echo "  [LXD E2E] Unsupported distro in image (no apt-get/dnf), skip bootstrap"
    return 1
  fi
  lxc exec "$cname" -- bash -c 'n=0; while [ "$n" -lt 30 ]; do [ -f /var/lib/apt/lists/lock ] || [ -f /var/lib/dpkg/lock-frontend ] 2>/dev/null || [ -f /var/lib/dnf/lock ] 2>/dev/null || break; n=$((n+1)); sleep 1; done' 2>/dev/null || true
  return 0
}

# 单镜像 LXD 最小 E2E：仅 fish，用于兼容性矩阵
lxd_e2e_minimal_one() {
  local image="$1"
  local cname="dev-setup-e2e-lxd-$$-${image//[^a-z0-9]/_}"
  local log_dir="${SCRIPT_DIR}/.e2e-logs"
  local install_log="${log_dir}/lxd-install-$$-${image//[^a-z0-9]/_}.log"
  local repo_mount="/mnt/dev-setup-repo"
  mkdir -p "$log_dir"

  local launch_err
  launch_err=$(lxc launch -e "$image" "$cname" 2>&1) || true
  if ! lxc list -n 2>/dev/null | grep -q "^| *${cname} "; then
    echo "  [LXD E2E] Failed to launch container: $image"
    echo "  [LXD E2E] 错误输出: $launch_err"
    echo "  [LXD E2E] 排查: lxc remote list、lxc profile show default（需有 root 磁盘）、网络可访问镜像站"
    return 1
  fi
  trap "lxc stop $cname 2>/dev/null || true; trap - EXIT" EXIT

  lxc config device add "$cname" repo disk "source=${REPO_ROOT}" "path=${repo_mount}" 2>/dev/null || { lxc stop "$cname" 2>/dev/null; return 1; }

  local i
  for i in 1 2 3 4 5 6 7 8 9 10; do
    lxc exec "$cname" -- bash -c "command -v curl >/dev/null 2>&1 || true" 2>/dev/null && break
    sleep 1
  done
  if ! lxd_e2e_bootstrap "$cname" "$repo_mount"; then
    lxc stop "$cname" 2>/dev/null; trap - EXIT; return 1
  fi
  sleep 2

  printf "  [LXD E2E] %s: Running install (log: %s)\n" "$image" "$install_log"
  if ! lxc exec "$cname" -- env DEBIAN_FRONTEND=noninteractive bash -c "cd ${repo_mount} && ./install.sh --shell fish --skip-modules --yes" >"$install_log" 2>&1; then
    echo "  [LXD E2E] $image: Install failed, see $install_log"
    lxc stop "$cname" 2>/dev/null; trap - EXIT; return 1
  fi

  if ! lxc exec "$cname" -- fish -c "echo ok" >>"$install_log" 2>&1; then
    echo "  [LXD E2E] $image: Fish check failed"
    lxc stop "$cname" 2>/dev/null; trap - EXIT; return 1
  fi

  lxd_e2e_verify_tools "$cname" "$install_log" "$log_dir" \
    "fish" "fish --version 2>&1 | head -1" || { lxc stop "$cname" 2>/dev/null; trap - EXIT; return 1; }

  lxc stop "$cname" >/dev/null 2>&1 || true
  trap - EXIT
  echo "  [LXD E2E] $image: 安装成功"
  return 0
}

# 单镜像 LXD 完整 E2E：fish + zsh + uv + bun + fnm + go（仅限 Debian/Ubuntu 系，dnf 系可后续扩展）
lxd_e2e_with_tools_one() {
  local image="$1"
  local cname="dev-setup-e2e-lxd-tools-$$-${image//[^a-z0-9]/_}"
  local log_dir="${SCRIPT_DIR}/.e2e-logs"
  local install_log="${log_dir}/lxd-install-tools-$$-${image//[^a-z0-9]/_}.log"
  local repo_mount="/mnt/dev-setup-repo"
  mkdir -p "$log_dir"

  if ! lxc launch -e "$image" "$cname" >/dev/null 2>&1; then
    echo "  [LXD E2E tools] Failed to launch: $image"
    return 1
  fi
  trap "lxc stop $cname 2>/dev/null || true; trap - EXIT" EXIT

  lxc config device add "$cname" repo disk "source=${REPO_ROOT}" "path=${repo_mount}" 2>/dev/null || { lxc stop "$cname" 2>/dev/null; return 1; }

  local i
  for i in 1 2 3 4 5 6 7 8 9 10; do
    lxc exec "$cname" -- bash -c "command -v curl >/dev/null 2>&1 || true" 2>/dev/null && break
    sleep 1
  done
  # 安装 unzip/zsh 等（Ubuntu/Debian）：Ubuntu 需 universe（22.04 jammy / 24.04 noble 等由 VERSION_CODENAME 判定）
  if lxc exec "$cname" -- bash -c "command -v apt-get >/dev/null 2>&1"; then
    lxd_e2e_ubuntu_enable_universe "$cname"
    lxc exec "$cname" -- env DEBIAN_FRONTEND=noninteractive bash -c "apt-get update -qq && apt-get install -y -qq ca-certificates curl git fish unzip zsh >/dev/null" 2>/dev/null || true
  else
    lxc stop "$cname" 2>/dev/null; trap - EXIT; echo "  [LXD E2E tools] Only Debian/Ubuntu images supported for full tools test"; return 1
  fi
  lxc exec "$cname" -- bash -c 'n=0; while [ "$n" -lt 30 ]; do [ -f /var/lib/dpkg/lock-frontend ] 2>/dev/null && n=$((n+1)) && sleep 1 || break; done' 2>/dev/null || true
  sleep 2

  printf "  [LXD E2E tools] %s: Running install (log: %s)\n" "$image" "$install_log"
  if ! lxc exec "$cname" -- env DEBIAN_FRONTEND=noninteractive bash -c "cd ${repo_mount} && ./install.sh --shell fish --with-uv --with-go --with-bun --with-fnm --yes" >"$install_log" 2>&1; then
    echo "  [LXD E2E tools] $image: Install failed, see $install_log"
    lxc stop "$cname" 2>/dev/null; trap - EXIT; return 1
  fi

  lxc exec "$cname" -- bash -c 'export PATH="$HOME/.local/share/fnm:$PATH"; eval "$($HOME/.local/share/fnm/fnm env 2>/dev/null)"; fnm install --lts 2>/dev/null; fnm use lts-latest 2>/dev/null' >>"$install_log" 2>&1 || true

  if ! lxd_e2e_verify_tools "$cname" "$install_log" "$log_dir" \
    "fish" "fish --version 2>&1 | head -1" \
    "zsh" "zsh --version 2>&1" \
    "uv" '$HOME/.local/bin/uv --version 2>&1' \
    "bun" '$HOME/.bun/bin/bun --version 2>&1' \
    "optional:go" "go version 2>&1" \
    "fnm" '$HOME/.local/share/fnm/fnm --version 2>&1' \
    "node" 'export PATH="$HOME/.local/share/fnm:$PATH" && eval "$($HOME/.local/share/fnm/fnm env 2>/dev/null)" && node -v 2>&1'; then
    lxc stop "$cname" 2>/dev/null; trap - EXIT; return 1
  fi

  lxc stop "$cname" >/dev/null 2>&1 || true
  trap - EXIT
  echo "  [LXD E2E tools] $image: 安装与验证成功"
  return 0
}

test_lxd_e2e_minimal() {
  lxd_available || { echo "LXD not found or not usable (lxc + driver lxd), skip"; return 0; }
  lxd_arch_ok || { echo "LXD E2E skip: E2E_LXD_ARCH=${E2E_LXD_ARCH:-} requires amd64, host is $(uname -m)"; return 0; }
  local images
  images=$(lxd_e2e_image_list)
  [[ -z "$images" ]] && { echo "LXD E2E skip: E2E_LXD_DEB_UB=1 but no ubuntu/debian images"; return 0; }
  local failed=""
  for img in $images; do
    if ! lxd_e2e_minimal_one "$img"; then
      failed="$failed $img"
    fi
  done
  if [[ -n "$failed" ]]; then
    echo "  [LXD E2E] Failed images:$failed"
    return 1
  fi
  return 0
}

test_lxd_e2e_with_tools() {
  lxd_available || { echo "LXD not found or not usable, skip"; return 0; }
  lxd_arch_ok || { echo "LXD E2E tools skip: E2E_LXD_ARCH=${E2E_LXD_ARCH:-} requires amd64, host is $(uname -m)"; return 0; }
  local images
  images=$(lxd_e2e_image_list)
  [[ -z "$images" ]] && { echo "LXD E2E tools skip: E2E_LXD_DEB_UB=1 but no ubuntu/debian images"; return 0; }
  local failed=""
  for img in $images; do
    if ! lxd_e2e_with_tools_one "$img"; then
      failed="$failed $img"
    fi
  done
  if [[ -n "$failed" ]]; then
    echo "  [LXD E2E tools] Failed images:$failed"
    return 1
  fi
  return 0
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
  echo "E2E tests for dev-setup"
  echo "======================"
  run_test "Bash syntax (install.sh)" test_syntax
  run_test "install.sh --help exits 0" test_help_exit_zero
  run_test "Help contains Usage or 用法" test_help_contains_usage
  run_test "Help (English) content" test_help_english
  run_test "Help (Chinese) content" test_help_chinese
  run_test "Unknown option fails" test_unknown_option_fails
  run_test "Parse --shell fish" test_parse_shell_fish
  run_test "Parse --shell zsh" test_parse_shell_zsh
  run_test "Parse --container options" test_parse_container_options
  run_test "Invalid --container fails" test_invalid_container_fails
  echo "--- All option choices ---"
  run_test "Parse --lang en" test_parse_lang_en
  run_test "Parse --lang zh" test_parse_lang_zh
  run_test "Parse --with-docker" test_parse_with_docker
  run_test "Parse --with-podman" test_parse_with_podman
  run_test "Parse --with-ai" test_parse_with_ai
  run_test "Parse --with-python" test_parse_with_python
  run_test "Parse --with-shell-tools" test_parse_with_shell_tools
  run_test "Parse --with-uv" test_parse_with_uv
  run_test "Parse --with-bun" test_parse_with_bun
  run_test "Parse --with-fnm" test_parse_with_fnm
  run_test "Parse --with-go" test_parse_with_go
  run_test "Parse --yes" test_parse_yes_long
  run_test "Parse -y" test_parse_yes_short
  run_test "Parse --skip-modules" test_parse_skip_modules
  run_test "Parse all options combined" test_parse_all_options_combined

  if [[ "${E2E_LXD:-0}" == "1" ]] || [[ "${E2E_LXD_FULL:-0}" == "1" ]]; then
    run_test "LXD E2E minimal install (system container)" test_lxd_e2e_minimal
    if [[ "${E2E_LXD_FULL:-0}" == "1" ]]; then
      run_test "LXD E2E with tools (fish,zsh,uv,bun,go,fnm,node)" test_lxd_e2e_with_tools
    else
      echo "  (Skip LXD tools test; set E2E_LXD_FULL=1 to include)"
    fi
  fi

  if [[ "${E2E_DOCKER:-0}" == "1" ]] || [[ "${E2E_DOCKER_FULL:-0}" == "1" ]]; then
    run_test "Docker E2E minimal install" test_docker_e2e_minimal
    if [[ "${E2E_DOCKER_FULL:-0}" == "1" ]]; then
      run_test "Docker E2E with tools (fish,zsh,uv,bun,go,fnm,node)" test_docker_e2e_with_tools
    else
      echo "  (Skip heavy tools test; set E2E_DOCKER_FULL=1 to include)"
    fi
  fi
  if [[ "${E2E_LXD:-0}" != "1" && "${E2E_LXD_FULL:-0}" != "1" && "${E2E_DOCKER:-0}" != "1" && "${E2E_DOCKER_FULL:-0}" != "1" ]]; then
    echo ""
    echo "Optional: E2E_LXD=1 (LXD system container) | E2E_LXD_FULL=1 (+ tools)"
    echo "          E2E_DOCKER=1 (minimal container) | E2E_DOCKER_FULL=1 (+ tools verification)"
  fi

  echo ""
  if [[ $FAILED -eq 0 ]]; then
    echo "All tests passed."
    exit 0
  else
    echo "Some tests failed."
    exit 1
  fi
}

main "$@"
