#!/bin/bash

# ========================================
# OSS 备份管理工具 v2.0
# 支持统一备份目录管理
# ========================================

source oss-config.sh

BACKUP_DIR=".backups"

# 列出所有项目的备份
list_all_backups() {
    echo ""
    echo "================================"
    echo "所有项目备份列表"
    echo "================================"
    echo ""
    
    # 列出所有项目
    ossutil ls oss://${OSS_BUCKET}/${BACKUP_DIR}/ 2>/dev/null | grep "oss://" | while IFS= read -r line; do
        PROJECT_PATH=$(echo "$line" | awk '{print $NF}' | sed 's|oss://'${OSS_BUCKET}'/||' | sed 's|/$||')
        PROJECT_NAME=$(basename "$PROJECT_PATH")
        
        if [ -n "$PROJECT_NAME" ]; then
            echo "📁 项目: $PROJECT_NAME"
            
            # 列出该项目的所有备份
            ossutil ls oss://${OSS_BUCKET}/${PROJECT_PATH}/ 2>/dev/null | grep "oss://" | while IFS= read -r backup_line; do
                BACKUP_TIME=$(echo "$backup_line" | awk '{print $NF}' | sed 's|oss://'${OSS_BUCKET}'/'${PROJECT_PATH}'/||' | sed 's|/$||')
                FILE_COUNT=$(ossutil ls oss://${OSS_BUCKET}/${PROJECT_PATH}/${BACKUP_TIME}/ -r 2>/dev/null | grep -c "oss://")
                
                if [ -n "$BACKUP_TIME" ]; then
                    echo "  └─ $BACKUP_TIME ($FILE_COUNT 个文件)"
                fi
            done
            echo ""
        fi
    done
}

# 列出指定项目的备份
list_project_backups() {
    read -p "输入项目名称（如: tct）: " PROJECT_NAME
    
    if [ -z "$PROJECT_NAME" ]; then
        echo "错误: 项目名称不能为空"
        return
    fi
    
    echo ""
    echo "================================"
    echo "项目 $PROJECT_NAME 的备份列表"
    echo "================================"
    echo ""
    
    PROJECT_PATH="${BACKUP_DIR}/${PROJECT_NAME}"
    
    ossutil ls oss://${OSS_BUCKET}/${PROJECT_PATH}/ 2>/dev/null | grep "oss://" | while IFS= read -r line; do
        BACKUP_TIME=$(echo "$line" | awk '{print $NF}' | sed 's|oss://'${OSS_BUCKET}'/'${PROJECT_PATH}'/||' | sed 's|/$||')
        
        if [ -n "$BACKUP_TIME" ]; then
            FILE_COUNT=$(ossutil ls oss://${OSS_BUCKET}/${PROJECT_PATH}/${BACKUP_TIME}/ -r 2>/dev/null | grep -c "oss://")
            
            # 格式化时间显示
            DISPLAY_TIME=$(echo "$BACKUP_TIME" | sed 's/_/ /g' | sed 's/\([0-9]\{8\}\) \([0-9]\{6\}\)/\1 \2/')
            echo "  • $DISPLAY_TIME ($FILE_COUNT 个文件)"
        fi
    done
    
    echo ""
}

# 删除指定备份
delete_backup() {
    read -p "输入项目名称（如: tct）: " PROJECT_NAME
    
    if [ -z "$PROJECT_NAME" ]; then
        echo "错误: 项目名称不能为空"
        return
    fi
    
    echo ""
    echo "项目 $PROJECT_NAME 的备份列表:"
    PROJECT_PATH="${BACKUP_DIR}/${PROJECT_NAME}"
    
    ossutil ls oss://${OSS_BUCKET}/${PROJECT_PATH}/ 2>/dev/null | grep "oss://" | nl -w2 -s'. '
    
    echo ""
    read -p "输入要删除的备份时间戳（如: 20251126_170755）: " BACKUP_TIME
    
    if [ -z "$BACKUP_TIME" ]; then
        echo "错误: 备份时间戳不能为空"
        return
    fi
    
    FULL_BACKUP_PATH="${PROJECT_PATH}/${BACKUP_TIME}"
    
    echo ""
    echo "确认删除备份: $FULL_BACKUP_PATH"
    read -p "(y/n) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ossutil rm oss://${OSS_BUCKET}/${FULL_BACKUP_PATH}/ -r -f
        if [ $? -eq 0 ]; then
            echo "✓ 备份已删除"
        else
            echo "✗ 删除失败"
        fi
    fi
}

# 清理旧备份
cleanup_old_backups() {
    read -p "输入项目名称（如: tct，留空表示所有项目）: " PROJECT_NAME
    read -p "保留最近几个备份？[默认5]: " KEEP_COUNT
    KEEP_COUNT=${KEEP_COUNT:-5}
    
    echo ""
    echo "保留最近 $KEEP_COUNT 个备份，删除其余..."
    echo ""
    
    if [ -z "$PROJECT_NAME" ]; then
        # 清理所有项目
        ossutil ls oss://${OSS_BUCKET}/${BACKUP_DIR}/ 2>/dev/null | grep "oss://" | while IFS= read -r line; do
            PROJECT_PATH=$(echo "$line" | awk '{print $NF}' | sed 's|oss://'${OSS_BUCKET}'/||' | sed 's|/$||')
            PROJECT=$(basename "$PROJECT_PATH")
            
            echo "处理项目: $PROJECT"
            cleanup_project_backups "$PROJECT_PATH" "$KEEP_COUNT"
        done
    else
        # 清理指定项目
        PROJECT_PATH="${BACKUP_DIR}/${PROJECT_NAME}"
        cleanup_project_backups "$PROJECT_PATH" "$KEEP_COUNT"
    fi
    
    echo ""
    echo "✓ 清理完成"
}

# 清理指定项目的旧备份
cleanup_project_backups() {
    local PROJECT_PATH=$1
    local KEEP_COUNT=$2
    
    # 获取所有备份，按时间排序
    local BACKUPS=$(ossutil ls oss://${OSS_BUCKET}/${PROJECT_PATH}/ 2>/dev/null | grep "oss://" | awk '{print $NF}' | sed 's|oss://'${OSS_BUCKET}'/'${PROJECT_PATH}'/||' | sed 's|/$||' | sort -r)
    
    local COUNT=0
    echo "$BACKUPS" | while IFS= read -r BACKUP_TIME; do
        COUNT=$((COUNT + 1))
        
        if [ $COUNT -gt $KEEP_COUNT ]; then
            echo "  删除: ${PROJECT_PATH}/${BACKUP_TIME}"
            ossutil rm oss://${OSS_BUCKET}/${PROJECT_PATH}/${BACKUP_TIME}/ -r -f
        else
            echo "  保留: ${PROJECT_PATH}/${BACKUP_TIME}"
        fi
    done
}

# 恢复备份
restore_backup() {
    read -p "输入项目名称（如: tct）: " PROJECT_NAME
    
    if [ -z "$PROJECT_NAME" ]; then
        echo "错误: 项目名称不能为空"
        return
    fi
    
    echo ""
    echo "项目 $PROJECT_NAME 的备份列表:"
    PROJECT_PATH="${BACKUP_DIR}/${PROJECT_NAME}"
    
    ossutil ls oss://${OSS_BUCKET}/${PROJECT_PATH}/ 2>/dev/null | grep "oss://" | nl -w2 -s'. '
    
    echo ""
    read -p "输入要恢复的备份时间戳（如: 20251126_170755）: " BACKUP_TIME
    
    if [ -z "$BACKUP_TIME" ]; then
        echo "错误: 备份时间戳不能为空"
        return
    fi
    
    FULL_BACKUP_PATH="${PROJECT_PATH}/${BACKUP_TIME}"
    
    # 确定恢复目标路径（假设与项目名称相同）
    read -p "恢复到哪个路径？[默认: $PROJECT_NAME]: " RESTORE_PATH
    RESTORE_PATH=${RESTORE_PATH:-$PROJECT_NAME}
    
    echo ""
    echo "恢复配置:"
    echo "  从: $FULL_BACKUP_PATH"
    echo "  到: $RESTORE_PATH"
    echo ""
    read -p "确认恢复？(y/n) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # 先备份当前版本
        TEMP_BACKUP="${PROJECT_PATH}/temp_$(date +%Y%m%d_%H%M%S)"
        echo "创建临时备份: $TEMP_BACKUP"
        ossutil cp -r oss://${OSS_BUCKET}/${RESTORE_PATH}/ oss://${OSS_BUCKET}/${TEMP_BACKUP}/ --update 2>/dev/null
        
        # 清空目标
        echo "清空目标路径..."
        ossutil rm oss://${OSS_BUCKET}/${RESTORE_PATH}/ -r -f
        
        # 恢复备份
        echo "恢复备份..."
        ossutil cp -r oss://${OSS_BUCKET}/${FULL_BACKUP_PATH}/ oss://${OSS_BUCKET}/${RESTORE_PATH}/ --update -f
        
        if [ $? -eq 0 ]; then
            echo "✓ 恢复完成"
            echo ""
            read -p "是否删除临时备份 $TEMP_BACKUP？(y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                ossutil rm oss://${OSS_BUCKET}/${TEMP_BACKUP}/ -r -f
                echo "✓ 临时备份已删除"
            fi
        else
            echo "✗ 恢复失败，请检查临时备份: $TEMP_BACKUP"
        fi
    fi
}

# 查看备份详情
view_backup_details() {
    read -p "输入项目名称（如: tct）: " PROJECT_NAME
    
    if [ -z "$PROJECT_NAME" ]; then
        echo "错误: 项目名称不能为空"
        return
    fi
    
    read -p "输入备份时间戳（如: 20251126_170755）: " BACKUP_TIME
    
    if [ -z "$BACKUP_TIME" ]; then
        echo "错误: 备份时间戳不能为空"
        return
    fi
    
    FULL_BACKUP_PATH="${BACKUP_DIR}/${PROJECT_NAME}/${BACKUP_TIME}"
    
    echo ""
    echo "================================"
    echo "备份详情"
    echo "================================"
    echo "  项目: $PROJECT_NAME"
    echo "  时间: $BACKUP_TIME"
    echo "  路径: $FULL_BACKUP_PATH"
    echo ""
    echo "文件列表:"
    ossutil ls oss://${OSS_BUCKET}/${FULL_BACKUP_PATH}/ -r
}

# 统计备份大小
show_backup_statistics() {
    echo ""
    echo "================================"
    echo "备份统计信息"
    echo "================================"
    echo ""
    
    # 统计总备份数和大小
    TOTAL_BACKUPS=$(ossutil ls oss://${OSS_BUCKET}/${BACKUP_DIR}/ -r 2>/dev/null | grep "oss://" | wc -l)
    
    echo "统计中..."
    ossutil du oss://${OSS_BUCKET}/${BACKUP_DIR}/ 2>/dev/null
    
    echo ""
    echo "总备份数: $TOTAL_BACKUPS 个文件/目录"
    
    # 按项目统计
    echo ""
    echo "各项目备份统计:"
    ossutil ls oss://${OSS_BUCKET}/${BACKUP_DIR}/ 2>/dev/null | grep "oss://" | while IFS= read -r line; do
        PROJECT_PATH=$(echo "$line" | awk '{print $NF}' | sed 's|oss://'${OSS_BUCKET}'/||' | sed 's|/$||')
        PROJECT_NAME=$(basename "$PROJECT_PATH")
        
        if [ -n "$PROJECT_NAME" ]; then
            BACKUP_COUNT=$(ossutil ls oss://${OSS_BUCKET}/${PROJECT_PATH}/ 2>/dev/null | grep -c "oss://")
            echo "  $PROJECT_NAME: $BACKUP_COUNT 个备份"
        fi
    done
    
    echo ""
}

# 主菜单
while true; do
    echo ""
    echo "================================"
    echo "OSS 备份管理工具 v2.0"
    echo "================================"
    echo ""
    echo "请选择操作:"
    echo "  1) 列出所有备份"
    echo "  2) 列出指定项目的备份"
    echo "  3) 查看备份详情"
    echo "  4) 恢复备份"
    echo "  5) 删除指定备份"
    echo "  6) 清理旧备份"
    echo "  7) 备份统计"
    echo "  8) 退出"
    echo ""
    read -p "选择 [1-8]: " choice
    
    case $choice in
        1) list_all_backups ;;
        2) list_project_backups ;;
        3) view_backup_details ;;
        4) restore_backup ;;
        5) delete_backup ;;
        6) cleanup_old_backups ;;
        7) show_backup_statistics ;;
        8) echo "再见！"; exit 0 ;;
        *) echo "无效选择，请重新输入" ;;
    esac
done