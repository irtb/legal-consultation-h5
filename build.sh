#!/bin/bash

# MacBook (BSD) 兼容版本

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}开始构建和混淆 (MacBook版)${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

# 创建构建目录
echo -e "${YELLOW}[1/6]${NC} 创建构建目录..."
rm -rf dist/
mkdir -p dist/assets/{css,js}
mkdir -p dist/media/{images,animations}

# 1. 压缩CSS
echo -e "${YELLOW}[2/6]${NC} 压缩CSS..."
cleancss -o dist/assets/css/styles-v3.2.1.min.css assets/css/styles-v3.2.1.css

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} CSS压缩完成"
else
    echo -e "${RED}✗${NC} CSS压缩失败"
    exit 1
fi

# 2. 混淆和压缩JS
echo -e "${YELLOW}[3/6]${NC} 混淆和压缩JavaScript..."

# 检查混淆配置文件
if [ ! -f "obfuscate-config.json" ]; then
    echo -e "${RED}✗${NC} 找不到 obfuscate-config.json"
    exit 1
fi

# 混淆 core-7f2a3b4c.js
echo "  → 混淆 core-7f2a3b4c.js..."
javascript-obfuscator assets/js/core-7f2a3b4c.js \
    --output dist/assets/js/core-7f2a3b4c.tmp.js \
    --config obfuscate-config.json

if [ $? -ne 0 ]; then
    echo -e "${RED}✗${NC} JavaScript混淆失败"
    exit 1
fi

# 压缩混淆后的代码（MacBook 兼容语法）
echo "  → 压缩混淆后的代码..."
terser dist/assets/js/core-7f2a3b4c.tmp.js \
    -o dist/assets/js/core-7f2a3b4c.min.js \
    -c drop_console=true,drop_debugger=true \
    -m

if [ $? -eq 0 ]; then
    rm -f dist/assets/js/core-7f2a3b4c.tmp.js
    echo -e "${GREEN}✓${NC} JavaScript混淆压缩完成"
else
    echo -e "${RED}✗${NC} JavaScript压缩失败"
    exit 1
fi

# 复制 jQuery
echo "  → 复制 jQuery..."
cp assets/js/framework-2.1.5.min.js dist/assets/js/

# 3. 压缩HTML
echo -e "${YELLOW}[4/6]${NC} 压缩HTML..."
html-minifier index.html \
    --collapse-whitespace \
    --remove-comments \
    --remove-optional-tags \
    --remove-redundant-attributes \
    --remove-script-type-attributes \
    --remove-tag-whitespace \
    --use-short-doctype \
    --minify-css true \
    --minify-js true \
    -o dist/index.html

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} HTML压缩完成"
else
    echo -e "${RED}✗${NC} HTML压缩失败"
    exit 1
fi

# 4. 复制媒体文件
echo -e "${YELLOW}[5/6]${NC} 复制媒体文件..."
if [ -d "media/images" ] && [ "$(ls -A media/images)" ]; then
    cp media/images/* dist/media/images/
    echo "  → 图片文件已复制"
fi

if [ -d "media/animations" ] && [ "$(ls -A media/animations)" ]; then
    cp media/animations/* dist/media/animations/
    echo "  → 动画文件已复制"
fi

echo -e "${GREEN}✓${NC} 媒体文件复制完成"

# 5. 更新HTML中的引用路径（MacBook 语法）
echo -e "${YELLOW}[6/6]${NC} 更新资源引用..."
sed -i '' 's/core-7f2a3b4c\.js/core-7f2a3b4c.min.js/g' dist/index.html
sed -i '' 's/styles-v3\.2\.1\.css/styles-v3.2.1.min.css/g' dist/index.html
echo -e "${GREEN}✓${NC} 资源引用更新完成"

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}构建完成！${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

# 文件大小对比
echo -e "${YELLOW}文件大小对比:${NC}"
echo ""
echo -e "${YELLOW}HTML:${NC}"
if [ -f "index.html" ] && [ -f "dist/index.html" ]; then
    ORIGINAL_HTML=$(stat -f%z index.html)
    MINIFIED_HTML=$(stat -f%z dist/index.html)
    echo "  原始: $(echo "scale=2; $ORIGINAL_HTML / 1024" | bc) KB"
    echo "  压缩: $(echo "scale=2; $MINIFIED_HTML / 1024" | bc) KB"
    SAVED=$((ORIGINAL_HTML - MINIFIED_HTML))
    echo -e "  ${GREEN}节省: $(echo "scale=2; $SAVED / 1024" | bc) KB${NC}"
fi

echo ""
echo -e "${YELLOW}CSS:${NC}"
if [ -f "assets/css/styles-v3.2.1.css" ] && [ -f "dist/assets/css/styles-v3.2.1.min.css" ]; then
    ORIGINAL_CSS=$(stat -f%z assets/css/styles-v3.2.1.css)
    MINIFIED_CSS=$(stat -f%z dist/assets/css/styles-v3.2.1.min.css)
    echo "  原始: $(echo "scale=2; $ORIGINAL_CSS / 1024" | bc) KB"
    echo "  压缩: $(echo "scale=2; $MINIFIED_CSS / 1024" | bc) KB"
    SAVED=$((ORIGINAL_CSS - MINIFIED_CSS))
    echo -e "  ${GREEN}节省: $(echo "scale=2; $SAVED / 1024" | bc) KB${NC}"
fi

echo ""
echo -e "${YELLOW}JavaScript:${NC}"
if [ -f "assets/js/core-7f2a3b4c.js" ] && [ -f "dist/assets/js/core-7f2a3b4c.min.js" ]; then
    ORIGINAL_JS=$(stat -f%z assets/js/core-7f2a3b4c.js)
    MINIFIED_JS=$(stat -f%z dist/assets/js/core-7f2a3b4c.min.js)
    echo "  原始: $(echo "scale=2; $ORIGINAL_JS / 1024" | bc) KB"
    echo "  混淆压缩: $(echo "scale=2; $MINIFIED_JS / 1024" | bc) KB"
    SAVED=$((ORIGINAL_JS - MINIFIED_JS))
    echo -e "  ${GREEN}节省: $(echo "scale=2; $SAVED / 1024" | bc) KB${NC}"
fi

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${YELLOW}输出目录:${NC} dist/"
echo ""
echo -e "${YELLOW}测试命令:${NC}"
echo "  cd dist && python3 -m http.server 8000"
echo ""
echo -e "${YELLOW}部署命令:${NC}"
echo "  ./deploy-oss.sh"
echo -e "${GREEN}================================${NC}"
