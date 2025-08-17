#!/bin/sh

# 测试脚本: 无限循环输出消息
LOG_FILE="/var/log/test_script.log"

echo "Test script started at $(date)" >> $LOG_FILE

while true; do
    echo "Hello from test script! Time: $(date)"
    echo "Hello from test script! Time: $(date)" >> $LOG_FILE
    sleep 5
done
