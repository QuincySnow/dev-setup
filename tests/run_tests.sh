#!/usr/bin/env bash
# =============================================================================
# dev-setup 测试入口：轻量 CLI/解析 + 可选 bats + 可选 Docker
# =============================================================================
# 用法:
#   ./tests/run_tests.sh              # 仅快速测试（无 Docker）
#   ./tests/run_tests.sh && E2E_DOCKER=1 ./tests/e2e.sh   # 含最小容器
#   E2E_DOCKER_FULL=1 ./tests/run_tests.sh               # 含完整容器
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
FAILED=0

run() {
  if "$@"; then
    return 0
  else
    FAILED=1
    return 1
  fi
}

echo "=============================================="
echo "  Layer 1: Quick tests (e2e.sh, no Docker)"
echo "=============================================="
# 启用 LXD E2E 时在 lxd 组下运行，避免 socket permission denied（效果等同先 newgrp lxd 再测）
# 用 getent group lxd 判断用户是否在 lxd 组（不依赖当前进程是否已 newgrp），并保证 /snap/bin 在 PATH 以便找到 lxc
run_e2e() {
  if [[ "${E2E_LXD:-0}" == "1" ]] || [[ "${E2E_LXD_FULL:-0}" == "1" ]]; then
    if getent group lxd 2>/dev/null | grep -qE "\b${USER}\b"; then
      # sg 子 shell 可能 PATH 很精简，显式加入常见 lxc 路径（snap / apt）
      sg lxd -c 'export PATH="/snap/bin:/usr/local/bin:/usr/bin:/bin:$PATH"; export E2E_LXD="'"${E2E_LXD:-0}"'"; export E2E_LXD_FULL="'"${E2E_LXD_FULL:-0}"'"; export E2E_LXD_IMAGES="'"${E2E_LXD_IMAGES:-}"'"; export E2E_LXD_ARCH="'"${E2E_LXD_ARCH:-}"'"; export E2E_LXD_DEB_UB="'"${E2E_LXD_DEB_UB:-0}"'"; export E2E_DOCKER="'"${E2E_DOCKER:-0}"'"; export E2E_DOCKER_FULL="'"${E2E_DOCKER_FULL:-0}"'"; "'"${SCRIPT_DIR}"'/e2e.sh"'
    else
      "${SCRIPT_DIR}/e2e.sh"
    fi
  else
    "${SCRIPT_DIR}/e2e.sh"
  fi
}
run run_e2e || true

echo ""
echo "=============================================="
echo "  Layer 2: Bats (if installed)"
echo "=============================================="
if command -v bats >/dev/null 2>&1; then
  if [[ -d "${SCRIPT_DIR}/bats" ]]; then
    run bats "${SCRIPT_DIR}/bats" || true
  else
    echo "  (tests/bats/ not found, skip)"
  fi
else
  echo "  (bats not found; install: npm i -g bats, or apt install bats)"
fi

if [[ "${E2E_LXD:-0}" == "1" ]] || [[ "${E2E_LXD_FULL:-0}" == "1" ]]; then
  echo ""
  echo "=============================================="
  echo "  Layer 3: LXD E2E (already run in e2e.sh)"
  echo "=============================================="
  echo "  (LXD system-container tests were executed above in Layer 1)"
fi
if [[ "${E2E_DOCKER:-0}" == "1" ]] || [[ "${E2E_DOCKER_FULL:-0}" == "1" ]]; then
  echo ""
  echo "=============================================="
  echo "  Layer 3: Docker E2E (already run in e2e.sh)"
  echo "=============================================="
  echo "  (Docker tests were executed above in Layer 1)"
fi

echo ""
if [[ $FAILED -eq 0 ]]; then
  echo "All test layers passed."
  exit 0
else
  echo "One or more test layers failed."
  exit 1
fi
