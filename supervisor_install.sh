#!/bin/sh

# 一键安装Supervisor脚本 for Alpine Linux（修复版，自动执行reread和update）
# 作者: Grok
# 日期: 2025-08-16

# 检查是否为root用户
if [ "$(id -u)" != "0" ]; then
   echo "此脚本必须以root用户运行" 1>&2
   exit 1
fi

# 定义变量
SUPERVISOR_CONF="/etc/supervisord.conf"
SUPERVISOR_D_DIR="/etc/supervisor.d"
LOG_DIR="/var/log/supervisor"
LOG_FILE="$LOG_DIR/supervisord.log"
RUN_DIR="/var/run/supervisor"
SUPERVISOR_PKG="supervisor"

# 函数: 检查Supervisor是否运行
check_supervisor_running() {
    if [ -f "$RUN_DIR/supervisord.pid" ] && ps -p "$(cat $RUN_DIR/supervisord.pid)" > /dev/null 2>&1; then
        return 0  # Supervisor正在运行
    else
        return 1  # Supervisor未运行
    fi
}

# 函数: 安装Supervisor
install_supervisor() {
    if ! apk info -e "$SUPERVISOR_PKG" > /dev/null 2>&1; then
        echo "正在安装Supervisor..."
        apk update
        apk add "$SUPERVISOR_PKG"
    else
        echo "Supervisor已安装。"
    fi

    # 创建必要目录
    mkdir -p "$SUPERVISOR_D_DIR" "$LOG_DIR" "$RUN_DIR"

    # 创建并设置主日志文件权限
    if [ ! -f "$LOG_FILE" ]; then
        echo "创建主日志文件: $LOG_FILE"
        touch "$LOG_FILE"
        chmod 644 "$LOG_FILE"
        chown root:root "$LOG_FILE"
    fi
    # 确保日志目录权限
    chmod 755 "$LOG_DIR"
    chown root:root "$LOG_DIR"

    # 生成主配置文件如果不存在
    if [ ! -f "$SUPERVISOR_CONF" ]; then
        echo "生成主配置文件: $SUPERVISOR_CONF"
        cat << EOF > "$SUPERVISOR_CONF"
[unix_http_server]
file=$RUN_DIR/supervisord.sock   ; (the path to the socket file)

[supervisord]
logfile=$LOG_FILE ; (main log file)
logfile_maxbytes=50MB        ; (max main logfile bytes b4 rotation;default 50MB)
logfile_backups=10           ; (num of main logfile rotation backups;default 10)
loglevel=info                ; (log level;default info; others: debug,warn,trace)
pidfile=$RUN_DIR/supervisord.pid ; (supervisord pidfile;default supervisord.pid)
nodaemon=false               ; (start in foreground if true;default false)
minfds=1024                  ; (min. avail startup file descriptors;default 1024)
minprocs=200                 ; (min. avail process descriptors;default 200)

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix://$RUN_DIR/supervisord.sock ; use a unix:// URL  for a unix socket

[include]
files = $SUPERVISOR_D_DIR/*.ini
EOF
        chmod 644 "$SUPERVISOR_CONF"
    else
        echo "主配置文件已存在: $SUPERVISOR_CONF"
    fi
}

# 函数: 启用开机自启动
enable_autostart() {
    install_supervisor
    echo "启用Supervisor开机自启动..."
    if [ -f /etc/init.d/supervisord ]; then
        rc-update add supervisord default
        /etc/init.d/supervisord start
        echo "Supervisor已启动并加入开机自启动。"
    else
        echo "Supervisor init脚本不存在，请检查安装。"
    fi
}

# 函数: 添加程序配置
add_config() {
    echo "添加新程序配置..."
    printf "请输入程序名称（无空格）: "
    read prog_name
    if [ -z "$prog_name" ]; then
        echo "程序名称不能为空。"
        return
    fi
    config_file="$SUPERVISOR_D_DIR/$prog_name.ini"

    if [ -f "$config_file" ]; then
        echo "配置已存在: $config_file"
        return
    fi

    printf "请输入命令（例如: /usr/bin/myapp）: "
    read command
    if [ -z "$command" ]; then
        echo "命令不能为空。"
        return
    fi

    printf "请输入工作目录（默认: /）: "
    read directory
    if [ -z "$directory" ]; then
        directory="/"
    fi

    printf "请输入用户（默认: root）: "
    read user
    if [ -z "$user" ]; then
        user="root"
    fi

    printf "自动重启？（yes/no，默认: yes）: "
    read autorestart
    if [ -z "$autorestart" ] || [ "$autorestart" = "yes" ]; then
        autorestart="true"
    else
        autorestart="false"
    fi

    printf "启动重试次数（默认: 3）: "
    read startretries
    if [ -z "$startretries" ]; then
        startretries="3"
    fi

    printf "环境变量（格式: KEY1='value1',KEY2='value2'，默认: 无）: "
    read environment

    echo "生成配置: $config_file"
    cat << EOF > "$config_file"
[program:$prog_name]
command=$command
directory=$directory
user=$user
autorestart=$autorestart
startretries=$startretries
EOF
    if [ -n "$environment" ]; then
        echo "environment=$environment" >> "$config_file"
    fi
    chmod 644 "$config_file"

    # 自动执行reread和update
    if check_supervisor_running; then
        echo "应用新配置..."
        supervisorctl reread
        supervisorctl update
        echo "配置已应用。"
    else
        echo "Supervisor未运行，请先启动Supervisor（选项1），然后手动运行 'supervisorctl reread' 和 'supervisorctl update'。"
    fi
}

# 函数: 删除程序配置
delete_config() {
    echo "删除程序配置..."
    printf "请输入程序名称: "
    read prog_name
    if [ -z "$prog_name" ]; then
        echo "程序名称不能为空。"
        return
    fi
    config_file="$SUPERVISOR_D_DIR/$prog_name.ini"

    if [ -f "$config_file" ]; then
        rm "$config_file"
        echo "配置已删除: $config_file"
        # 自动执行reread和update
        if check_supervisor_running; then
            echo "更新配置..."
            supervisorctl reread
            supervisorctl update
            echo "配置已更新。"
        else
            echo "Supervisor未运行，请先启动Supervisor（选项1），然后手动运行 'supervisorctl reread' 和 'supervisorctl update'。"
        fi
    else
        echo "配置不存在: $config_file"
    fi
}

# 主菜单
while true; do
    echo ""
    echo "Supervisor 一键管理脚本"
    echo "1. 安装Supervisor并启用开机自启动"
    echo "2. 添加程序配置"
    echo "3. 删除程序配置"
    echo "4. 退出"
    printf "请选择选项: "
    read choice

    case $choice in
        1) enable_autostart ;;
        2) add_config ;;
        3) delete_config ;;
        4) exit 0 ;;
        *) echo "无效选项，请重试。" ;;
    esac
done
