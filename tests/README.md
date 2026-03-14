# dev-setup 测试说明

测试分三层，按需运行以平衡速度与覆盖率。

## 层级概览

| 层级 | 内容 | 耗时 | 依赖 |
|------|------|------|------|
| **Layer 1** | 语法、`--help`、选项解析（无 Docker） | 秒级 | 无 |
| **Layer 2** | Bats 用例（CLI + lib 逻辑） | 秒级 | bats |
| **Layer 3** | Docker 容器内真实安装 | 分钟级 | Docker |

## 常用命令

```bash
# 仅快速测试（推荐日常/CI）
./tests/run_tests.sh

# 或直接跑 e2e（等同 Layer 1）
./tests/e2e.sh

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

- **E2E_DOCKER=1**：运行 Docker 最小 E2E（单容器，fish 安装与验证）。
- **E2E_DOCKER_FULL=1**：在 E2E_DOCKER 基础上再跑「多工具」容器测试（uv/bun/fnm/node 等）。

默认不设时只跑 Layer 1（及 Layer 2，若已装 bats），不启动任何容器。
