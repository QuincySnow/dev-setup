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
run "${SCRIPT_DIR}/e2e.sh" || true

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
