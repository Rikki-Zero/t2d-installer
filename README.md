# T2D 安装器

这是一个用于自动化安装和管理 [T2D](https://github.com/Neet-NXO/T2D) 服务的脚本集合。T2D 是一个高性能的UDP over TCP隧道工具，适用于各种网络环境。

## 🚀 功能特性

- **一键安装**：自动化下载最新版本的T2D二进制文件并安装到系统。
- **跨平台支持**：自动检测Linux发行版（CentOS, Debian, Ubuntu）和系统架构，下载对应版本。
- **服务管理**：
  - **Systemd 集成**：自动配置 `t2d@.service` systemd 模板服务，方便管理多个T2D实例（推荐现代Linux系统）。
  - **Init.d 集成**：自动配置 `/etc/init.d/t2d` 服务，支持传统init系统（适用于旧版Linux或无systemd环境）。
- **配置模板**：自动创建客户端和服务器的配置示例文件，方便用户快速上手。
- **Bash 自动补全**：为 `systemctl start t2d@` 等命令提供自动补全功能（仅Systemd模式）。
- **一键反安装**：提供脚本，轻松移除所有安装器部署的文件和配置。

## 📋 前提条件

- 支持的操作系统：CentOS, Debian, Ubuntu
- 需要 `root` 权限来运行安装和反安装脚本。
- 系统需安装 `curl`, `jq`, `tar`。
  - Systemd模式还需要 `systemd`, `bash-completion`。
  - Init.d模式不需要 `systemd` 或 `bash-completion`。

## 📥 安装

### Systemd 模式 (推荐)

适用于大多数现代Linux发行版（如Ubuntu 16.04+, Debian 8+, CentOS 7+）。

```bash
curl -fsSL https://raw.githubusercontent.com/Rikka-Sei/t2d-installer/refs/heads/Stable/install.sh | sudo bash
```

### Init.d 模式

适用于较旧的Linux发行版或没有Systemd的环境。

```bash
curl -fsSL https://raw.githubusercontent.com/Rikka-Sei/t2d-installer/refs/heads/Stable/initd-install.sh | sudo bash
```

## 🗑️ 卸载

### Systemd 模式 (对应Systemd安装)

```bash
curl -fsSL https://raw.githubusercontent.com/Rikka-Sei/t2d-installer/refs/heads/Stable/uninstall.sh | sudo bash
```

### Init.d 模式 (对应Init.d安装)

```bash
curl -fsSL https://raw.githubusercontent.com/Rikka-Sei/t2d-installer/refs/heads/Stable/initd-uninstall.sh | sudo bash
```

## ⚙️ 配置

安装完成后，您可以在 `/etc/t2d/` 目录下找到 `client.example` 和 `server.example` 模板文件。您可以复制这些文件并根据您的需求进行修改。

例如，创建一个客户端配置文件：

```bash
sudo cp /etc/t2d/client.example /etc/t2d/my-client.json
sudo nano /etc/t2d/my-client.json
```

### Systemd 模式服务管理示例

修改完成后，您可以通过systemd启动T2D服务：

```bash
sudo systemctl start t2d@my-client
sudo systemctl enable t2d@my-client # 设置开机自启
```

查看服务状态：

```bash
sudo systemctl status t2d@my-client
```

### Init.d 模式服务管理示例

修改完成后，您可以通过init.d启动T2D服务：

```bash
sudo /etc/init.d/t2d t2d start my-client
```

查看服务状态：

```bash
sudo /etc/init.d/t2d t2d status my-client
```

## 💡 Bash 自动补全 (仅Systemd模式)

Systemd安装脚本会自动设置bash补全。在安装完成后，重新登录您的shell，或手动运行 `source /etc/bash_completion.d/t2d` 来启用补全功能。

之后，当您输入 `systemctl start t2d@` 并按下 `Tab` 键时，系统会自动补全 `/etc/t2d/` 目录下的 `.json` 配置文件名，例如 `t2d@my-client.service`。

## 📄 许可证

本项目采用 [AGPL-3.0 license](LICENSE) 许可证。 