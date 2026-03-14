---
name: dev-setup-tests
description: Run and troubleshoot dev-setup test layers (Layer 1 e2e.sh, Layer 2 Bats, Layer 3 LXD/Docker E2E). Use when running tests, only Bats and LXD, or when LXD E2E is skipped with "lxc + driver lxd" or permission denied.
---

# dev-setup 测试

## 入口

统一入口（仓库根目录执行）：

```bash
./tests/run_tests.sh
```

可选环境变量控制是否跑 LXD/Docker E2E；不设则只跑 Layer 1（及 Layer 2 若已装 bats）。

## 只跑 Bats + LXD（不跑 Docker）

```bash
E2E_LXD=1 ./tests/run_tests.sh
```

- Layer 1（e2e.sh 快速测试）仍会执行。
- Layer 2：需已安装 `bats`（`npm i -g bats` 或 `apt install bats`）。
- Layer 3：只跑 LXD E2E，不跑 Docker。

## LXD 权限：自动 `sg lxd`

设置 `E2E_LXD=1` 或 `E2E_LXD_FULL=1` 时，`run_tests.sh` 会**在 lxd 组下执行** e2e（`sg lxd`），效果等同先 `newgrp lxd` 再测，**无需手动先运行 `newgrp lxd`**。前提是用户已加入 lxd 组（`sudo usermod -aG lxd $USER` 后至少重新登录一次）。

## 若 LXD 被跳过："LXD not found or not usable (lxc + driver lxd), skip"

脚本通过 `lxc` 客户端且 `lxc info` 含 `driver: lxd` 判断 LXD 可用。跳过常见原因与处理：

1. **`lxc` 不在 PATH**：`export PATH="/snap/bin:$PATH"` 或在 `~/.zshrc` 中加入后重载。
2. **当前用户不在 `lxd` 组**：`sudo usermod -aG lxd $USER` 后**重新登录**或新开终端，之后由脚本自动用 `sg lxd` 运行。
3. **在能执行 `lxc list` 的终端里跑测试**：IDE 终端需保证 PATH 含 `/snap/bin`。

## 若 "Failed to launch container: ubuntu:22.04"

多为 default profile 无 root 磁盘（`lxc profile show default` 显示 `devices: {}`）。修复：`lxc storage list` → 若无池则 `lxc storage create default dir` → `lxc profile device add default root disk path=/ pool=default`。再试 `lxc launch ubuntu:22.04 test`。详见 `tests/README.md`。

## 环境变量速查

| 变量 | 作用 |
|------|------|
| `E2E_LXD=1` | 跑 LXD 最小 E2E（默认 ubuntu:22.04） |
| `E2E_LXD_FULL=1` | 再跑 LXD 多工具 E2E |
| `E2E_LXD_IMAGES` | 多镜像，如 `ubuntu:22.04 debian:12` |
| `E2E_LXD_ARCH=amd64` | 仅 amd64 主机跑 LXD E2E，非 x86_64 则跳过 |
| `E2E_LXD_DEB_UB=1` | 只测 Debian/Ubuntu 镜像（默认 ubuntu:22.04 debian:12） |
| `E2E_DOCKER=1` | 跑 Docker 最小 E2E |
| `E2E_DOCKER_FULL=1` | 跑 Docker 多工具 E2E |

详见 `tests/README.md`。
