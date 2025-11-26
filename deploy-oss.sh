#!/bin/bash

# MacBook (BSD) 兼容版本

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

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}阿里云 OSS 部署脚本 (MacBook版)${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "${YELLOW}部署配置:${NC}"
echo -e "  Bucket: ${BLUE}${OSS_BUCKET}${NC}"
echo -e "  Endpoint: ${BLUE}${OSS_ENDPOINT}${NC}"
echo -e "  部署路径: ${BLUE}${OSS_DEPLOY_PATH}${NC}"
echo -e "  本地目录: ${BLUE}dist/${NC}"
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
echo -e "${YELLOW}[1/5]${NC} 构建项目..."
./build.sh

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ 构建失败，终止部署${NC}"
    exit 1
fi

# 检查构建目录
if [ ! -d "dist" ]; then
    echo -e "${RED}✗ 构建目录 dist/ 不存在${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 构建完成${NC}"

# ========================================
# 步骤2: 备份当前版本
# ========================================
echo ""
echo -e "${YELLOW}[2/5]${NC} 备份当前版本..."
BACKUP_PATH="${OSS_DEPLOY_PATH}_backup_$(date +%Y%m%d_%H%M%S)"

# 检查是否有现有文件（MacBook 兼容）
FILE_COUNT=$(ossutil ls oss://${OSS_BUCKET}/${OSS_DEPLOY_PATH}/ 2>/dev/null | grep -c "oss://")

if [ "$FILE_COUNT" -gt 0 ]; then
    echo "  → 发现现有文件，创建备份..."
    ossutil cp -r oss://${OSS_BUCKET}/${OSS_DEPLOY_PATH}/ oss://${OSS_BUCKET}/${BACKUP_PATH}/ --update 2>&1 | grep -v "Succeed:"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 备份完成: ${BACKUP_PATH}${NC}"
    else
        echo -e "${YELLOW}⚠ 备份失败（可能是首次部署）${NC}"
    fi
else
    echo "  → 首次部署，跳过备份"
fi

# ========================================
# 步骤3: 清理旧文件（可选）
# ========================================
echo ""
echo -e "${YELLOW}[3/5]${NC} 清理旧文件..."
read -p "是否删除 OSS 上的旧文件？(y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ossutil rm oss://${OSS_BUCKET}/${OSS_DEPLOY_PATH}/ -r -f
    echo -e "${GREEN}✓ 旧文件已删除${NC}"
else
    echo "  → 保留旧文件（将覆盖同名文件）"
fi

# ========================================
# 步骤4: 上传文件到 OSS
# ========================================
echo ""
echo -e "${YELLOW}[4/5]${NC} 上传文件到 OSS..."

# 上传 HTML 文件
echo "  → 上传 HTML 文件..."
ossutil cp dist/index.html oss://${OSS_BUCKET}/${OSS_DEPLOY_PATH}/ \
    --meta "Cache-Control:${OSS_HTML_CACHE_CONTROL}#Content-Type:text/html; charset=utf-8" \
    -f

# 上传 CSS 文件
echo "  → 上传 CSS 文件..."
ossutil cp -r dist/assets/css/ oss://${OSS_BUCKET}/${OSS_DEPLOY_PATH}/assets/css/ \
    --meta "Cache-Control:${OSS_CACHE_CONTROL}#Content-Type:text/css" \
    --update \
    -f

# 上传 JS 文件
echo "  → 上传 JS 文件..."
ossutil cp -r dist/assets/js/ oss://${OSS_BUCKET}/${OSS_DEPLOY_PATH}/assets/js/ \
    --meta "Cache-Control:${OSS_CACHE_CONTROL}#Content-Type:application/javascript" \
    --update \
    -f

# 上传图片文件
if [ -d "dist/media/images" ] && [ "$(ls -A dist/media/images)" ]; then
    echo "  → 上传图片文件..."
    ossutil cp -r dist/media/images/ oss://${OSS_BUCKET}/${OSS_DEPLOY_PATH}/media/images/ \
        --meta "Cache-Control:${OSS_CACHE_CONTROL}" \
        --update \
        -f
fi

# 上传动画文件
if [ -d "dist/media/animations" ] && [ "$(ls -A dist/media/animations)" ]; then
    echo "  → 上传动画文件..."
    ossutil cp -r dist/media/animations/ oss://${OSS_BUCKET}/${OSS_DEPLOY_PATH}/media/animations/ \
        --meta "Cache-Control:${OSS_CACHE_CONTROL}" \
        --update \
        -f
fi

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 文件上传完成${NC}"
else
    echo -e "${RED}✗ 文件上传失败${NC}"
    exit 1
fi

# ========================================
# 步骤5: 验证部署
# ========================================
echo ""
echo -e "${YELLOW}[5/5]${NC} 验证部署..."

FILE_COUNT=$(ossutil ls oss://${OSS_BUCKET}/${OSS_DEPLOY_PATH}/ -r 2>/dev/null | grep -c "oss://")

if [ "$FILE_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✓ 验证成功，共上传 ${FILE_COUNT} 个对象${NC}"
else
    echo -e "${YELLOW}⚠ 无法验证文件数量${NC}"
fi

# ========================================
# 部署完成
# ========================================
echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}✓ 部署成功！${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "${YELLOW}访问地址:${NC}"

# CDN 域名
if [ -n "$OSS_CDN_DOMAIN" ]; then
    echo -e "  CDN: ${BLUE}${OSS_CDN_DOMAIN}/${OSS_DEPLOY_PATH}/${NC}"
fi

# OSS 直接访问
OSS_URL="https://${OSS_BUCKET}.${OSS_ENDPOINT}/${OSS_DEPLOY_PATH}/"
echo -e "  OSS: ${BLUE}${OSS_URL}${NC}"

echo ""
echo -e "${YELLOW}备份路径:${NC}"
echo -e "  ${BACKUP_PATH}"

echo ""
echo -e "${YELLOW}查看所有文件:${NC}"
echo "  ossutil ls oss://${OSS_BUCKET}/${OSS_DEPLOY_PATH}/ -r"

echo ""
echo -e "${YELLOW}回滚到备份:${NC}"
echo "  ossutil cp -r oss://${OSS_BUCKET}/${BACKUP_PATH}/ oss://${OSS_BUCKET}/${OSS_DEPLOY_PATH}/ --update -f"
echo ""
