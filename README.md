# dev-setup

> 一键搭建开发环境：macOS/Linux 自动化配置脚本

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey)](https://github.com/SKIPPINGpetticoatconvent/dev-setup)
[![Shell](https://img.shields.io/badge/shell-Fish%20%7C%20Zsh-blue)](https://github.com/SKIPPINGpetticoatconvent/dev-setup)

[English](./README.md) | [中文](./README.zh.md)

---

## 简介

`dev-setup` 是一个一键脚本，帮助你在 macOS 或 Linux 上快速搭建完整的开发环境。

### 特性

- 🚀 **一键安装**：运行 `./install.sh` 即可完成所有配置
- 🖥️ **跨平台**：支持 macOS (Homebrew) 和 Linux (apt)
- 🐟/🦔 **多 Shell 支持**：可选 Fish Shell 或 Zsh
- 📦 **可选模块**：Docker、AI 工具、Python 工具链
- 🔒 **安全**：自动备份旧配置，检查依赖
- 🎨 **开箱即用**：预配置的 dotfiles，基于 [我的博客](https://skippingpetticoatconvent.github.io/) 主题

---

## 快速开始

### 交互式安装

```bash
git clone https://github.com/SKIPPINGpetticoatconvent/dev-setup.git
cd dev-setup
./install.sh
```

### 指定 Shell 安装

```bash
# 安装 Fish Shell
./install.sh --shell fish

# 安装 Zsh
./install.sh --shell zsh
```

### 带模块安装

```bash
# 安装 Fish + Docker + AI
./install.sh --shell fish --with-docker --with-ai

# 安装 Zsh + Python 工具
./install.sh --shell zsh --with-python
```

### 非交互式安装

```bash
./install.sh --shell fish --with-docker --with-ai --with-python --yes
```

### 一行命令安装

```bash
curl -sSL https://raw.githubusercontent.com/SKIPPINGpetticoatconvent/dev-setup/main/install.sh | bash
```

---

## 使用说明

### 命令行选项

| 选项 | 说明 |
|------|------|
| `--shell {fish\|zsh}` | 选择 Shell（默认：交互式选择）|
| `--with-docker` | 安装 Docker |
| `--with-ai` | 安装 AI 工具 (Ollama) |
| `--with-python` | 安装 Python 工具 (uv, pipx) |
| `--yes, -y` | 跳过所有确认 |
| `--skip-modules` | 跳过可选模块 |
| `--help` | 显示帮助 |

### 安装流程

1. **检测 OS**：自动识别 macOS 或 Linux
2. **安装核心工具**：git, curl, wget, unzip
3. **安装 Shell**：Fish (推荐) 或 Zsh
4. **安装效率工具**：starship, fzf, tmux
5. **安装可选模块**：Docker, AI, Python
6. **配置 Dotfiles**：自动链接配置文件

---

## 已安装工具

### Shell & 终端

- **Fish Shell** - 现代 Shell，开箱即用
- **Zsh** - 强大的可扩展 Shell
- **Oh My Zsh** - Zsh 框架（选择 Zsh 时）
- **Fisher** - Fish 插件管理器
- **Starship** - 跨 Shell 提示符
- **fzf** - 模糊搜索
- **tmux** - 终端复用器

### 开发工具

- **Git** - 版本控制
- **Neovim** - 现代文本编辑器
- **Bat** - 带语法高亮的 cat 替代品
- **Eza/Exa** - 现代 ls 替代品
- **Ripgrep** - 高性能搜索
- **FD** - 现代 find 替代品
- **HTop** - 系统监控

### 可选模块

#### Docker

- Docker Engine
- Docker Compose
- 免 sudo 配置

#### AI 工具

- Ollama - 本地 LLM 运行
- 可选：Open WebUI

#### Python 工具

- uv - 极速包管理器
- pipx - CLI 工具管理
- Rye - Python 版本管理（可选）

---

## Dotfiles 结构

```
dotfiles/
├── fish/
│   ├── config.fish          # Fish 主配置
│   └── functions/          # 自定义函数
├── zsh/
│   ├── .zshrc              # Zsh 主配置
│   └── .p10k.zsh           # Powerlevel10k
├── starship.toml           # Starship 配置
├── fzf/                    # fzf 快捷键
├── tmux.conf               # tmux 配置
├── gitconfig               # Git 配置
└── vimrc                   # Vim 配置
```

---

## 截图

> 截图占位符（安装完成后欢迎贡献截图）

---

## 配置

### 修改 Git 配置

安装完成后，编辑 `~/.gitconfig` 填入你的信息：

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### 自定义 Shell 插件

**Fish**：编辑 `~/.config/fish/config.fish`

**Zsh**：编辑 `~/.zshrc`，修改 plugins 数组

---

## 故障排除

### Homebrew 未安装

```bash
# macOS
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Linux
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Docker 权限问题

```bash
sudo usermod -aG docker $USER
# 重新登录使更改生效
```

### Starship 主题问题

```bash
# 重新初始化
starship preset gruvbox-rainbow > ~/.config/starship.toml
```

---

## 相关博客

本脚本的安装步骤与本站以下博客文章一致，更多细节与故障排查请直接参考对应文章：

🔗 **[Skipping Petticoat Convent](https://skippingpetticoatconvent.github.io/)**

- [Zsh 终极配置指南](https://skippingpetticoatconvent.github.io/blog/2025-03-01-zsh/)
- [Fish Shell 终极配置指南](https://skippingpetticoatconvent.github.io/blog/2026-02-12-fish-shell-guide/)
- [迁移到 uv](https://skippingpetticoatconvent.github.io/blog/2026-02-12-migrate-to-uv/)
- [Debian/Ubuntu 安装 Docker](https://skippingpetticoatconvent.github.io/blog/2026-02-15-De_and_Ub_install_Docker/)

---

## 贡献

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add amazing feature'`)
4. 推送分支 (`git push origin feature/amazing-feature`)
5. 打开 Pull Request

---

## 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](./LICENSE) 文件

---

## 致谢

- [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh)
- [Fisher](https://github.com/jorgebucaran/fisher)
- [Starship](https://github.com/starship/starship)
- [FZF](https://github.com/junegunn/fzf)

---

<p align="center">
  Made with ❤️ by <a href="https://github.com/SKIPPINGpetticoatconvent">SKIPPINGpetticoatconvent</a>
</p>
test
