#!/usr/bin/env bats
# -----------------------------------------------------------------------------
# Bats: install.sh CLI (help, exit codes, parse). No Docker.
# Run from repo root: bats tests/bats/install_cli.bats
# -----------------------------------------------------------------------------

setup() {
  SCRIPT_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
  REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
  INSTALL_SH="${REPO_ROOT}/install.sh"
}

@test "install.sh exists and is executable" {
  [[ -f "$INSTALL_SH" ]]
  [[ -x "$INSTALL_SH" ]]
}

@test "install.sh --help exits 0" {
  run "$INSTALL_SH" --help
  [[ $status -eq 0 ]]
}

@test "install.sh --help contains Usage or 用法" {
  run "$INSTALL_SH" --help
  [[ $output =~ (Usage:|用法:) ]]
}

@test "install.sh --help (en) contains Development Environment Setup" {
  run "$INSTALL_SH" --help
  [[ $output == *"Development Environment Setup"* ]]
  [[ $output == *"--shell"* ]]
  [[ $output == *"--help"* ]]
}

@test "install.sh --lang zh --help contains 开发环境" {
  run "$INSTALL_SH" --lang zh --help
  [[ $output == *"开发环境"* ]]
  [[ $output == *"用法:"* ]]
}

@test "install.sh unknown option exits non-zero" {
  run "$INSTALL_SH" --unknown-option 2>&1 || true
  [[ $status -ne 0 ]]
  [[ $output =~ [Uu]nknown ]]
}

@test "install.sh --shell fish --help exits 0" {
  run "$INSTALL_SH" --shell fish --help
  [[ $status -eq 0 ]]
}

@test "install.sh --shell zsh --help exits 0" {
  run "$INSTALL_SH" --shell zsh --help
  [[ $status -eq 0 ]]
}

@test "install.sh --container docker --help exits 0" {
  run "$INSTALL_SH" --container docker --help
  [[ $status -eq 0 ]]
}

@test "install.sh --container invalid fails" {
  run "$INSTALL_SH" --container invalid 2>&1 || true
  [[ $status -ne 0 ]]
  [[ $output =~ [Ii]nvalid ]]
}

@test "install.sh --with-bun --with-fnm --yes --help exits 0" {
  run "$INSTALL_SH" --with-bun --with-fnm --yes --help
  [[ $status -eq 0 ]]
}

@test "install.sh parse all options combined exits 0" {
  run "$INSTALL_SH" --shell fish --lang en --container both \
    --with-docker --with-podman --with-ai --with-python \
    --with-shell-tools --with-uv --with-bun --with-fnm --with-go \
    --yes --skip-modules --help
  [[ $status -eq 0 ]]
}
