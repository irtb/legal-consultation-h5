#!/bin/bash

# ========================================
# 阿里云 OSS 部署脚本 v3.1.0
# - 备份统一管理
# - 自动刷新CDN
# ========================================

# 加载配置
if [ -f "oss-config.sh" ]; then
    source oss-config.sh
else
    echo -e "${RED}错误: 找不到 oss-config.sh 配置文件${NC}"
    echo "请先创建配置文件: cp oss-config.sh.example oss-config.sh"
    exit 1
fi

# 检查必需的环境变量
if [ -z "$OSS_BUCKET" ] || [ -z "$OSS_ENDPOINT" ]; then
    echo -e "${RED}错误: OSS 配置不完整${NC}"
    echo "请检查 oss-config.sh 中的配置"
    exit 1
fi

# 自定义部署路径（命令行参数）
if [ -n "$1" ]; then
    OSS_DEPLOY_PATH="$1"
else
    OSS_DEPLOY_PATH="$OSS_BASE_PATH"
fi

# 全局变量
BACKUP_DIR=".backups"  # 统一备份目录
BACKUP_PATH=""
ROLLBACK_NEEDED=false
DEPLOY_SUCCESS=false
ORIGINAL_FILE_COUNT=0
CDN_REFRESH_NEEDED=false

# ========================================
# 回滚函数
# ========================================
rollback() {
    echo ""
    echo -e "${RED}================================${NC}"
    echo -e "${RED}部署失败，开始自动回滚...${NC}"
    echo -e "${RED}================================${NC}"
    echo ""
    
    if [ -n "$BACKUP_PATH" ] && [ "$ROLLBACK_NEEDED" = true ]; then
        # 检查备份是否存在
        BACKUP_EXISTS=$(ossutil ls oss://${OSS_BUCKET}/${BACKUP_PATH}/ 2>/dev/null | grep -c "oss://")
        
        if [ "$BACKUP_EXISTS" -gt 0 ]; then
            echo -e "${YELLOW}[回滚 1/3]${NC} 删除失败的部署..."
            ossutil rm oss://${OSS_BUCKET}/${OSS_DEPLOY_PATH}/ -r -f 2>/dev/null
            
            echo -e "${YELLOW}[回滚 2/3]${NC} 恢复备份版本..."
            ossutil cp -r oss://${OSS_BUCKET}/${BACKUP_PATH}/ oss://${OSS_BUCKET}/${OSS_DEPLOY_PATH}/ --update -f
            
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓ 回滚成功，已恢复到之前的版本${NC}"
                
                echo -e "${YELLOW}[回滚 3/3]${NC} 清理临时备份..."
                read -p "是否保留此次备份？(y/n) " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    ossutil rm oss://${OSS_BUCKET}/${BACKUP_PATH}/ -r -f
                    echo -e "${GREEN}✓ 临时备份已清理${NC}"
                else
                    echo -e "${YELLOW}备份已保留: ${BACKUP_PATH}${NC}"
                fi
            else
                echo -e "${RED}✗ 回滚失败，请手动恢复${NC}"
                echo "手动恢复命令："
                echo "  ossutil cp -r oss://${OSS_BUCKET}/${BACKUP_PATH}/ oss://${OSS_BUCKET}/${OSS_DEPLOY_PATH}/ --update -f"
            fi
        else
            echo -e "${YELLOW}⚠ 没有找到备份${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ 未创建备份或不需要回滚${NC}"
    fi
    
    echo ""
    echo -e "${RED}================================${NC}"
    echo -e "${RED}部署失败${NC}"
    echo -e "${RED}================================${NC}"
    exit 1
}

# ========================================
# 清理函数（部署成功后调用）
# ========================================
cleanup() {
    if [ "$DEPLOY_SUCCESS" = true ] && [ -n "$BACKUP_PATH" ]; then
        echo ""
        echo -e "${YELLOW}清理备份${NC}"
        echo "备份路径: ${BACKUP_PATH}"
        read -p "是否删除本次备份？(y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ossutil rm oss://${OSS_BUCKET}/${BACKUP_PATH}/ -r -f
            echo -e "${GREEN}✓ 备份已删除${NC}"
        else
            echo -e "${YELLOW}备份已保留${NC}"
        fi
    fi
}

# ========================================
# CDN 刷新函数
# ========================================
refresh_cdn() {
    if [ -z "$OSS_CDN_DOMAIN" ]; then
        echo -e "${YELLOW}⚠ 未配置 CDN 域名，跳过 CDN 刷新${NC}"
        return
    fi
    
    echo ""
    echo -e "${YELLOW}[CDN]${NC} 刷新 CDN 缓存..."
    
    # 构建需要刷新的 URL 列表
    local urls=(
        "${OSS_CDN_DOMAIN}/${OSS_DEPLOY_PATH}/"
        "${OSS_CDN_DOMAIN}/${OSS_DEPLOY_PATH}/index.html"
        "${OSS_CDN_DOMAIN}/${OSS_DEPLOY_PATH}/assets/css/"
        "${OSS_CDN_DOMAIN}/${OSS_DEPLOY_PATH}/assets/js/"
    )
    
    # 检查是否安装了 aliyun CLI
    if command -v aliyun &> /dev/null; then
        echo "  → 使用 aliyun CLI 刷新 CDN..."
        
        # 构建 URL 字符串（逗号分隔）
        local url_string=$(IFS=,; echo "${urls[*]}")
        
        # 刷新 CDN（目录刷新）
        aliyun cdn RefreshObjectCaches \
            --ObjectPath="$url_string" \
            --ObjectType=Directory 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ CDN 刷新请求已提交${NC}"
            echo "  → 刷新通常需要 5-10 分钟生效"
        else
            echo -e "${YELLOW}⚠ CDN 刷新失败（可能需要配置 aliyun CLI）${NC}"
            show_manual_cdn_refresh
        fi
    else
        echo -e "${YELLOW}⚠ 未安装 aliyun CLI，提供手动刷新方法${NC}"
        show_manual_cdn_refresh
    fi
}

# ========================================
# 显示手动刷新 CDN 的方法
# ========================================
show_manual_cdn_refresh() {
    echo ""
    echo -e "${YELLOW}手动刷新 CDN 的方法：${NC}"
    echo ""
    echo "方法1: 阿里云控制台"
    echo "  1. 访问: https://cdn.console.aliyun.com/refresh"
    echo "  2. 选择「刷新缓存」"
    echo "  3. 输入以下 URL（选择「目录」类型）："
    echo "     ${OSS_CDN_DOMAIN}/${OSS_DEPLOY_PATH}/"
    echo ""
    echo "方法2: 安装 aliyun CLI"
    echo "  pip install aliyun-python-sdk-cdn"
    echo "  aliyun configure  # 配置 AccessKey"
    echo ""
}

# ========================================
# 捕获错误信号
# ========================================
trap 'rollback' INT TERM

# ========================================
# 开始部署
# ========================================
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}阿里云 OSS 部署脚本 v3.1.0${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "${YELLOW}部署配置:${NC}"
echo -e "  Bucket: ${BLUE}${OSS_BUCKET}${NC}"
echo -e "  Endpoint: ${BLUE}${OSS_ENDPOINT}${NC}"
echo -e "  部署路径: ${BLUE}${OSS_DEPLOY_PATH}${NC}"
echo -e "  备份目录: ${BLUE}${BACKUP_DIR}${NC}"
echo -e "  本地目录: ${BLUE}dist/${NC}"
if [ -n "$OSS_CDN_DOMAIN" ]; then
    echo -e "  CDN 域名: ${BLUE}${OSS_CDN_DOMAIN}${NC}"
fi
echo ""

# 询问确认
read -p "确认部署？(y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}取消部署${NC}"
    exit 0
fi

# ========================================
# 步骤1: 构建项目
# ========================================
echo ""
echo -e "${YELLOW}[1/7]${NC} 构建项目..."
./build.sh

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ 构建失败${NC}"
    exit 1
fi

# 检查构建目录
if [ ! -d "dist" ]; then
    echo -e "${RED}✗ 构建目录 dist/ 不存在${NC}"
    exit 1
fi

# 检查关键文件
if [ ! -f "dist/index.html" ]; then
    echo -e "${RED}✗ 缺少关键文件: index.html${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 构建完成并验证通过${NC}"

# ========================================
# 步骤2: 创建备份（统一到 .backups 目录）
# ========================================
echo ""
echo -e "${YELLOW}[2/7]${NC} 创建当前版本备份..."

# 备份路径格式: .backups/{项目名}/YYYYMMDD_HHMMSS/
PROJECT_NAME=$(basename "$OSS_DEPLOY_PATH")
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="${BACKUP_DIR}/${PROJECT_NAME}/${TIMESTAMP}"

# 检查是否有现有文件
ORIGINAL_FILE_COUNT=$(ossutil ls oss://${OSS_BUCKET}/${OSS_DEPLOY_PATH}/ 2>/dev/null | grep -c "oss://")

if [ "$ORIGINAL_FILE_COUNT" -gt 0 ]; then
    echo "  → 发现现有文件 (${ORIGINAL_FILE_COUNT} 个对象)"
    echo "  → 创建备份到: ${BACKUP_PATH}"
    
    # 创建备份
    ossutil cp -r oss://${OSS_BUCKET}/${OSS_DEPLOY_PATH}/ oss://${OSS_BUCKET}/${BACKUP_PATH}/ --update
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 备份完成${NC}"
        ROLLBACK_NEEDED=true
    else
        echo -e "${RED}✗ 备份失败${NC}"
        read -p "是否继续部署（无备份保护）？(y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}取消部署${NC}"
            exit 0
        fi
        echo -e "${YELLOW}⚠ 继续部署（无备份保护）${NC}"
        ROLLBACK_NEEDED=false
    fi
else
    echo "  → 首次部署，跳过备份"
    ROLLBACK_NEEDED=false
fi

# ========================================
# 步骤3: 验证备份
# ========================================
if [ "$ROLLBACK_NEEDED" = true ]; then
    echo ""
    echo -e "${YELLOW}[3/7]${NC} 验证备份完整性..."
    
    BACKUP_FILE_COUNT=$(ossutil ls oss://${OSS_BUCKET}/${BACKUP_PATH}/ -r 2>/dev/null | grep -c "oss://")
    
    if [ "$BACKUP_FILE_COUNT" -eq "$ORIGINAL_FILE_COUNT" ]; then
        echo -e "${GREEN}✓ 备份验证通过 (${BACKUP_FILE_COUNT}/${ORIGINAL_FILE_COUNT} 文件)${NC}"
    else
        echo -e "${YELLOW}⚠ 备份不完整 (${BACKUP_FILE_COUNT}/${ORIGINAL_FILE_COUNT} 文件)${NC}"
        read -p "是否继续部署？(y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}取消部署${NC}"
            ossutil rm oss://${OSS_BUCKET}/${BACKUP_PATH}/ -r -f
            exit 0
        fi
    fi
else
    echo ""
    echo -e "${YELLOW}[3/7]${NC} 跳过备份验证（首次部署）"
fi

# ========================================
# 步骤4: 清理旧文件
# ========================================
echo ""
echo -e "${YELLOW}[4/7]${NC} 清理旧文件..."

if [ "$ORIGINAL_FILE_COUNT" -gt 0 ]; then
    read -p "是否删除 OSS 上的旧文件？(y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ossutil rm oss://${OSS_BUCKET}/${OSS_DEPLOY_PATH}/ -r -f
        
        if [ $? -ne 0 ]; then
            echo -e "${RED}✗ 删除失败${NC}"
            rollback
        fi
        echo -e "${GREEN}✓ 旧文件已删除${NC}"
    else
        echo "  → 保留旧文件（将覆盖同名文件）"
    fi
else
    echo "  → 无旧文件需要清理"
fi

# ========================================
# 步骤5: 上传新文件
# ========================================
echo ""
echo -e "${YELLOW}[5/7]${NC} 上传文件到 OSS..."

# 上传 HTML 文件
echo "  → 上传 HTML 文件..."
ossutil cp dist/index.html oss://${OSS_BUCKET}/${OSS_DEPLOY_PATH}/ -f

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ HTML 上传失败${NC}"
    rollback
fi

# 上传 CSS 文件
echo "  → 上传 CSS 文件..."
if [ -d "dist/assets/css" ] && [ "$(ls -A dist/assets/css 2>/dev/null)" ]; then
    ossutil cp -r dist/assets/css/ oss://${OSS_BUCKET}/${OSS_DEPLOY_PATH}/assets/css/ --update -f
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ CSS 上传失败${NC}"
        rollback
    fi
fi

# 上传 JS 文件
echo "  → 上传 JS 文件..."
if [ -d "dist/assets/js" ] && [ "$(ls -A dist/assets/js 2>/dev/null)" ]; then
    ossutil cp -r dist/assets/js/ oss://${OSS_BUCKET}/${OSS_DEPLOY_PATH}/assets/js/ --update -f
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ JS 上传失败${NC}"
        rollback
    fi
fi

# 上传图片文件
if [ -d "dist/media/images" ] && [ "$(ls -A dist/media/images 2>/dev/null)" ]; then
    echo "  → 上传图片文件..."
    ossutil cp -r dist/media/images/ oss://${OSS_BUCKET}/${OSS_DEPLOY_PATH}/media/images/ --update -f
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ 图片上传失败${NC}"
        rollback
    fi
fi

# 上传动画文件
if [ -d "dist/media/animations" ] && [ "$(ls -A dist/media/animations 2>/dev/null)" ]; then
    echo "  → 上传动画文件..."
    ossutil cp -r dist/media/animations/ oss://${OSS_BUCKET}/${OSS_DEPLOY_PATH}/media/animations/ --update -f
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ 动画上传失败${NC}"
        rollback
    fi
fi

echo -e "${GREEN}✓ 所有文件上传完成${NC}"

# ========================================
# 步骤5.5: 设置缓存策略（可选）
# ========================================
echo ""
echo -e "${YELLOW}[5.5/7]${NC} 设置文件缓存策略..."

# HTML 缓存
ossutil set-meta oss://${OSS_BUCKET}/${OSS_DEPLOY_PATH}/index.html \
    Cache-Control:${OSS_HTML_CACHE_CONTROL} -f 2>/dev/null && \
    echo "  → HTML 缓存已设置" || echo "  → HTML 缓存设置跳过"

# 静态资源缓存
ossutil set-meta oss://${OSS_BUCKET}/${OSS_DEPLOY_PATH}/assets/ \
    Cache-Control:${OSS_CACHE_CONTROL} -r -f 2>/dev/null && \
    echo "  → 静态资源缓存已设置" || echo "  → 静态资源缓存设置跳过"

# 媒体文件缓存
ossutil set-meta oss://${OSS_BUCKET}/${OSS_DEPLOY_PATH}/media/ \
    Cache-Control:${OSS_CACHE_CONTROL} -r -f 2>/dev/null && \
    echo "  → 媒体文件缓存已设置" || echo "  → 媒体文件缓存设置跳过"

echo -e "${GREEN}✓ 缓存策略配置完成${NC}"

# ========================================
# 步骤6: 验证部署
# ========================================
echo ""
echo -e "${YELLOW}[6/7]${NC} 验证部署完整性..."

# 统计已上传的文件
DEPLOYED_FILE_COUNT=$(ossutil ls oss://${OSS_BUCKET}/${OSS_DEPLOY_PATH}/ -r 2>/dev/null | grep -c "oss://")

if [ "$DEPLOYED_FILE_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✓ 部署验证通过，共 ${DEPLOYED_FILE_COUNT} 个对象${NC}"
    
    # 检查关键文件是否存在
    echo "  → 验证关键文件..."
    
    # 检查 index.html
    ossutil stat oss://${OSS_BUCKET}/${OSS_DEPLOY_PATH}/index.html >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "    ✓ index.html"
    else
        echo -e "    ${RED}✗ index.html 缺失${NC}"
        rollback
    fi
    
    # 检查 CSS
    CSS_COUNT=$(ossutil ls oss://${OSS_BUCKET}/${OSS_DEPLOY_PATH}/assets/css/ 2>/dev/null | grep -c "\.css")
    if [ "$CSS_COUNT" -gt 0 ]; then
        echo "    ✓ CSS 文件 ($CSS_COUNT 个)"
    else
        echo -e "    ${YELLOW}⚠ CSS 文件可能缺失${NC}"
    fi
    
    # 检查 JS
    JS_COUNT=$(ossutil ls oss://${OSS_BUCKET}/${OSS_DEPLOY_PATH}/assets/js/ 2>/dev/null | grep -c "\.js")
    if [ "$JS_COUNT" -gt 0 ]; then
        echo "    ✓ JS 文件 ($JS_COUNT 个)"
    else
        echo -e "    ${YELLOW}⚠ JS 文件可能缺失${NC}"
    fi
    
    echo -e "${GREEN}✓ 关键文件验证通过${NC}"
    DEPLOY_SUCCESS=true
    
else
    echo -e "${RED}✗ 部署验证失败，未找到任何文件${NC}"
    rollback
fi

# ========================================
# 步骤7: 刷新 CDN
# ========================================
if [ -n "$OSS_CDN_DOMAIN" ]; then
    echo ""
    read -p "是否刷新 CDN 缓存？(y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        refresh_cdn
        CDN_REFRESH_NEEDED=true
    else
        echo -e "${YELLOW}⚠ 跳过 CDN 刷新（可能需要等待缓存过期）${NC}"
    fi
else
    echo ""
    echo -e "${YELLOW}[7/7]${NC} 跳过 CDN 刷新（未配置 CDN 域名）"
fi

# ========================================
# 部署成功
# ========================================
echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}✓ 部署成功！${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

# 显示访问地址
echo -e "${YELLOW}访问地址:${NC}"
if [ -n "$OSS_CDN_DOMAIN" ]; then
    echo -e "  CDN: ${BLUE}${OSS_CDN_DOMAIN}/${OSS_DEPLOY_PATH}/${NC}"
    if [ "$CDN_REFRESH_NEEDED" = true ]; then
        echo -e "       ${YELLOW}(CDN 刷新通常需要 5-10 分钟生效)${NC}"
    fi
fi
OSS_DIRECT_URL="https://${OSS_BUCKET}.${OSS_ENDPOINT}/${OSS_DEPLOY_PATH}/"
echo -e "  OSS: ${BLUE}${OSS_DIRECT_URL}${NC}"

# 显示备份信息
if [ -n "$BACKUP_PATH" ] && [ "$ROLLBACK_NEEDED" = true ]; then
    echo ""
    echo -e "${YELLOW}备份信息:${NC}"
    echo -e "  路径: ${BACKUP_PATH}"
    echo -e "  原文件数: ${ORIGINAL_FILE_COUNT}"
    echo -e "  新文件数: ${DEPLOYED_FILE_COUNT}"
fi

# 显示文件统计
echo ""
echo -e "${YELLOW}文件统计:${NC}"
echo -e "  HTML: 1 个"
echo -e "  CSS: $(ossutil ls oss://${OSS_BUCKET}/${OSS_DEPLOY_PATH}/assets/css/ 2>/dev/null | grep -c '\.css') 个"
echo -e "  JS: $(ossutil ls oss://${OSS_BUCKET}/${OSS_DEPLOY_PATH}/assets/js/ 2>/dev/null | grep -c '\.js') 个"
echo -e "  图片: $(ossutil ls oss://${OSS_BUCKET}/${OSS_DEPLOY_PATH}/media/images/ 2>/dev/null | grep -c 'oss://') 个"
echo -e "  动画: $(ossutil ls oss://${OSS_BUCKET}/${OSS_DEPLOY_PATH}/media/animations/ 2>/dev/null | grep -c 'oss://') 个"

# 显示常用命令
echo ""
echo -e "${YELLOW}常用命令:${NC}"
echo "  查看文件: ossutil ls oss://${OSS_BUCKET}/${OSS_DEPLOY_PATH}/ -r"
echo "  查看备份: ossutil ls oss://${OSS_BUCKET}/${BACKUP_DIR}/${PROJECT_NAME}/"
if [ -n "$BACKUP_PATH" ] && [ "$ROLLBACK_NEEDED" = true ]; then
    echo "  手动回滚: ossutil cp -r oss://${OSS_BUCKET}/${BACKUP_PATH}/ oss://${OSS_BUCKET}/${OSS_DEPLOY_PATH}/ --update -f"
fi
echo "  备份管理: ./backup-manager.sh"

# 询问是否清理备份
cleanup

echo ""
echo -e "${GREEN}部署流程完成！${NC}"
