# H5项目构建和部署使用手册

> 版本：v2.0.4
> 更新日期：2024-03-15
> 适用平台：MacBook / Linux

---

## 📋 目录

* [1. 项目简介](#1-项目简介)
* [2. 环境要求](#2-环境要求)
* [3. 快速开始](#3-快速开始)
* [4. 目录结构](#4-目录结构)
* [5. 构建流程](#5-构建流程)
* [6. 部署流程](#6-部署流程)
* [7. 常用命令](#7-常用命令)
* [8. 故障排查](#8-故障排查)
* [9. 最佳实践](#9-最佳实践)
* [10. FAQ](#10-faq)

---

## 1. 项目简介

### 1.1 项目概述

本项目是一个法律咨询H5页面，主要功能包括：

* 债务咨询问答流程
* 企业微信加粉引流
* 好多粉统计集成
* 响应式移动端适配

### 1.2 技术栈

| 技术                    | 版本     | 说明          |
| --------------------- | ------ | ----------- |
| jQuery                | 2.1.5  | JavaScript库 |
| 好多粉统计                 | Latest | zaaxstat.js |
| 阿里云OSS                | -      | 静态资源托管      |
| JavaScript Obfuscator | Latest | 代码混淆        |
| Terser                | Latest | 代码压缩        |
| CleanCSS              | Latest | CSS压缩       |
| HTML Minifier         | Latest | HTML压缩      |

### 1.3 浏览器兼容性

* ✅ iOS Safari 10+
* ✅ Android Chrome 60+
* ✅ 微信内置浏览器
* ✅ 企业微信

---

## 2. 环境要求

### 2.1 系统要求

* **MacBook**: macOS 10.15+
* **Linux**: Ubuntu 18.04+ / CentOS 7+
* **Node.js**: 14.0+
* **Python**: 3.6+ (用于本地测试服务器)

### 2.2 必需工具安装

#### 2.2.1 安装 Node.js 工具

```bash
# 安装构建和压缩工具
npm install -g terser
npm install -g clean-css-cli
npm install -g html-minifier
npm install -g javascript-obfuscator
```

#### 2.2.2 安装阿里云 OSS 工具

**MacBook:**

```bash
# 下载 ossutil (macOS)
curl -o ossutil https://gosspublic.alicdn.com/ossutil/1.7.18/ossutil-v1.7.18-darwin-amd64
chmod +x ossutil
sudo mv ossutil /usr/local/bin/

# 验证安装
ossutil --version
```

**Linux:**

```bash
# 下载 ossutil (Linux 64位)
wget https://gosspublic.alicdn.com/ossutil/1.7.18/ossutil-v1.7.18-linux-amd64.zip
unzip ossutil-v1.7.18-linux-amd64.zip
sudo mv ossutil-v1.7.18-linux-amd64/ossutil /usr/local/bin/
sudo chmod +x /usr/local/bin/ossutil

# 验证安装
ossutil --version
```

#### 2.2.3 配置 ossutil

```bash
# 交互式配置
ossutil config

# 按提示输入：
# endpoint: oss-cn-beijing.aliyuncs.com (根据你的区域修改)
# accessKeyID: 你的AccessKeyID
# accessKeySecret: 你的AccessKeySecret

# 测试连接
ossutil ls
```

### 2.3 可选工具

```bash
# bc 计算器 (用于显示压缩率)
# MacBook (通常已安装)
brew install bc

# Ubuntu/Debian
sudo apt-get install bc

# CentOS/RHEL
sudo yum install bc
```

---

## 3. 快速开始

### 3.1 克隆或下载项目

```bash
# 如果是 git 项目
git clone https://irtb/legal-consultation-h5.git
cd h5v8

# 或者直接下载解压
unzip h5v8.zip
cd h5v8
```

### 3.2 配置 OSS

```bash
# 1. 复制配置文件模板
cp oss-config.sh.example oss-config.sh

# 2. 编辑配置
vim oss-config.sh

# 修改以下内容：
# export OSS_ENDPOINT="oss-cn-beijing.aliyuncs.com"
# export OSS_BUCKET="your-bucket-name"
# export OSS_ACCESS_KEY_ID="your-key-id"
# export OSS_ACCESS_KEY_SECRET="your-key-secret"
# export OSS_BASE_PATH="h5/v8"
```

### 3.3 首次构建

```bash
# 赋予脚本执行权限
chmod +x build.sh
chmod +x deploy-oss.sh
chmod +x deploy.sh

# 执行构建
./build.sh
```

### 3.4 本地测试

```bash
# 进入构建目录
cd dist

# 启动本地服务器
python3 -m http.server 8000

# 在浏览器访问
# http://localhost:8000
```

### 3.5 部署到 OSS

```bash
# 返回项目根目录
cd ..

# 部署到默认路径
./deploy.sh

# 或部署到自定义路径
./deploy.sh h5/test
```

---

## 4. 目录结构

```
h5v8/
├── README.md                        # 本使用手册
├── .gitignore                       # Git 忽略文件
│
├── index.html                       # 源 HTML 文件
│
├── assets/                          # 源代码目录
│   ├── css/
│   │   └── styles-v3.2.1.css       # 源 CSS
│   └── js/
│       ├── core-7f2a3b4c.js        # 主业务逻辑（源码）
│       └── framework-2.1.5.min.js  # jQuery 库
│
├── media/                           # 媒体资源
│   ├── images/
│   │   ├── advisor-portrait-001.jpg  # 律师头像
│   │   └── info-banner.jpg           # 退出提示横幅
│   └── animations/
│       └── gesture-indicator.gif     # 手势动画
│
├── build.sh                         # 构建脚本
├── deploy.sh                        # 快捷部署脚本
├── deploy-oss.sh                    # OSS 部署脚本
├── clean-backups.sh                 # 清理备份脚本
│
├── oss-config.sh                    # OSS 配置（不要提交到 git）
├── oss-config.sh.example            # OSS 配置示例
├── obfuscate-config.json            # 混淆配置
│
└── dist/                            # 构建输出（不要提交到 git）
    ├── index.html                   # 压缩后的 HTML
    ├── assets/
    │   ├── css/
    │   │   └── styles-v3.2.1.min.css
    │   └── js/
    │       ├── core-7f2a3b4c.min.js  # 混淆压缩后的 JS
    │       └── framework-2.1.5.min.js
    └── media/
        ├── images/
        └── animations/
```

---

## 5. 构建流程

### 5.1 构建命令

```bash
./build.sh
```

### 5.2 构建步骤详解

| 步骤 | 操作        | 输入                             | 输出                                      |
| -- | --------- | ------------------------------ | --------------------------------------- |
| 1  | 创建目录      | -                              | `dist/` 目录结构                            |
| 2  | 压缩 CSS    | `assets/css/styles-v3.2.1.css` | `dist/assets/css/styles-v3.2.1.min.css` |
| 3  | 混淆 JS     | `assets/js/core-7f2a3b4c.js`   | `dist/assets/js/core-7f2a3b4c.tmp.js`   |
| 4  | 压缩 JS     | `core-7f2a3b4c.tmp.js`         | `dist/assets/js/core-7f2a3b4c.min.js`   |
| 5  | 复制 jQuery | `framework-2.1.5.min.js`       | `dist/assets/js/framework-2.1.5.min.js` |
| 6  | 压缩 HTML   | `index.html`                   | `dist/index.html`                       |
| 7  | 复制媒体      | `media/*`                      | `dist/media/*`                          |
| 8  | 更新引用      | `dist/index.html`              | 路径指向 `.min` 文件                          |

### 5.3 构建输出示例

```
================================
开始构建和混淆 (MacBook版)
================================

[1/6] 创建构建目录...
[2/6] 压缩CSS...
✓ CSS压缩完成
[3/6] 混淆和压缩JavaScript...
  → 混淆 core-7f2a3b4c.js...
  → 压缩混淆后的代码...
✓ JavaScript混淆压缩完成
  → 复制 jQuery...
[4/6] 压缩HTML...
✓ HTML压缩完成
[5/6] 复制媒体文件...
  → 图片文件已复制
  → 动画文件已复制
✓ 媒体文件复制完成
[6/6] 更新资源引用...
✓ 资源引用更新完成

================================
构建完成！
================================

文件大小对比:

HTML:
  原始: 16.50 KB
  压缩: 9.12 KB
  节省: 7.38 KB

CSS:
  原始: 14.23 KB
  压缩: 9.45 KB
  节省: 4.78 KB

JavaScript:
  原始: 28.67 KB
  混淆压缩: 19.34 KB
  节省: 9.33 KB

================================
输出目录: dist/

测试命令:
  cd dist && python3 -m http.server 8000

部署命令:
  ./deploy-oss.sh
================================
```

### 5.4 验证构建结果

```bash
# 查看目录结构
tree dist/

# 查看文件大小
du -h dist/*

# 检查混淆效果
head -n 20 dist/assets/js/core-7f2a3b4c.min.js
```

---

## 6. 部署流程

### 6.1 部署命令

#### 6.1.1 部署到默认路径

```bash
./deploy.sh

# 等同于
./deploy-oss.sh
```

#### 6.1.2 部署到自定义路径

```bash
# 部署到测试环境
./deploy.sh h5/test

# 部署到生产环境
./deploy.sh h5/prod

# 部署到带版本号的路径
./deploy.sh h5/v1.0.0

# 部署到多级路径
./deploy.sh projects/legal/consultation
```

### 6.2 部署步骤详解

| 步骤 | 操作     | 说明                      |
| -- | ------ | ----------------------- |
| 1  | 显示配置信息 | 显示 Bucket、Endpoint、部署路径 |
| 2  | 确认部署   | 需要用户输入 `y` 确认           |
| 3  | 执行构建   | 自动调用 `build.sh`         |
| 4  | 备份旧版本  | 将现有文件备份到带时间戳的目录         |
| 5  | 清理旧文件  | 询问是否删除 OSS 上的旧文件        |
| 6  | 上传文件   | 分别上传 HTML、CSS、JS、图片     |
| 7  | 验证部署   | 统计已上传的文件数量              |
| 8  | 显示访问地址 | 显示 CDN 和 OSS 访问地址       |

### 6.3 部署输出示例

```
================================
阿里云 OSS 部署脚本 (MacBook版)
================================

部署配置:
  Bucket: my-h5-bucket
  Endpoint: oss-cn-beijing.aliyuncs.com
  部署路径: h5/v8
  本地目录: dist/

确认部署？(y/n) y

[1/5] 构建项目...
================================
开始构建和混淆 (MacBook版)
================================
...
构建完成！

[2/5] 备份当前版本...
  → 发现现有文件，创建备份...
✓ 备份完成: h5/v8_backup_20240315_143022

[3/5] 清理旧文件...
是否删除 OSS 上的旧文件？(y/n) y
✓ 旧文件已删除

[4/5] 上传文件到 OSS...
  → 上传 HTML 文件...
  → 上传 CSS 文件...
  → 上传 JS 文件...
  → 上传图片文件...
  → 上传动画文件...
✓ 文件上传完成

[5/5] 验证部署...
✓ 验证成功，共上传 11 个对象

================================
✓ 部署成功！
================================

访问地址:
  CDN: https://cdn.example.com/h5/v8/
  OSS: https://my-h5-bucket.oss-cn-beijing.aliyuncs.com/h5/v8/

备份路径:
  h5/v8_backup_20240315_143022

查看所有文件:
  ossutil ls oss://my-h5-bucket/h5/v8/ -r

回滚到备份:
  ossutil cp -r oss://my-h5-bucket/h5/v8_backup_20240315_143022/ oss://my-h5-bucket/h5/v8/ --update -f
```

### 6.4 部署场景示例

#### 场景1：开发环境测试

```bash
# 1. 修改代码
vim assets/js/core-7f2a3b4c.js

# 2. 部署到测试环境
./deploy.sh h5/dev

# 3. 访问测试地址
# https://your-bucket.oss-cn-beijing.aliyuncs.com/h5/dev/
```

#### 场景2：预发布环境

```bash
# 部署到预发布
./deploy.sh h5/staging

# 测试通过后再部署到生产
./deploy.sh h5/prod
```

#### 场景3：版本管理

```bash
# 部署不同版本
./deploy.sh h5/v1.0.0
./deploy.sh h5/v1.0.1
./deploy.sh h5/v1.1.0

# 可以同时保留多个版本，方便回滚
```

#### 场景4：灰度发布

```bash
# 部署新版本到灰度环境
./deploy.sh h5/gray

# 配置好多粉按比例分流
# 10% 流量 → https://bucket.com/h5/gray/
# 90% 流量 → https://bucket.com/h5/prod/
```

---

## 7. 常用命令

### 7.1 构建相关

```bash
# 完整构建
./build.sh

# 只构建不部署
./build.sh

# 清理构建产物
rm -rf dist/

# 查看构建产物
tree dist/
du -h dist/
```

### 7.2 部署相关

```bash
# 部署到默认路径
./deploy.sh

# 部署到指定路径
./deploy.sh h5/custom-path

# 只上传不构建（手动调用）
ossutil cp -r dist/ oss://bucket/path/ --update
```

### 7.3 OSS 管理

```bash
# 查看 bucket 列表
ossutil ls

# 查看指定路径的文件
ossutil ls oss://bucket/h5/v8/
ossutil ls oss://bucket/h5/v8/ -r  # 递归显示

# 下载文件
ossutil cp oss://bucket/h5/v8/index.html ./

# 下载整个目录
ossutil cp -r oss://bucket/h5/v8/ ./backup/

# 删除文件
ossutil rm oss://bucket/h5/v8/index.html

# 删除目录
ossutil rm oss://bucket/h5/v8/ -r -f

# 设置文件权限（公共读）
ossutil set-acl oss://bucket/h5/v8/ public-read -r

# 查看文件详情
ossutil stat oss://bucket/h5/v8/index.html

# 同步目录（本地→OSS）
ossutil sync dist/ oss://bucket/h5/v8/
```

### 7.4 备份管理

```bash
# 查看所有备份
ossutil ls oss://bucket/ | grep "_backup_"

# 恢复备份
ossutil cp -r oss://bucket/h5/v8_backup_20240315_143022/ oss://bucket/h5/v8/ --update -f

# 删除指定备份
ossutil rm oss://bucket/h5/v8_backup_20240315_143022/ -r -f

# 清理7天前的备份
./clean-backups.sh
```

### 7.5 本地测试

```bash
# 方法1: Python
cd dist && python3 -m http.server 8000

# 方法2: PHP
cd dist && php -S localhost:8000

# 方法3: Node.js (需要安装 http-server)
npm install -g http-server
cd dist && http-server -p 8000

# 访问地址
# http://localhost:8000
```

---

## 8. 故障排查

### 8.1 构建问题

#### 问题1: `javascript-obfuscator` 报错

**错误信息:**

```
error: unknown option '--rotate-string-array'
```

**解决方案:**

```bash
# 检查 obfuscate-config.json 是否使用了 MacBook 兼容版本
cat obfuscate-config.json

# 确保没有这些不兼容的参数：
# - rotateStringArray
# - stringArrayEncoding
# - stringArrayCallsTransform
```

#### 问题2: `terser` 参数错误

**错误信息:**

```
TypeError: Cannot create property 'drop_console=true' on boolean 'true'
```

**解决方案:**

```bash
# 检查 build.sh 中的 terser 命令
# 应该是：
terser input.js -o output.js -c drop_console=true,drop_debugger=true -m

# 不是：
terser input.js -o output.js -c -m --compress drop_console=true
```

#### 问题3: `sed` 命令在 MacBook 上报错

**错误信息:**

```
sed: 1: "dist/index.html": extra characters at the end of d command
```

**解决方案:**

```bash
# MacBook (BSD sed) 需要加空字符串参数
sed -i '' 's/xxx/yyy/g' dist/index.html

# Linux (GNU sed) 不需要
sed -i 's/xxx/yyy/g' dist/index.html
```

### 8.2 部署问题

#### 问题1: OSS 访问被拒绝

**错误信息:**

```
Error Code: AccessDenied.
The bucket you access does not belong to you.
```

**解决方案:**

```bash
# 1. 检查 bucket 名称是否正确
ossutil ls

# 2. 重新配置 ossutil
ossutil config

# 3. 检查 AccessKey 权限
# 确保 AccessKey 有 OSS 读写权限
```

#### 问题2: 配置文件找不到

**错误信息:**

```
错误: 找不到 oss-config.sh 配置文件
```

**解决方案:**

```bash
# 复制配置文件模板
cp oss-config.sh.example oss-config.sh

# 编辑配置
vim oss-config.sh
```

#### 问题3: 上传失败

**错误信息:**

```
Error: operation error PutObject
```

**解决方案:**

```bash
# 1. 检查网络连接
ping oss-cn-beijing.aliyuncs.com

# 2. 检查 bucket 是否存在
ossutil ls oss://your-bucket/

# 3. 检查剩余存储空间
ossutil du oss://your-bucket/

# 4. 尝试手动上传单个文件
ossutil cp dist/index.html oss://your-bucket/test/
```

### 8.3 访问问题

#### 问题1: 404 Not Found

**可能原因:**

* 部署路径错误
* 文件未上传成功
* bucket 不存在

**解决方案:**

```bash
# 1. 确认文件已上传
ossutil ls oss://bucket/h5/v8/ -r

# 2. 检查访问地址是否正确
# 正确格式：https://bucket.oss-cn-beijing.aliyuncs.com/h5/v8/

# 3. 检查 bucket 权限
ossutil set-acl oss://bucket/h5/v8/ public-read -r
```

#### 问题2: 403 Forbidden

**可能原因:**

* bucket 未设置公共读权限
* Referer 防盗链限制

**解决方案:**

```bash
# 设置公共读权限
ossutil set-acl oss://bucket/h5/v8/ public-read -r

# 在阿里云控制台检查：
# 1. Bucket 权限设置
# 2. 防盗链设置（Referer 白名单）
# 3. 跨域设置（CORS）
```

#### 问题3: 缓存问题

**现象:**
修改了代码，但访问时还是旧版本

**解决方案:**

```bash
# 方法1: 在 URL 后加时间戳
https://bucket.com/h5/v8/?t=20240315143022

# 方法2: 清除 OSS 文件后重新上传
./deploy-oss.sh h5/v8
# 选择 "y" 删除旧文件

# 方法3: 修改文件名（如使用 hash）
# styles-v3.2.1.css → styles-v3.2.1.abc123.css

# 方法4: 使用 CDN 刷新
# 在阿里云 CDN 控制台手动刷新 URL
```

---

## 9. 最佳实践

### 9.1 开发流程

```
1. 开发
   ├─ 修改源代码 (assets/)
   └─ 本地测试 (python3 -m http.server)

2. 测试
   ├─ 构建项目 (./build.sh)
   ├─ 部署到测试环境 (./deploy.sh h5/test)
   └─ 测试验证

3. 预发布
   ├─ 部署到预发布环境 (./deploy.sh h5/staging)
   └─ 全面测试

4. 生产
   ├─ 部署到生产环境 (./deploy.sh h5/prod)
   └─ 监控

5. 备份
   └─ 定期清理旧备份 (./clean-backups.sh)
```

### 9.2 版本管理

#### 推荐的版本命名方式

```bash
# 语义化版本
./deploy.sh h5/v1.0.0      # 主版本.次版本.修订号
./deploy.sh h5/v1.0.1
./deploy.sh h5/v1.1.0

# 日期版本
./deploy.sh h5/20240315
./deploy.sh h5/2024-03-15

# 环境版本
./deploy.sh h5/dev         # 开发
./deploy.sh h5/test        # 测试
./deploy.sh h5/staging     # 预发布
./deploy.sh h5/prod        # 生产
```

#### Git 版本管理

```bash
# 创建 .gitignore
cat > .gitignore << 'EOF'
dist/
oss-config.sh
node_modules/
*.log
.DS_Store
EOF

# 提交代码
git add .
git commit -m "feat: 添加新功能"
git push

# 创建标签
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

### 9.3 安全建议

#### 9.3.1 保护敏感信息

```bash
# 1. 不要将 oss-config.sh 提交到 git
echo "oss-config.sh" >> .gitignore

# 2. 使用 RAM 子账号（限制权限）
# 在阿里云 RAM 控制台创建子账号
# 只授予必要的 OSS 权限

# 3. 定期轮换 AccessKey
# 建议每 90 天更换一次

# 4. 启用 MFA（多因素认证）
```

#### 9.3.2 访问控制

```bash
# 1. 设置 Referer 防盗链
# 在阿里云 OSS 控制台设置白名单
# 例如：*.yourdomain.com

# 2. 使用私有 bucket + 签名 URL
# 对于敏感资源，不使用公共读

# 3. 启用 CDN 鉴权
# 对于重要资源启用 URL 鉴权
```

### 9.4 性能优化

#### 9.4.1 文件压缩

```bash
# 1. 启用 Gzip 压缩（OSS 自动支持）
# 客户端请求时带 Accept-Encoding: gzip 即可

# 2. 图片优化
# 使用 imagemin 压缩图片
npm install -g imagemin-cli
imagemin media/images/* --out-dir=media/images/

# 3. 使用 WebP 格式
# 在支持的浏览器使用 WebP
```

#### 9.4.2 缓存策略

```bash
# 在 oss-config.sh 中设置：
export OSS_CACHE_CONTROL="max-age=31536000"        # 静态资源缓存 1 年
export OSS_HTML_CACHE_CONTROL="max-age=600"        # HTML 缓存 10 分钟

# 或在上传时指定：
ossutil cp file.js oss://bucket/path/ \
    --meta "Cache-Control:max-age=31536000"
```

#### 9.4.3 CDN 加速

```bash
# 1. 在阿里云 CDN 控制台添加加速域名
# 2. 配置 CNAME 解析
# 3. 在 oss-config.sh 中配置 CDN 域名
export OSS_CDN_DOMAIN="https://cdn.yourdomain.com"
```

### 9.5 监控和日志

#### 9.5.1 访问日志

```bash
# 在阿里云 OSS 控制台启用日志存储
# 日志会保存到指定的 bucket

# 下载日志分析
ossutil cp -r oss://log-bucket/logs/ ./logs/

# 分析访问量
cat logs/* | grep "GET" | wc -l
```

#### 9.5.2 告警设置

```bash
# 在阿里云云监控设置告警规则：
# 1. OSS 下行流量超过阈值
# 2. OSS 请求次数超过阈值
# 3. 4xx/5xx 错误率超过阈值
```

---

## 10. FAQ

### Q1: 如何修改好多粉的统计ID？

**A:** 编辑 `index.html`，找到：

```html
<script type="text/javascript" src="//res.hduofen.cn/js/zaaxstat.js?id=lWaxBLZD"></script>
```

修改 `id` 参数为你的统计ID。

---

### Q2: 如何自定义问题流程？

**A:** 编辑 `assets/js/core-7f2a3b4c.js`，找到 `ConsultationFlowData`：

```javascript
const ConsultationFlowData = [
    {
        stageKey: "debt_amount",
        promptText: "您的债务总额是多少?",
        selectionOptions: [
            { optionId: "DA001", labelText: "5万以下" },
            // 添加更多选项...
        ]
    },
    // 添加更多问题...
];
```

---

### Q3: 如何修改律师信息？

**A:** 编辑 `index.html`，找到律师简介卡片部分：

```html
<div class="profile-card-section">
    <div class="advisor-portrait">
        <img src="./media/images/advisor-portrait-001.jpg" alt="律师头像">
    </div>
    <div class="profile-details">
        <p class="advisor-name">
            刘律师
            <span>专长债务协商咨询</span>
        </p>
        <!-- 修改这里的内容 -->
    </div>
</div>
```

---

### Q4: 如何更换图片资源？

**A:**

```bash
# 1. 替换图片文件
cp new-avatar.jpg media/images/advisor-portrait-001.jpg

# 2. 重新构建
./build.sh

# 3. 部署
./deploy.sh
```

---

### Q5: 如何回滚到之前的版本？

**A:**

```bash
# 1. 查看备份列表
ossutil ls oss://bucket/ | grep "_backup_"

# 2. 恢复备份
ossutil cp -r oss://bucket/h5/v8_backup_20240315_143022/ \
    oss://bucket/h5/v8/ --update -f

# 3. 验证
curl https://bucket.oss-cn-beijing.aliyuncs.com/h5/v8/
```

---

### Q6: 构建很慢怎么办？

**A:** 混淆过程较慢是正常的，可以：

```bash
# 1. 开发时跳过混淆，只压缩
# 直接使用 terser 而不是 javascript-obfuscator
terser assets/js/core-7f2a3b4c.js -o dist/assets/js/core-7f2a3b4c.min.js -c -m

# 2. 生产部署时再完整构建
./build.sh
```

---

### Q7: 如何部署到多个环境？

**A:**

```bash
# 方法1: 不同的部署路径
./deploy.sh h5/dev
./deploy.sh h5/test
./deploy.sh h5/prod

# 方法2: 不同的配置文件
cp oss-config.sh oss-config-dev.sh
cp oss-config.sh oss-config-prod.sh

# 编辑 deploy-oss.sh，根据参数加载不同配置
if [ "$1" = "prod" ]; then
    source oss-config-prod.sh
else
    source oss-config-dev.sh
fi
```

---

### Q8: 如何查看混淆后的代码效果？

**A:**

```bash
# 查看混淆后的代码
cat dist/assets/js/core-7f2a3b4c.min.js

# 对比混淆前后
echo "=== 原始代码 ==="
head -n 20 assets/js/core-7f2a3b4c.js

echo "=== 混淆后 ==="
head -n 20 dist/assets/js/core-7f2a3b4c.min.js
```

---

### Q9: 部署后无法访问怎么办？

**A:** 按顺序检查：

```bash
# 1. 检查文件是否上传成功
ossutil ls oss://bucket/h5/v8/ -r

# 2. 检查 bucket 权限
ossutil stat oss://bucket/h5/v8/index.html

# 3. 设置公共读权限
ossutil set-acl oss://bucket/h5/v8/ public-read -r

# 4. 测试直接访问
curl -I https://bucket.oss-cn-beijing.aliyuncs.com/h5/v8/index.html

# 5. 检查防火墙/安全组规则
```

---

### Q10: 如何添加新的页面？

**A:**

```bash
# 1. 创建新的 HTML 文件
cp index.html page2.html

# 2. 修改 build.sh，添加对新页面的处理
# 在压缩 HTML 步骤添加：
html-minifier page2.html -o dist/page2.html ...

# 3. 构建和部署
./build.sh
./deploy.sh

# 4. 访问新页面
# https://bucket.com/h5/v8/page2.html
```

---

## 附录

### A. OSS 区域节点列表

| 区域       | Endpoint                          |
| -------- | --------------------------------- |
| 华东1（杭州）  | `oss-cn-hangzhou.aliyuncs.com`    |
| 华东2（上海）  | `oss-cn-shanghai.aliyuncs.com`    |
| 华北1（青岛）  | `oss-cn-qingdao.aliyuncs.com`     |
| 华北2（北京）  | `oss-cn-beijing.aliyuncs.com`     |
| 华北3（张家口） | `oss-cn-zhangjiakou.aliyuncs.com` |
| 华南1（深圳）  | `oss-cn-shenzhen.aliyuncs.com`    |
| 华南2（河源）  | `oss-cn-heyuan.aliyuncs.com`      |
| 西南1（成都）  | `oss-cn-chengdu.aliyuncs.com`     |
| 中国香港     | `oss-cn-hongkong.aliyuncs.com`    |

完整列表：[https://help.aliyun.com/document\_detail/31837.html](https://help.aliyun.com/document_detail/31837.html)

### B. 常用 MIME 类型

| 文件扩展名   | Content-Type               |
| ------- | -------------------------- |
| `.html` | `text/html; charset=utf-8` |
| `.css`  | `text/css`                 |
| `.js`   | `application/javascript`   |
| `.json` | `application/json`         |
| `.jpg`  | `image/jpeg`               |
| `.png`  | `image/png`                |
| `.gif`  | `image/gif`                |
| `.svg`  | `image/svg+xml`            |
| `.webp` | `image/webp`               |

### C. 参考链接

* [阿里云 OSS 官方文档](https://help.aliyun.com/product/31815.html)
* [ossutil 使用文档](https://help.aliyun.com/document_detail/120075.html)
* [JavaScript Obfuscator](https://github.com/javascript-obfuscator/javascript-obfuscator)
* [Terser 文档](https://terser.org/docs/)
* [好多粉官网](https://www.hduofen.cn/)

---

## 更新日志

### v2.0.4 (2024-03-15)

* ✅ 完善 MacBook 兼容性
* ✅ 优化部署脚本错误处理
* ✅ 添加完整的使用手册

### v2.0.3 (2024-03-14)

* ✅ 修复 sed 命令 MacBook 兼容问题
* ✅ 修复 terser 参数错误
* ✅ 优化混淆配置

### v2.0.0 (2024-03-10)

* ✅ 完全重构代码
* ✅ 添加代码混淆和压缩
* ✅ 集成阿里云 OSS 部署
* ✅ 优化好多粉统计兼容性

---

## 联系方式

如有问题，请联系：

* 技术支持邮箱：[wayfarer_x@foxmail.com](mailto:wayfarer_x@foxmail.com)
* 项目地址：[https://github.com/irtb/legal-consultation-h5](https://github.com/irtb/legal-consultation-h5)

---

**最后更新时间**: 2024-03-15 14:30:00
**文档版本**: v2.0.4
