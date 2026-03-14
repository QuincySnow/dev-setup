#!/usr/bin/env bats
# -----------------------------------------------------------------------------
# Bats: lib/core.sh ask_confirmation (YES_MODE). No Docker.
# Run from repo root: bats tests/bats/core_ask_confirmation.bats
# -----------------------------------------------------------------------------

setup() {
  SCRIPT_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
  REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
  LIB_DIR="${REPO_ROOT}/lib"
}

_run_ask() {
  local default="$1"
  bash -c "source '${LIB_DIR}/core.sh'; ask_confirmation 'Install?' '${default}'"
}

@test "ask_confirmation with YES_MODE=1 and default n returns 1" {
  YES_MODE=1 run _run_ask n
  [[ $status -eq 1 ]]
}

@test "ask_confirmation with YES_MODE=1 and default y returns 0" {
  YES_MODE=1 run _run_ask y
  [[ $status -eq 0 ]]
}

@test "ask_confirmation with YES_MODE=true and default n returns 1" {
  YES_MODE=true run _run_ask n
  [[ $status -eq 1 ]]
}

@test "ask_confirmation with YES_MODE=true and default y returns 0" {
  YES_MODE=true run _run_ask y
  [[ $status -eq 0 ]]
}
