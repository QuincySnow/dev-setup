# E2E Tests for dev-setup

End-to-end tests for the `install.sh` script.

## Quick run

From the repo root:

```bash
./tests/e2e.sh
```

## Use Docker for testing

To run the **Docker E2E** test (full install inside an Ubuntu container):

```bash
E2E_DOCKER=1 ./tests/e2e.sh
```

**Requirements:**

- Docker installed and running
- Current user in the `docker` group (or run with `sudo`)

If Docker is not available or you get "permission denied", the test is **skipped** and the suite still passes.

**Linux – add user to docker group:**

```bash
sudo usermod -aG docker $USER
# Then log out and back in (or newgrp docker)
```

After that, run again:

```bash
E2E_DOCKER=1 ./tests/e2e.sh
```

**失败时的详细报告：**

当容器内安装失败时，测试会：

- 在终端打印 **「Docker E2E 失败 - 详细报告」**，包含：
  - 容器名、**安装日志**与**诊断日志**路径
  - **安装脚本完整 stdout/stderr**（逐行带 `  | ` 前缀）
  - **诊断块**：容器内执行的 `apt-get update`、`apt-get install -y fish`（完整输出，无 -qq）、`apt-cache policy fish`、`dpkg -l fish`、`/etc/os-release`、`/tmp` 等，便于根据真实 apt/系统错误修复
  - **复现命令**：可直接复制到终端在同等环境下调试
- 将安装输出写入 `tests/.e2e-logs/docker-install-<pid>.log`，诊断输出写入 `tests/.e2e-logs/docker-diagnostic-<pid>.log`，便于事后查看

## What is tested

- **Bash syntax**: `bash -n install.sh`
- **Help output**: `./install.sh --help` exits 0 and contains expected strings
- **English help**: Contains "Development Environment Setup", "--shell", "--help"
- **Chinese help**: `./install.sh --lang zh --help` contains "开发环境", "用法:", "--shell"
- **Unknown option**: `./install.sh --unknown-option` fails and prints "Unknown option"
- **Argument parsing**: `--shell fish`, `--shell zsh`, `--container docker|podman|both` parse correctly
- **Invalid container**: `./install.sh --container invalid` fails with an error message
- **All option choices** (each must parse with `--help`):
  - `--lang en`, `--lang zh`
  - `--with-docker`, `--with-podman`, `--with-ai`, `--with-python`, `--with-shell-tools`
  - `--with-uv`, `--with-bun`, `--with-fnm`, `--with-go`
  - `--yes`, `-y`, `--skip-modules`
  - **Combined**: all options together
- **Docker E2E** (when `E2E_DOCKER=1`): Minimal install in container, then verify `fish` works
