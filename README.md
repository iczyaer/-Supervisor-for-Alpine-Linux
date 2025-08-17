Supervisor 一键安装脚本 (Alpine Linux)

项目描述
这是一个为 Alpine Linux 系统设计的 Supervisor 一键安装脚本，简化了 Supervisor 的安装、配置管理和进程监控。脚本支持自动生成主配置文件、创建日志目录、启用开机自启动，以及交互式添加/删除程序配置。添加或删除配置后，脚本会自动执行 supervisorctl reread 和 supervisorctl update，无需手动操作。另提供一个测试脚本，用于验证 Supervisor 的功能。

功能特性
- 自动安装 Supervisor：通过 apk 安装 Supervisor，创建必要的目录和日志文件。
- 生成主配置文件：自动创建 /etc/supervisord.conf，确保日志文件和配置目录正确设置。
- 开机自启动：将 Supervisor 添加到系统服务，自动启动。
- 交互式配置管理：支持用户自定义程序名称、命令、工作目录、用户、自动重启等参数。
- 自动应用配置：添加或删除配置后自动运行 supervisorctl reread 和 supervisorctl update。
- 测试脚本：提供 test_script.sh，每 5 秒输出消息到日志和 stdout，用于验证进程管理功能。

环境要求
- 操作系统：Alpine Linux
- 权限：需要 root 权限运行脚本
- 网络：需要联网以通过 apk 安装 Supervisor

安装与使用

1. 下载脚本
将以下文件下载到您的 Alpine Linux 系统：
- supervisor_install.sh：主安装脚本
- test_script.sh：测试脚本

命令：
wget https://raw.githubusercontent.com/iczyaer/Supervisor-for-Alpine-Linux/main/supervisor_install.sh
wget https://raw.githubusercontent.com/iczyaer/Supervisor-for-Alpine-Linux/main/test_script.sh
chmod +x supervisor_install.sh test_script.sh

2. 准备测试脚本
将测试脚本移动到 /usr/local/bin/ 并设置执行权限：

命令：
mv test_script.sh /usr/local/bin/test_script.sh
chmod +x /usr/local/bin/test_script.sh

3. 运行安装脚本
以 root 用户运行脚本：

命令：
./supervisor_install.sh

脚本提供以下菜单选项：
1. 安装 Supervisor 并启用开机自启动：安装 Supervisor，创建日志文件 /var/log/supervisor/supervisord.log 和主配置文件 /etc/supervisord.conf，并加入系统服务。
2. 添加程序配置：交互式输入程序参数，生成 /etc/supervisor.d/*.ini 配置文件，并自动应用。
3. 删除程序配置：删除指定的 .ini 配置文件，并自动更新。
4. 退出：退出脚本。

4. 添加测试配置
1. 选择菜单选项 2 添加程序配置。
2. 输入以下参数：
   - 程序名称：test_script
   - 命令：/usr/local/bin/test_script.sh
   - 工作目录：/（默认，按 Enter）
   - 用户：root（默认，按 Enter）
   - 自动重启：yes（默认，按 Enter）
   - 启动重试次数：3（默认，按 Enter）
   - 环境变量：留空（默认，按 Enter）
3. 脚本会生成 /etc/supervisor.d/test_script.ini 并自动运行 supervisorctl reread 和 supervisorctl update，输出“配置已应用”。

生成的配置文件示例：
[program:test_script]
command=/usr/local/bin/test_script.sh
directory=/
user=root
autorestart=true
startretries=3

5. 验证功能
- 检查进程状态：
  命令：supervisorctl status
  预期输出：test_script RUNNING

- 查看日志：
  - Supervisor 主日志：
    命令：tail -f /var/log/supervisor/supervisord.log
    预期：包含启动信息，无“没有文件”错误。
  - 测试脚本日志：
    命令：tail -f /var/log/test_script.log
    预期：每 5 秒输出 Hello from test script! Time: ...
  - 进程输出日志：
    命令：tail -f /var/log/supervisor/test_script-stdout---supervisor-*.log
    预期：捕获的 stdout 输出

- 测试进程管理：
  - 停止进程：
    命令：supervisorctl stop test_script
    预期：状态变为 STOPPED
  - 启动进程：
    命令：supervisorctl start test_script
    预期：状态变回 RUNNING
  - 模拟崩溃：
    命令：pkill -f test_script.sh
    预期：Supervisor 自动重启，状态仍为 RUNNING

- 测试开机自启动：
  命令：reboot
  命令：supervisorctl status
  预期：test_script RUNNING

- 删除配置：
  选择菜单选项 3，输入 test_script，脚本会删除 /etc/supervisor.d/test_script.ini 并自动运行 supervisorctl reread 和 supervisorctl update，输出“配置已更新”。

6. 测试未运行 Supervisor 的情况
1. 停止 Supervisor：
   命令：/etc/init.d/supervisord stop
2. 选择菜单选项 2 添加配置（如 test_script）。
3. 脚本会提示：
   Supervisor未运行，请先启动Supervisor（选项1），然后手动运行 'supervisorctl reread' 和 'supervisorctl update'。
4. 选择选项 1 启动 Supervisor，再次添加配置，确认自动 reread 和 update 生效。

文件结构
- supervisor_install.sh：主脚本，包含安装、配置管理和自启动功能。
- test_script.sh：测试脚本，每 5 秒输出消息到日志和 stdout。
- 生成的文件：
  - /etc/supervisord.conf：主配置文件
  - /etc/supervisor.d/*.ini：程序配置文件
  - /var/log/supervisor/supervisord.log：Supervisor 主日志
  - /var/log/supervisor/*.log：进程日志
  - /var/log/test_script.log：测试脚本日志

常见问题
- 日志文件不存在：
  - 检查目录权限：
    命令：ls -ld /var/log/supervisor
    预期：drwxr-xr-x
  - 确保日志文件存在：
    命令：ls -l /var/log/supervisor/supervisord.log
    预期：-rw-r--r--
- Supervisor 未运行：
  - 启动服务：
    命令：/etc/init.d/supervisord start
  - 检查服务状态：
    命令：rc-status
- 进程未启动：
  - 验证测试脚本路径和权限：
    命令：ls -l /usr/local/bin/test_script.sh
  - 检查 Supervisor 日志：
    命令：tail /var/log/supervisor/supervisord.log
- 自动 reread/update 失败：
  - 确认 Supervisor 运行：
    命令：ps -p $(cat /var/run/supervisor/supervisord.pid)
  - 手动运行：
    命令：supervisorctl reread && supervisorctl update

贡献
欢迎提交 Issues 或 Pull Requests！如果您有改进建议或发现问题，请在 GitHub 仓库中反馈。

许可证
MIT License (请在仓库中添加 LICENSE 文件)
