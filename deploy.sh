#!/bin/bash

# ========================================
# 快捷部署脚本
# ========================================
# 使用方法:
#   ./deploy.sh              # 部署到默认路径（oss-config.sh 中配置的路径）
#   ./deploy.sh h5/test      # 部署到自定义路径
#   ./deploy.sh h5/prod/v2   # 部署到多级路径

CUSTOM_PATH="$1"

if [ -n "$CUSTOM_PATH" ]; then
    echo "部署到自定义路径: $CUSTOM_PATH"
    ./deploy-oss.sh "$CUSTOM_PATH"
else
    echo "部署到默认路径"
    ./deploy-oss.sh
fi
