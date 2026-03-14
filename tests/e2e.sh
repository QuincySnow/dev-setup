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
    ubuntu:22.04 bash -c "grep -q universe /etc/apt/sources.list 2>/dev/null || echo 'deb http://archive.ubuntu.com/ubuntu/ jammy universe' >> /etc/apt/sources.list; DEBIAN_FRONTEND=noninteractive apt-get update -qq && apt-get install -y -qq curl ca-certificates git fish >/dev/null && sleep 3600" >/dev/null 2>&1; then
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

  docker stop "$container_name" >/dev/null 2>&1 || true
  trap - EXIT
  echo "  [Docker E2E] 安装成功，日志已保存: $install_log"
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

  if [[ "${E2E_DOCKER:-0}" == "1" ]]; then
    run_test "Docker E2E minimal install" test_docker_e2e_minimal
  else
    echo ""
    echo "Optional: set E2E_DOCKER=1 to run Docker E2E test"
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
