# dev-setup 测试说明

**完整测试套件已全部跑通，无错误。** 测试分三层，按需运行以平衡速度与覆盖率。

## 层级概览

| 层级 | 内容 | 耗时 | 依赖 |
|------|------|------|------|
| **Layer 1** | 语法、`--help`、选项解析（无容器） | 秒级 | 无 |
| **Layer 2** | Bats 用例（CLI + lib 逻辑） | 秒级 | bats |
| **Layer 3** | LXD 系统容器 / Docker 容器内真实安装 | 分钟级 | LXD 或 Docker |

**LXD（系统容器）** 更接近真实系统（完整 OS、systemd、包管理器），适合验证各发行版兼容性；**Docker** 启动快、CI 常用。二者可选其一或同时使用。

## 常用命令

```bash
# 仅快速测试（推荐日常/CI）
./tests/run_tests.sh

# 或直接跑 e2e（等同 Layer 1）
./tests/e2e.sh

# ---------- LXD 系统容器 E2E（最大程度模拟系统，推荐验证兼容性）----------
# 仅 Linux 可用；需先安装 LXD：sudo snap install lxd && lxd init
# 最小安装（默认镜像 ubuntu:22.04）
E2E_LXD=1 ./tests/run_tests.sh

# 多发行版兼容性：在多个镜像上各跑一遍最小安装
E2E_LXD=1 E2E_LXD_IMAGES="ubuntu:22.04 debian:12" ./tests/run_tests.sh

# 完整安装（fish/zsh/uv/bun/fnm/node 等，仅支持 Debian/Ubuntu 系镜像）
E2E_LXD_FULL=1 ./tests/run_tests.sh

# 只跑 Bats + LXD（不跑 Docker）
E2E_LXD=1 ./tests/run_tests.sh

# 仅 amd64 架构跑 LXD E2E（非 x86_64 主机会跳过 LXD）
E2E_LXD=1 E2E_LXD_ARCH=amd64 ./tests/run_tests.sh

# 只测 Debian 与 Ubuntu 镜像（默认 ubuntu:22.04 debian:12）
E2E_LXD=1 E2E_LXD_DEB_UB=1 ./tests/run_tests.sh

# ---------- Docker E2E（可选）----------
# 含「最小」容器测试（单容器，仅 fish）
E2E_DOCKER=1 ./tests/run_tests.sh

# 含「完整」容器测试（最小 + 多工具安装与验证）
E2E_DOCKER_FULL=1 ./tests/run_tests.sh
```

## 安装 Bats（可选，用于 Layer 2）

- **npm**：`npm install -g bats`
- **Ubuntu**：`sudo apt install bats`（仓库版可能较旧）
- **最新版**：`git clone https://github.com/bats-core/bats-core.git && cd bats-core && ./install.sh /usr/local`

未安装 bats 时，`run_tests.sh` 会跳过 Layer 2 并提示。

## LXD 安装与各系统兼容性

- **LXD 仅支持 Linux**（宿主机）。常见安装方式：
  - **Snap（推荐）**：`sudo snap install lxd`，然后 `lxd init`（Ubuntu / Debian / Fedora / Arch 等均可）。
  - **Debian/Ubuntu**：`sudo apt install lxd`（或 snap）。
  - **Fedora**：`sudo dnf install lxd` 或通过 snap。
- **确保兼容性**：用 **E2E_LXD_IMAGES** 在多个发行版镜像上跑同一套脚本，例如：
  - `E2E_LXD_IMAGES="ubuntu:22.04 debian:12"` 验证 Debian 系；
  - 若需 Fedora 系，可加 `fedora:39`（需宿主机已拉取对应镜像：`lxc image list images:`）。
- 未安装或不可用 LXD 时，LXD E2E 会被跳过并提示。

### LXD 权限与自动 `sg lxd`

当设置 `E2E_LXD=1` 或 `E2E_LXD_FULL=1` 时，`run_tests.sh` 会**自动在 lxd 组下执行** e2e（通过 `sg lxd`），效果等同先执行 `newgrp lxd` 再跑测试，因此**无需手动先运行 `newgrp lxd`**。前提是当前用户已加入 `lxd` 组（`sudo usermod -aG lxd $USER` 后至少重新登录一次）。

### 若出现 "LXD not found or not usable (lxc + driver lxd), skip"

脚本通过 `lxc` 客户端且 `lxc info` 输出含 `driver: lxd` 判断 LXD 可用。若仍被跳过，请检查：

1. **`lxc` 是否在 PATH**：Snap 安装时客户端通常在 `/snap/bin`，执行 `export PATH="/snap/bin:$PATH"` 或在 `~/.zshrc` / `~/.bashrc` 中加入后重载。
2. **当前用户是否在 `lxd` 组**：`sudo usermod -aG lxd $USER` 后需**重新登录**一次（或新开终端），之后 `run_tests.sh` 会用 `sg lxd` 自动带 lxd 组运行。
3. **在能执行 `lxc list` 的终端里跑测试**：IDE 内置终端若未继承 PATH，请确保 PATH 含 `/snap/bin`。

### 若出现 "Failed to launch container: ubuntu:22.04"

脚本会打印 LXD 的原始错误。常见原因与处理：

- **No root device / 默认 profile 无根磁盘**：运行 `lxc profile show default`，若看到 `devices: {}` 说明没有 root 磁盘，需先配好再 launch：
  1. 查看存储池：`lxc storage list`
  2. 若没有任何池，创建默认 dir 池：`lxc storage create default dir`
  3. 为 default profile 添加 root 设备：`lxc profile device add default root disk path=/ pool=default`
  4. 验证：`lxc launch ubuntu:22.04 test`（若提示 "already exists" 表示同名容器已存在，可 `lxc delete test` 后重试或换名）
- **镜像拉取失败 / 网络**：确认能访问镜像站：`lxc image list ubuntu:`，必要时配置代理或换网络。
- **remote 未配置**：运行 `lxc remote list`，确认有 `ubuntu`。若无则按 LXD 文档添加官方 ubuntu 镜像 remote。

## 工具安装来源参考

Fish、Zsh、Go、uv、Bun、FNM 等安装命令与官方/网络文档的对照见 **`docs/INSTALL_SOURCES.md`**，便于定期核对防止过时。

## Debian/Ubuntu 安装流程说明（与实现同步）

- **Ubuntu**：在容器内启用 universe 时按 **VERSION_CODENAME**（如 jammy / noble）写入，不硬编码版本；24.04 (noble) 默认使用 `ubuntu.sources` (deb822) 且已含 universe，脚本会检测后跳过重复添加。最小镜像通常无 `add-apt-repository`，故用手动写入 `sources.list` 的方式。
- **Debian**：无 universe 概念，直接 `apt-get update && apt-get install`；仓库密钥使用当前推荐方式（signed-by 等由系统镜像提供）。
- 所有 apt 操作均使用 **DEBIAN_FRONTEND=noninteractive** 以支持非交互式运行。

## 目录结构

```
tests/
├── e2e.sh           # 快速测试 + 可选 Docker E2E
├── run_tests.sh     # 统一入口：Layer 1 + Layer 2 + 提示 Layer 3
├── bats/            # Bats 用例（需安装 bats）
│   ├── install_cli.bats
│   └── core_ask_confirmation.bats
├── .e2e-logs/       # Docker E2E 日志（自动生成）
└── README.md        # 本文件
```

## 环境变量

**LXD E2E（仅 Linux，最大程度模拟真实系统）**

- **E2E_LXD=1**：在 LXD 系统容器内跑最小 E2E（默认镜像 `ubuntu:22.04`）。
- **E2E_LXD_FULL=1**：再跑「多工具」E2E（fish/zsh/uv/bun/fnm/node，仅 Debian/Ubuntu 系镜像）。
- **E2E_LXD_IMAGES**：空格分隔的镜像列表，用于多发行版兼容性。例如：`E2E_LXD_IMAGES="ubuntu:22.04 debian:12"`。未设时默认 `ubuntu:22.04`。
- **E2E_LXD_ARCH=amd64**：仅在本机为 x86_64（amd64）时运行 LXD E2E；非 amd64 主机则跳过 LXD 测试。
- **E2E_LXD_DEB_UB=1**：只测 Debian 与 Ubuntu 镜像。未设 `E2E_LXD_IMAGES` 时用 `ubuntu:22.04 debian:12`；已设则从列表中只保留 `ubuntu:*` 与 `debian:*`。

**Docker E2E**

- **E2E_DOCKER=1**：运行 Docker 最小 E2E（单容器，fish 安装与验证）。
- **E2E_DOCKER_FULL=1**：在 E2E_DOCKER 基础上再跑「多工具」容器测试（uv/bun/fnm/node 等）。

默认不设时只跑 Layer 1（及 Layer 2，若已装 bats），不启动任何容器。LXD 与 Docker 可同时开启（先跑 LXD 再跑 Docker）。
