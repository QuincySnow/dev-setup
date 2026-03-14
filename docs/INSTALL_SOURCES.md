# 安装来源参考（与官方/网络文档同步）

本文档记录 Fish、Zsh、Go、uv、Bun、FNM 等工具的**官方或常用安装方式**，便于定期对照更新、防止脚本过时。实现见 `install.sh`、`lib/shell_setup.sh`、`lib/modules/python.sh`。

---

## Fish Shell

- **Ubuntu/Debian**：`sudo apt update && sudo apt install fish`（仓库版较旧，约 3.3.x）。
- **较新版本**：`sudo add-apt-repository ppa:fish-shell/release-3` 或 `release-4`（见 [fish-shell/fish-shell](https://github.com/fish-shell/fish-shell)），然后 `apt update && apt install fish`。最小镜像常无 `add-apt-repository`，脚本用手动启用 universe + apt install。
- **验证**：`fish -v`。

---

## Zsh

- **Ubuntu/Debian**：`sudo apt update && sudo apt install zsh -y`。
- **验证**：`zsh --version`。

---

## uv（Python 包管理器）

- **官方推荐**：`curl -LsSf https://astral.sh/uv/install.sh | sh`（[Astral 文档](https://docs.astral.sh/uv/)）。
- 安装后路径：`~/.local/bin/uv`，需加入 PATH。
- **验证**：`uv --version`。

---

## Bun（JavaScript 运行时）

- **官方**：`curl -fsSL https://bun.sh/install | bash`（[Bun 安装文档](https://bun.sh/docs/installation)）。
- 安装路径：`~/.bun/bin`；需 `BUN_INSTALL="$HOME/.bun"` 与 `PATH="$BUN_INSTALL/bin:$PATH"`。
- **前置**：需已安装 `unzip`（Debian/Ubuntu：`apt install unzip`）。
- **验证**：`bun --version`。

---

## FNM（Node 版本管理）

- **官方**：`curl -fsSL https://fnm.vercel.app/install | bash`（[fnm](https://fnm.vercel.app/)）。
- 可选：`--install-dir $HOME/.local/share/fnm`、`--skip-shell`。
- Linux 默认安装目录：`$HOME/.local/share/fnm`。使用前需 `eval "$(fnm env)"`。
- **验证**：`fnm --version`；安装 Node 后 `fnm install --lts`、`node -v`。

---

## Go（Golang）

- **官方二进制**：[go.dev/dl](https://go.dev/dl/) 下载 `goX.Y.Z.linux-amd64.tar.gz`，然后：
  - `sudo rm -rf /usr/local/go`
  - `sudo tar -C /usr/local -xzf goX.Y.Z.linux-amd64.tar.gz`
  - 将 `/usr/local/go/bin` 加入 PATH（如 `export PATH=$PATH:/usr/local/go/bin`）。
- **包管理器**：Ubuntu/Debian `apt install golang-go`；Fedora `dnf install golang`（版本可能较旧）。
- 本脚本在无包管理器时的 fallback 使用 **GO_VERSION**（默认 1.22.4，可在调用前 `export GO_VERSION=1.23.x` 覆盖），以保持可复现；最新稳定版见 [go.dev/dl](https://go.dev/dl/)。
- **验证**：`go version`。

---

## 更新建议

- 定期（如每季度）对照上述官方文档或本文档中的链接，检查安装 URL、PPA、版本号是否仍有效。
- 若某工具安装失败，优先核对其官网/仓库的安装说明是否已变更。
