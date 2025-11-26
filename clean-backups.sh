#!/bin/bash

source oss-config.sh

echo "================================"
echo "清理 OSS 备份文件"
echo "================================"
echo ""

# 列出所有备份
echo "现有备份:"
ossutil ls oss://${OSS_BUCKET}/ | grep "_backup_"

echo ""
read -p "是否删除 7 天前的备份？(y/n) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # 获取7天前的日期
    SEVEN_DAYS_AGO=$(date -d "7 days ago" +%Y%m%d)
    
    # 删除旧备份
    ossutil ls oss://${OSS_BUCKET}/ | grep "_backup_" | while read -r line; do
        BACKUP_NAME=$(echo $line | awk '{print $NF}')
        BACKUP_DATE=$(echo $BACKUP_NAME | grep -oP '\d{8}' | head -1)
        
        if [ "$BACKUP_DATE" -lt "$SEVEN_DAYS_AGO" ]; then
            echo "删除旧备份: $BACKUP_NAME"
            ossutil rm oss://${OSS_BUCKET}/${BACKUP_NAME} -r -f
        fi
    done
    
    echo "清理完成"
else
    echo "取消清理"
fi
