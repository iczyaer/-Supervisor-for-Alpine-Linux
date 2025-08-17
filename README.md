# Supervisor 一键安装脚本 (Alpine Linux)

这是一个为 **Alpine Linux** 系统设计的 Supervisor 一键安装脚本，简化了 Supervisor 的安装、配置管理和进程监控。脚本支持自动生成主配置文件、创建日志目录、启用开机自启动，以及交互式添加/删除程序配置。添加或删除配置后，脚本会自动执行 `supervisorctl reread` 和 `supervisorctl update`，无需手动操作。

## 功能特性

- **自动安装 Supervisor**：通过 `apk` 安装 Supervisor，并创建必要的目录和日志文件。
- **生成主配置文件**：自动创建 `/etc/supervisord.conf`，确保日志文件和配置目录正确设置。
- **开机自启动**：将 Supervisor 添加到系统服务，自动启动。
- **交互式配置管理**：支持用户自定义程序名称、命令、工作目录、用户、自动重启等参数。
- **自动应用配置**：添加或删除配置后自动运行 `supervisorctl reread` 和 `supervisorctl update`。
- **测试脚本**：提供简单的测试脚本，验证 Supervisor 的进程管理功能。

## 环境要求

- **操作系统**：Alpine Linux
- **权限**：需要 root 权限运行脚本
- **网络**：需要联网以通过 `apk` 安装 Supervisor

## 安装与使用

### 1. 下载脚本

将以下文件下载到您的 Alpine Linux 系统：

- `supervisor_install.sh`：主安装脚本
- `test_script.sh`：测试脚本

```bash
wget https://raw.githubusercontent.com/<your-username>/<your-repo>/main/supervisor_install.sh
wget https://raw.githubusercontent.com/<your-username>/<your-repo>/main/test_script.sh
chmod +x supervisor_install.sh test_script.sh# -Supervisor-for-Alpine-Linux
