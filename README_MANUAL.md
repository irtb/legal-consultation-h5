````markdown
# H5项目构建和部署使用手册

> 版本：v3.1.0  
> 更新日期：2024-11-26  
> 适用平台：MacBook / Linux

---

## 📋 目录

- [1. 项目简介](#1-项目简介)
- [2. 环境要求](#2-环境要求)
- [3. 快速开始](#3-快速开始)
- [4. 目录结构](#4-目录结构)
- [5. 构建流程](#5-构建流程)
- [6. 部署流程](#6-部署流程)
- [7. 备份管理](#7-备份管理)
- [8. CDN 刷新](#8-cdn-刷新)
- [9. 常用命令](#9-常用命令)
- [10. 故障排查](#10-故障排查)
- [11. 最佳实践](#11-最佳实践)
- [12. FAQ](#12-faq)

---

## 1. 项目简介

### 1.1 项目概述

本项目是一个法律咨询H5页面，主要功能包括：
- 债务咨询问答流程
- 企业微信加粉引流
- 好多粉统计集成
- 响应式移动端适配

### 1.2 技术栈

| 技术 | 版本 | 说明 |
|------|------|------|
| jQuery | 2.1.5 | JavaScript库 |
| 好多粉统计 | Latest | zaaxstat.js |
| 阿里云OSS | - | 静态资源托管 |
| JavaScript Obfuscator | Latest | 代码混淆 |
| Terser | Latest | 代码压缩 |
| CleanCSS | Latest | CSS压缩 |
| HTML Minifier | Latest | HTML压缩 |

### 1.3 浏览器兼容性

- ✅ iOS Safari 10+
- ✅ Android Chrome 60+
- ✅ 微信内置浏览器
- ✅ 企业微信

---

## 2. 环境要求

### 2.1 系统要求

- **MacBook**: macOS 10.15+
- **Linux**: Ubuntu 18.04+ / CentOS 7+
- **Node.js**: 14.0+
- **Python**: 3.6+ (用于本地测试服务器)

### 2.2 必需工具安装

#### 2.2.1 安装 Node.js 工具

```bash
# 安装构建和压缩工具
npm install -g terser
npm install -g clean-css-cli
npm install -g html-minifier
npm install -g javascript-obfuscator
````

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

#### 2.2.4 安装 aliyun CLI（可选，用于CDN刷新）

```bash
# 使用 pip 安装
pip3 install aliyun-python-sdk-core
pip3 install aliyun-python-sdk-cdn

# 配置
aliyun configure
# 按提示输入 Access Key ID 和 Secret
```

---

## 3. 快速开始

### 3.1 克隆或下载项目

```bash
# 如果是 git 项目
git clone https://github.com/irtb/legal-consultation-h5.git
cd legal-consultation-h5

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
# export OSS_CDN_DOMAIN="https://your-cdn.com"  # 可选
```

### 3.3 首次构建

```bash
# 赋予脚本执行权限
chmod +x build.sh
chmod +x deploy-oss.sh
chmod +x deploy.sh
chmod +x backup-manager.sh

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
./deploy.sh tct
```

---

## 4. 目录结构

### 4.1 本地目录结构

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
├── deploy-oss.sh                    # OSS 部署脚本（带自动回滚）
├── backup-manager.sh                # 备份管理工具
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

### 4.2 OSS 存储结构

```
lp-bjzhwx-net/                       # Bucket
│
├── tct/                             # 实际部署目录
│   ├── index.html
│   ├── assets/
│   │   ├── css/
│   │   │   └── styles-v3.2.1.min.css
│   │   └── js/
│   │       ├── core-7f2a3b4c.min.js
│   │       └── framework-2.1.5.min.js
│   └── media/
│       ├── images/
│       └── animations/
│
├── .backups/                        # 统一备份目录（v3.1 新增）
│   ├── tct/                         # 项目 tct 的所有备份
│   │   ├── 20251126_170755/        # 备份1（时间戳）
│   │   │   ├── index.html
│   │   │   ├── assets/
│   │   │   └── media/
│   │   ├── 20251126_173000/        # 备份2
│   │   └── 20251127_091500/        # 备份3
│   │
│   ├── another-project/             # 其他项目的备份
│   │   ├── 20251126_180000/
│   │   └── 20251127_100000/
│   │
│   └── h5-v2/                       # 更多项目...
│       └── 20251127_120000/
│
└── other-projects/                  # 其他部署项目
    └── ...
```

---

## 5. 构建流程

### 5.1 构建命令

```bash
./build.sh
```

### 5.2 构建步骤详解

| 步骤 | 操作        | 输入                             | 输出                                      | 说明                       |
| -- | --------- | ------------------------------ | --------------------------------------- | ------------------------ |
| 1  | 创建目录      | -                              | `dist/` 目录结构                            | 清理旧文件，创建新结构              |
| 2  | 压缩 CSS    | `assets/css/styles-v3.2.1.css` | `dist/assets/css/styles-v3.2.1.min.css` | 使用 cleancss              |
| 3  | 混淆 JS     | `assets/js/core-7f2a3b4c.js`   | `dist/assets/js/core-7f2a3b4c.tmp.js`   | 使用 javascript-obfuscator |
| 4  | 压缩 JS     | `core-7f2a3b4c.tmp.js`         | `dist/assets/js/core-7f2a3b4c.min.js`   | 使用 terser                |
| 5  | 复制 jQuery | `framework-2.1.5.min.js`       | `dist/assets/js/framework-2.1.5.min.js` | 直接复制                     |
| 6  | 压缩 HTML   | `index.html`                   | `dist/index.html`                       | 使用 html-minifier         |
| 7  | 复制媒体      | `media/*`                      | `dist/media/*`                          | 图片和动画                    |
| 8  | 更新引用      | `dist/index.html`              | 路径指向 `.min` 文件                          | 使用 sed                   |

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
  原始: 6.73 KB
  压缩: 4.39 KB
  节省: 2.33 KB

CSS:
  原始: 19.27 KB
  压缩: 12.20 KB
  节省: 7.07 KB

JavaScript:
  原始: 21.15 KB
  混淆压缩: 36.48 KB
  节省: -15.33 KB  # 混淆后体积增加是正常的

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

```bash
# 部署到默认路径（oss-config.sh 中的 OSS_BASE_PATH）
./deploy.sh

# 部署到自定义路径
./deploy.sh tct                    # 部署到 tct/
./deploy.sh h5/test                # 部署到 h5/test/
./deploy.sh projects/legal/v1.0.0  # 部署到 projects/legal/v1.0.0/
```

### 6.2 部署步骤详解

| 步骤     | 操作    | 说明                          |
| ------ | ----- | --------------------------- |
| \[1/7] | 构建项目  | 自动调用 `build.sh`，验证构建产物      |
| \[2/7] | 创建备份  | 备份到 `.backups/{项目名}/{时间戳}/` |
| \[3/7] | 验证备份  | 确保备份文件数量与原文件一致              |
| \[4/7] | 清理旧文件 | 询问是否删除 OSS 上的旧文件            |
| \[5/7] | 上传新文件 | 分别上传 HTML、CSS、JS、图片、动画 |
| \[5.5/7] | 设置缓存 | 配置 HTTP 缓存策略 |
| \[6/7] | 验证部署 | 检查关键文件是否存在 |
| \[7/7] | 刷新 CDN | 自动或手动刷新 CDN 缓存（可选）|

### 6.3 自动回滚机制 🔄

部署过程中任何步骤失败都会自动回滚：

```

部署失败触发条件:
├─ 构建失败 → 终止，不影响线上
├─ 备份失败 → 询问是否继续（无备份保护）
├─ 上传失败 → 自动回滚到备份
├─ 验证失败 → 自动回滚到备份
└─ 用户中断 (Ctrl+C) → 自动回滚

```

**回滚流程:**
1. 删除失败的部署文件
2. 从备份恢复原文件
3. 询问是否保留备份

### 6.4 部署输出示例

```

\================================
阿里云 OSS 部署脚本 v3.1.0
===================

部署配置:
Bucket: lp-bjzhwx-net
Endpoint: oss-cn-beijing.aliyuncs.com
部署路径: tct
备份目录: .backups
本地目录: dist/
CDN 域名: [https://cdn.example.com](https://cdn.example.com)

确认部署？(y/n) y

\[1/7] 构建项目...
✓ 构建完成并验证通过

\[2/7] 创建当前版本备份...
→ 发现现有文件 (7 个对象)
→ 创建备份到: .backups/tct/20251126\_170755
✓ 备份完成

\[3/7] 验证备份完整性...
✓ 备份验证通过 (7/7 文件)

\[4/7] 清理旧文件...
是否删除 OSS 上的旧文件？(y/n) y
✓ 旧文件已删除

\[5/7] 上传文件到 OSS...
→ 上传 HTML 文件...
→ 上传 CSS 文件...
→ 上传 JS 文件...
→ 上传图片文件...
→ 上传动画文件...
✓ 所有文件上传完成

\[5.5/7] 设置文件缓存策略...
→ HTML 缓存已设置
→ 静态资源缓存已设置
→ 媒体文件缓存已设置
✓ 缓存策略配置完成

\[6/7] 验证部署完整性...
✓ 部署验证通过，共 7 个对象
→ 验证关键文件...
✓ index.html
✓ CSS 文件 (1 个)
✓ JS 文件 (2 个)
✓ 关键文件验证通过

\[7/7] 刷新 CDN 缓存
是否刷新 CDN 缓存？(y/n) y
→ 使用 aliyun CLI 刷新 CDN...
✓ CDN 刷新请求已提交
→ 刷新通常需要 5-10 分钟生效

\================================
✓ 部署成功！
=======

访问地址:
CDN: [https://cdn.example.com/tct/](https://cdn.example.com/tct/)
(CDN 刷新通常需要 5-10 分钟生效)
OSS: [https://lp-bjzhwx-net.oss-cn-beijing.aliyuncs.com/tct/](https://lp-bjzhwx-net.oss-cn-beijing.aliyuncs.com/tct/)

备份信息:
路径: .backups/tct/20251126\_170755
原文件数: 7
新文件数: 7

文件统计:
HTML: 1 个
CSS: 1 个
JS: 2 个
图片: 2 个
动画: 1 个

常用命令:
查看文件: ossutil ls oss\://lp-bjzhwx-net/tct/ -r
查看备份: ossutil ls oss\://lp-bjzhwx-net/.backups/tct/
手动回滚: ossutil cp -r oss\://lp-bjzhwx-net/.backups/tct/20251126\_170755/ oss\://lp-bjzhwx-net/tct/ --update -f
备份管理: ./backup-manager.sh

清理备份
备份路径: .backups/tct/20251126\_170755
是否删除本次备份？(y/n) n
备份已保留

部署流程完成！

````

### 6.5 部署场景示例

#### 场景1：开发环境测试

```bash
# 1. 修改代码
vim assets/js/core-7f2a3b4c.js

# 2. 部署到测试环境
./deploy.sh h5/dev

# 3. 访问测试地址
# https://your-bucket.oss-cn-beijing.aliyuncs.com/h5/dev/
````

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

## 7. 备份管理

### 7.1 备份管理工具

```bash
./backup-manager.sh
```

### 7.2 功能菜单

```
================================
OSS 备份管理工具 v2.0
================================

请选择操作:
  1) 列出所有备份
  2) 列出指定项目的备份
  3) 查看备份详情
  4) 恢复备份
  5) 删除指定备份
  6) 清理旧备份
  7) 备份统计
  8) 退出

选择 [1-8]:
```

### 7.3 常用操作

#### 7.3.1 列出所有备份

```bash
# 选择 1
================================
所有项目备份列表
================================

📁 项目: tct
  └─ 20251126_170755 (7 个文件)
  └─ 20251126_173000 (7 个文件)
  └─ 20251127_091500 (7 个文件)

📁 项目: another-project
  └─ 20251126_180000 (12 个文件)
  └─ 20251127_100000 (12 个文件)
```

#### 7.3.2 列出指定项目的备份

```bash
# 选择 2
输入项目名称（如: tct）: tct

================================
项目 tct 的备份列表
================================

  • 20251127 091500 (7 个文件)
  • 20251126 173000 (7 个文件)
  • 20251126 170755 (7 个文件)
```

#### 7.3.3 恢复备份

```bash
# 选择 4
输入项目名称（如: tct）: tct

项目 tct 的备份列表:
  1. .backups/tct/20251127_091500/
  2. .backups/tct/20251126_173000/
  3. .backups/tct/20251126_170755/

输入要恢复的备份时间戳（如: 20251126_170755）: 20251126_170755

恢复配置:
  从: .backups/tct/20251126_170755
  到: tct

确认恢复？(y/n) y
创建临时备份: .backups/tct/temp_20251127_110000
清空目标路径...
恢复备份...
✓ 恢复完成
是否删除临时备份？(y/n) n
```

#### 7.3.4 清理旧备份

```bash
# 选择 6
输入项目名称（如: tct，留空表示所有项目）: tct
保留最近几个备份？[默认5]: 3

保留最近 3 个备份，删除其余...

处理项目: tct
  保留: .backups/tct/20251127_091500
  保留: .backups/tct/20251126_173000
  保留: .backups/tct/20251126_170755
  删除: .backups/tct/20251125_140000
  删除: .backups/tct/20251124_120000

✓ 清理完成
```

#### 7.3.5 查看备份详情

```bash
# 选择 3
输入项目名称（如: tct）: tct
输入备份时间戳（如: 20251126_170755）: 20251126_170755

================================
备份详情
================================
  项目: tct
  时间: 20251126_170755
  路径: .backups/tct/20251126_170755

文件列表:
oss://bucket/.backups/tct/20251126_170755/index.html
oss://bucket/.backups/tct/20251126_170755/assets/css/styles-v3.2.1.min.css
oss://bucket/.backups/tct/20251126_170755/assets/js/core-7f2a3b4c.min.js
oss://bucket/.backups/tct/20251126_170755/assets/js/framework-2.1.5.min.js
oss://bucket/.backups/tct/20251126_170755/media/images/advisor-portrait-001.jpg
oss://bucket/.backups/tct/20251126_170755/media/images/info-banner.jpg
oss://bucket/.backups/tct/20251126_170755/media/animations/gesture-indicator.gif
```

#### 7.3.6 备份统计

```bash
# 选择 7
================================
备份统计信息
================================

统计中...
storage class   object count            sum size(byte)
Standard        42                      1,234,567

总备份数: 42 个文件/目录

各项目备份统计:
  tct: 3 个备份
  another-project: 2 个备份
  h5-v2: 1 个备份
```

### 7.4 手动备份操作

```bash
# 手动创建备份
ossutil cp -r oss://lp-bjzhwx-net/tct/ \
    oss://lp-bjzhwx-net/.backups/tct/manual_$(date +%Y%m%d_%H%M%S)/ \
    --update

# 手动恢复备份
ossutil cp -r oss://lp-bjzhwx-net/.backups/tct/20251126_170755/ \
    oss://lp-bjzhwx-net/tct/ \
    --update -f

# 手动删除备份
ossutil rm oss://lp-bjzhwx-net/.backups/tct/20251126_170755/ -r -f
```

---

## 8. CDN 刷新

### 8.1 自动刷新（需要 aliyun CLI）

部署时会自动询问是否刷新 CDN：

```bash
[7/7] 刷新 CDN 缓存
是否刷新 CDN 缓存？(y/n) y
  → 使用 aliyun CLI 刷新 CDN...
✓ CDN 刷新请求已提交
  → 刷新通常需要 5-10 分钟生效
```

### 8.2 手动刷新

#### 8.2.1 方法1: 阿里云控制台

1. 访问：[https://cdn.console.aliyun.com/refresh](https://cdn.console.aliyun.com/refresh)
2. 选择「刷新缓存」
3. 选择刷新类型：「目录」
4. 输入 URL：`https://cdn.example.com/tct/`
5. 点击「提交」

#### 8.2.2 方法2: 使用 aliyun CLI

```bash
# 刷新目录
aliyun cdn RefreshObjectCaches \
    --ObjectPath="https://cdn.example.com/tct/" \
    --ObjectType=Directory

# 刷新具体文件
aliyun cdn RefreshObjectCaches \
    --ObjectPath="https://cdn.example.com/tct/index.html,https://cdn.example.com/tct/assets/css/styles-v3.2.1.min.css" \
    --ObjectType=File

# 查询刷新任务状态
aliyun cdn DescribeRefreshTasks
```

#### 8.2.3 方法3: 预热（提前加载到CDN节点）

```bash
# 预热常用文件
aliyun cdn PushObjectCache \
    --ObjectPath="https://cdn.example.com/tct/index.html,https://cdn.example.com/tct/assets/js/core-7f2a3b4c.min.js"
```

### 8.3 CDN 配置建议

#### 8.3.1 缓存规则

| 文件类型   | 缓存时间 | 说明            |
| ------ | ---- | ------------- |
| HTML   | 10分钟 | 方便快速更新内容      |
| CSS/JS | 1年   | 文件名带版本号，可长期缓存 |
| 图片     | 1年   | 静态资源，长期缓存     |

#### 8.3.2 配置示例

在 `oss-config.sh` 中：

```bash
export OSS_HTML_CACHE_CONTROL="max-age=600"        # 10分钟
export OSS_CACHE_CONTROL="max-age=31536000"        # 1年
```

---

## 9. 常用命令

### 9.1 构建相关

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

# 检查混淆效果

head -n 50 dist/assets/js/core-7f2a3b4c.min.js

````

### 9.2 部署相关

```bash
# 部署到默认路径
./deploy.sh

# 部署到指定路径
./deploy.sh tct
./deploy.sh h5/test
./deploy.sh projects/legal/v1.0.0

# 只上传不构建（不推荐，仅调试用）
ossutil cp -r dist/ oss://bucket/path/ --update -f
````

### 9.3 OSS 文件管理

```bash
# 查看 bucket 列表
ossutil ls

# 查看指定路径的文件
ossutil ls oss://bucket/tct/
ossutil ls oss://bucket/tct/ -r              # 递归显示所有文件

# 查看文件详情
ossutil stat oss://bucket/tct/index.html

# 下载文件
ossutil cp oss://bucket/tct/index.html ./

# 下载整个目录
ossutil cp -r oss://bucket/tct/ ./local-backup/

# 删除文件
ossutil rm oss://bucket/tct/index.html

# 删除目录
ossutil rm oss://bucket/tct/ -r -f

# 同步目录（本地→OSS）
ossutil sync dist/ oss://bucket/tct/

# 计算目录大小
ossutil du oss://bucket/tct/
```

### 9.4 备份管理

```bash
# 启动备份管理工具
./backup-manager.sh

# 查看所有备份
ossutil ls oss://bucket/.backups/ -r

# 查看指定项目的备份
ossutil ls oss://bucket/.backups/tct/

# 手动创建备份
ossutil cp -r oss://bucket/tct/ \
    oss://bucket/.backups/tct/$(date +%Y%m%d_%H%M%S)/ \
    --update

# 恢复指定备份
ossutil cp -r oss://bucket/.backups/tct/20251126_170755/ \
    oss://bucket/tct/ \
    --update -f

# 删除指定备份
ossutil rm oss://bucket/.backups/tct/20251126_170755/ -r -f

# 清理7天前的备份
find_date=$(date -v-7d +%Y%m%d)  # MacBook
# find_date=$(date -d "7 days ago" +%Y%m%d)  # Linux
ossutil ls oss://bucket/.backups/tct/ | \
    grep -E "[0-9]{8}_[0-9]{6}" | \
    awk -v date="$find_date" '$0 < date {print}' | \
    xargs -I {} ossutil rm oss://bucket/{} -r -f
```

### 9.5 缓存管理

```bash
# 查看文件的缓存设置
ossutil stat oss://bucket/tct/index.html | grep Cache-Control

# 设置单个文件的缓存
ossutil set-meta oss://bucket/tct/index.html \
    Cache-Control:max-age=600 -f

# 设置目录的缓存（递归）
ossutil set-meta oss://bucket/tct/assets/ \
    Cache-Control:max-age=31536000 -r -f

# 清除缓存设置
ossutil set-meta oss://bucket/tct/index.html \
    Cache-Control: -f
```

### 9.6 本地测试

```bash
# 方法1: Python
cd dist && python3 -m http.server 8000

# 方法2: PHP
cd dist && php -S localhost:8000

# 方法3: Node.js (需要安装 http-server)
npm install -g http-server
cd dist && http-server -p 8000

# 方法4: MacBook 自带的 SimpleHTTPServer (Python 2)
cd dist && python -m SimpleHTTPServer 8000

# 访问地址
# http://localhost:8000
```

### 9.7 CDN 管理

```bash
# 刷新 CDN 目录
aliyun cdn RefreshObjectCaches \
    --ObjectPath="https://cdn.example.com/tct/" \
    --ObjectType=Directory

# 刷新指定文件
aliyun cdn RefreshObjectCaches \
    --ObjectPath="https://cdn.example.com/tct/index.html" \
    --ObjectType=File

# 预热文件（提前加载到CDN）
aliyun cdn PushObjectCache \
    --ObjectPath="https://cdn.example.com/tct/index.html"

# 查询刷新任务
aliyun cdn DescribeRefreshTasks

# 查询预热任务
aliyun cdn DescribeRefreshQuota
```

---

## 10. 故障排查

### 10.1 构建问题

#### 问题1: `javascript-obfuscator` 报错

**错误信息:**

```
error: unknown option '--rotate-string-array'
```

**原因:** 使用了不兼容的混淆选项

**解决方案:**

```bash
# 检查 obfuscate-config.json
cat obfuscate-config.json

# 确保使用兼容的配置
# 移除以下不兼容的选项：
# - rotateStringArray
# - stringArrayEncoding
# - stringArrayCallsTransform
```

#### 问题2: `terser` 参数错误

**错误信息:**

```
TypeError: Cannot create property 'drop_console=true' on boolean 'true'
```

**原因:** terser 参数格式错误

**解决方案:**

```bash
# 正确的 terser 命令格式：
terser input.js -o output.js -c drop_console=true,drop_debugger=true -m

# 错误格式：
# terser input.js -o output.js -c -m --compress drop_console=true
```

#### 问题3: `sed` 命令在 MacBook 上报错

**错误信息:**

```
sed: 1: "dist/index.html": extra characters at the end of d command
```

**原因:** MacBook 使用 BSD sed，需要不同的语法

**解决方案:**

```bash
# MacBook (BSD sed) 需要加空字符串参数
sed -i '' 's/xxx/yyy/g' dist/index.html

# Linux (GNU sed) 不需要
sed -i 's/xxx/yyy/g' dist/index.html
```

### 10.2 部署问题

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
# 在阿里云 RAM 控制台检查策略
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

# 检查文件权限
chmod 644 oss-config.sh
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

# 5. 检查文件大小限制（单个文件 < 5GB）
ls -lh dist/
```

#### 问题4: 部署后自动回滚

**场景:** 部署过程中出现错误，自动触发回滚

**处理步骤:**

```bash
# 1. 查看错误信息，确定失败原因
# 2. 检查备份是否保留
ossutil ls oss://bucket/.backups/tct/

# 3. 修复问题后重新部署
./deploy.sh tct

# 4. 如果需要手动恢复某个备份
./backup-manager.sh
# 选择 4) 恢复备份
```

### 10.3 访问问题

#### 问题1: 404 Not Found

**可能原因:**

* 部署路径错误
* 文件未上传成功
* 访问 URL 错误

**解决方案:**

```bash
# 1. 确认文件已上传
ossutil ls oss://bucket/tct/ -r

# 2. 检查访问地址格式
# 正确: https://bucket.oss-cn-beijing.aliyuncs.com/tct/
# 错误: https://bucket.oss-cn-beijing.aliyuncs.com/tct  (少了斜杠)

# 3. 检查 index.html 是否存在
ossutil stat oss://bucket/tct/index.html

# 4. 测试直接访问文件
curl -I https://bucket.oss-cn-beijing.aliyuncs.com/tct/index.html
```

#### 问题2: 403 Forbidden

**可能原因:**

* Bucket 权限设置
* Referer 防盗链
* IP 白名单

**解决方案:**

```bash
# 1. 在阿里云控制台检查：
#    - Bucket 权限设置（应该是公共读或自定义）
#    - 防盗链设置（Referer 白名单）
#    - 跨域设置（CORS）

# 2. 测试是否是防盗链问题
curl -H "Referer: https://yourdomain.com" \
    https://bucket.oss-cn-beijing.aliyuncs.com/tct/index.html

# 3. 临时禁用防盗链测试
# 在控制台 → 数据安全 → 防盗链 → 清空白名单
```

#### 问题3: 缓存问题

**现象:** 修改了代码，但访问时还是旧版本

**解决方案:**

```bash
# 方法1: 浏览器强制刷新
# Chrome/Firefox: Cmd+Shift+R (Mac) 或 Ctrl+Shift+R (Windows)
# Safari: Cmd+Option+E (清除缓存) + Cmd+R

# 方法2: 在 URL 后加时间戳
https://bucket.com/tct/?t=$(date +%s)

# 方法3: 刷新 CDN
aliyun cdn RefreshObjectCaches \
    --ObjectPath="https://cdn.example.com/tct/" \
    --ObjectType=Directory

# 方法4: 修改文件名（推荐）
# styles-v3.2.1.css → styles-v3.2.2.css

# 方法5: 检查 OSS 文件是否真的更新了
ossutil stat oss://bucket/tct/index.html
# 查看 Last-Modified 时间
```

### 10.4 CDN 问题

#### 问题1: CDN 刷新失败

**错误信息:**

```
Error: aliyun: command not found
```

**解决方案:**

```bash
# 安装 aliyun CLI
pip3 install aliyun-python-sdk-core
pip3 install aliyun-python-sdk-cdn

# 配置
aliyun configure

# 测试
aliyun cdn DescribeRefreshQuota
```

#### 问题2: CDN 刷新后仍然是旧内容

**原因:** CDN 节点较多，部分节点可能还未刷新

**解决方案:**

```bash
# 1. 等待 5-10 分钟后再测试

# 2. 查询刷新任务状态
aliyun cdn DescribeRefreshTasks

# 3. 使用不同地区的网络测试
# 或使用 VPN 切换到不同地区

# 4. 联系阿里云技术支持
# 提供刷新任务 ID
```

---

## 11. 最佳实践

### 11.1 开发流程

```
1. 本地开发
   ├─ 修改源代码 (assets/)
   ├─ 本地测试 (python3 -m http.server)
   └─ Git 提交

2. 开发环境部署
   ├─ 构建项目 (./build.sh)
   ├─ 部署到开发环境 (./deploy.sh h5/dev)
   └─ 开发环境测试

3. 测试环境部署
   ├─ 部署到测试环境 (./deploy.sh h5/test)
   ├─ 功能测试
   └─ 性能测试

4. 预发布环境
   ├─ 部署到预发布环境 (./deploy.sh h5/staging)
   ├─ 全面测试
   └─ 灰度测试（可选）

5. 生产环境部署
   ├─ 部署到生产环境 (./deploy.sh h5/prod)
   ├─ 刷新 CDN
   ├─ 监控访问日志
   └─ 数据统计验证

6. 维护
   ├─ 定期清理旧备份 (./backup-manager.sh)
   └─ 监控 OSS 存储空间
```

### 11.2 版本管理

#### 11.2.1 推荐的版本命名方式

```bash
# 语义化版本（推荐）
./deploy.sh h5/v1.0.0      # 主版本.次版本.修订号
./deploy.sh h5/v1.0.1      # Bug 修复
./deploy.sh h5/v1.1.0      # 新功能
./deploy.sh h5/v2.0.0      # 重大更新

# 日期版本
./deploy.sh h5/20241126
./deploy.sh h5/2024-11-26

# 环境版本
./deploy.sh h5/dev         # 开发
./deploy.sh h5/test        # 测试
./deploy.sh h5/staging     # 预发布
./deploy.sh h5/prod        # 生产

# 功能分支版本
./deploy.sh h5/feature-payment
./deploy.sh h5/hotfix-button
```

#### 11.2.2 Git 版本管理

```bash
# 创建 .gitignore
cat > .gitignore << 'EOF'
# 构建产物
dist/

# OSS 配置（包含敏感信息）
oss-config.sh

# 依赖
node_modules/

# 日志
*.log

# 系统文件
.DS_Store
*.swp
.idea/
.vscode/
EOF

# 提交代码
git add .
git commit -m "feat: 添加新功能"
git push

# 创建标签
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0

# 查看标签
git tag -l
```

### 11.3 安全建议

#### 11.3.1 保护敏感信息

```bash
# 1. 不要将 oss-config.sh 提交到 git
echo "oss-config.sh" >> .gitignore

# 2. 使用 RAM 子账号（最小权限原则）
# 在阿里云 RAM 控制台创建子账号
# 只授予必要的 OSS 和 CDN 权限

# 3. 定期轮换 AccessKey
# 建议每 90 天更换一次

# 4. 启用 MFA（多因素认证）
# 在阿里云账号设置中启用

# 5. 使用环境变量（可选）
export OSS_ACCESS_KEY_ID="your-key"
export OSS_ACCESS_KEY_SECRET="your-secret"
```

#### 11.3.2 访问控制

```bash
# 1. 设置 Referer 防盗链
# 控制台 → Bucket → 数据安全 → 防盗链
# 白名单: *.yourdomain.com

# 2. 使用私有 Bucket + 签名 URL（可选）
# 对于敏感资源

# 3. 启用 CDN 鉴权
# 对于重要资源启用 URL 鉴权
```

### 11.4 性能优化

#### 11.4.1 文件压缩

```bash
# 1. 启用 Gzip 压缩（OSS 自动支持）
# 客户端请求时带 Accept-Encoding: gzip 即可

# 2. 图片优化
# 使用 imagemin 压缩图片
npm install -g imagemin-cli imagemin-mozjpeg imagemin-pngquant

imagemin media/images/* --plugin=mozjpeg --plugin=pngquant \
    --out-dir=media/images/

# 3. 使用 WebP 格式（可选）
# 在支持的浏览器使用 WebP
```

#### 11.4.2 缓存策略

```bash
# 在 oss-config.sh 中设置：
export OSS_CACHE_CONTROL="max-age=31536000"        # 静态资源 1年
export OSS_HTML_CACHE_CONTROL="max-age=600"        # HTML 10分钟

# 手动设置特定文件：
ossutil set-meta oss://bucket/tct/index.html \
    Cache-Control:max-age=300 -f              # 5分钟

ossutil set-meta oss://bucket/tct/assets/ \
    Cache-Control:max-age=2592000 -r -f      # 30天
```

#### 11.4.3 CDN 加速

```bash
# 1. 在阿里云 CDN 控制台添加加速域名

# 2. 配置 CNAME 解析
# example.com → xxx.cdn.aliyuncs.com

# 3. 在 oss-config.sh 中配置
export OSS_CDN_DOMAIN="https://cdn.yourdomain.com"

# 4. 启用 HTTPS
# 上传 SSL 证书到 CDN

# 5. 配置缓存规则
# 在 CDN 控制台配置不同文件类型的缓存时间
```

### 11.5 监控和日志

#### 11.5.1 访问日志

```bash
# 1. 在阿里云 OSS 控制台启用日志存储
# Bucket → 日志管理 → 实时日志查询

# 2. 下载日志分析
ossutil cp -r oss://log-bucket/logs/ ./logs/

# 3. 分析访问量
cat logs/* | grep "GET" | wc -l

# 4. 分析热门文件
cat logs/* | grep "GET" | awk '{print $7}' | sort | uniq -c | sort -rn | head -20
```

#### 11.5.2 告警设置

```bash
# 在阿里云云监控设置告警规则：

# 1. OSS 下行流量超过阈值
# 规则: 下行流量 > 100GB/小时

# 2. OSS 请求次数超过阈值
# 规则: 请求次数 > 100万次/小时

# 3. 4xx/5xx 错误率超过阈值
# 规则: 错误率 > 5%

# 4. CDN 带宽使用率
# 规则: 带宽使用率 > 80%
```

#### 11.5.3 定期维护

```bash
# 创建定期维护脚本
cat > maintenance.sh << 'EOF'
#!/bin/bash

echo "开始定期维护..."

# 1. 清理7天前的备份
echo "[1/3] 清理旧备份..."
./backup-manager.sh <<< $'6\n\n7\n8'

# 2. 检查存储空间
echo "[2/3] 检查存储空间..."
ossutil du oss://bucket/

# 3. 生成报告
echo "[3/3] 生成维护报告..."
echo "维护时间: $(date)" > maintenance_$(date +%Y%m%d).log
echo "存储使用: $(ossutil du oss://bucket/)" >> maintenance_$(date +%Y%m%d).log

echo "维护完成！"
EOF

chmod +x maintenance.sh

# 添加到 crontab（每周日凌晨3点执行）
# 0 3 * * 0 /path/to/maintenance.sh
```

### 11.6 备份策略

```bash
# 推荐的备份保留策略：

# 1. 开发环境：保留最近 3 个备份
./backup-manager.sh
# 选择 6 → 输入项目名 → 输入 3

# 2. 测试环境：保留最近 5 个备份
# 选择 6 → 输入项目名 → 输入 5

# 3. 生产环境：保留最近 10 个备份
# 选择 6 → 输入项目名 → 输入 10

# 4. 重要版本：永久保留
# 手动创建带标记的备份
ossutil cp -r oss://bucket/tct/ \
    oss://bucket/.backups/tct/v1.0.0_stable/ \
    --update
```

---

## 12. FAQ

### Q1: 如何修改好多粉的统计ID？

**A:** 编辑 `index.html`，找到：

```html
<script type="text/javascript" src="//res.hduofen.cn/js/zaaxstat.js?id=lWaxBLZD"></script>
```

修改 `id` 参数为你的统计ID，然后重新构建和部署。

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
            { optionId: "DA002", labelText: "5-10万" },
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
./deploy.sh tct
```

---

### Q5: 如何回滚到之前的版本？

**A:**

```bash
# 方法1: 使用备份管理工具
./backup-manager.sh
# 选择 4) 恢复备份

# 方法2: 手动回滚
# 1. 查看备份列表
ossutil ls oss://bucket/.backups/tct/

# 2. 恢复备份
ossutil cp -r oss://bucket/.backups/tct/20251126_170755/ \
    oss://bucket/tct/ --update -f

# 3. 刷新 CDN
aliyun cdn RefreshObjectCaches \
    --ObjectPath="https://cdn.example.com/tct/" \
    --ObjectType=Directory
```

---

### Q6: 构建很慢怎么办？

**A:** 混淆过程较慢是正常的，可以：

```bash
# 1. 开发时跳过混淆（修改 build.sh）
# 注释掉混淆步骤，直接使用 terser 压缩
terser assets/js/core-7f2a3b4c.js \
    -o dist/assets/js/core-7f2a3b4c.min.js -c -m

# 2. 生产部署时再完整构建
./build.sh  # 包含混淆
```

---

### Q7: 如何部署到多个环境？

**A:**

```bash
# 方法1: 不同的部署路径
./deploy.sh h5/dev        # 开发环境
./deploy.sh h5/test       # 测试环境
./deploy.sh h5/staging    # 预发布环境
./deploy.sh h5/prod       # 生产环境

# 方法2: 不同的配置文件（高级）
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
ossutil ls oss://bucket/tct/ -r

# 2. 检查文件是否存在
ossutil stat oss://bucket/tct/index.html

# 3. 测试直接访问
curl -I https://bucket.oss-cn-beijing.aliyuncs.com/tct/index.html

# 4. 如果返回 403，检查 Bucket 权限
# 在阿里云控制台检查：
# - Bucket 读写权限
# - 防盗链设置
# - 跨域设置

# 5. 检查防火墙/安全组规则（如果有）
```

---

### Q10: 如何添加新的页面？

**A:**

```bash
# 1. 创建新的 HTML 文件
cp index.html page2.html

# 2. 修改 build.sh，添加对新页面的处理
# 在压缩 HTML 步骤添加：
html-minifier page2.html \
    --collapse-whitespace \
    --remove-comments \
    --minify-js true \
    --minify-css true \
    -o dist/page2.html

# 3. 修改 deploy-oss.sh，添加上传新页面
ossutil cp dist/page2.html oss://${OSS_BUCKET}/${OSS_DEPLOY_PATH}/ -f

# 4. 构建和部署
./build.sh
./deploy.sh tct

# 5. 访问新页面
# https://bucket.com/tct/page2.html
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
| 新加坡      | `oss-ap-southeast-1.aliyuncs.com` |
| 美国西部     | `oss-us-west-1.aliyuncs.com`      |

完整列表：[https://help.aliyun.com/document\_detail/31837.html](https://help.aliyun.com/document_detail/31837.html)

### B. 常用 MIME 类型

| 文件扩展名    | Content-Type               |
| -------- | -------------------------- |
| `.html`  | `text/html; charset=utf-8` |
| `.css`   | `text/css`                 |
| `.js`    | `application/javascript`   |
| `.json`  | `application/json`         |
| `.jpg`   | `image/jpeg`               |
| `.png`   | `image/png`                |
| `.gif`   | `image/gif`                |
| `.svg`   | `image/svg+xml`            |
| `.webp`  | `image/webp`               |
| `.woff`  | `font/woff`                |
| `.woff2` | `font/woff2`               |
| `.ttf`   | `font/ttf`                 |
| `.mp4`   | `video/mp4`                |
| `.mp3`   | `audio/mpeg`               |

### C. 快速参考命令

```bash
# 构建
./build.sh

# 部署
./deploy.sh tct

# 备份管理
./backup-manager.sh

# 查看文件
ossutil ls oss://bucket/tct/ -r

# 恢复备份
ossutil cp -r oss://bucket/.backups/tct/20251126_170755/ oss://bucket/tct/ --update -f

# 刷新 CDN
aliyun cdn RefreshObjectCaches --ObjectPath="https://cdn.example.com/tct/" --ObjectType=Directory

# 本地测试
cd dist && python3 -m http.server 8000
```

### D. 参考链接

* [阿里云 OSS 官方文档](https://help.aliyun.com/product/31815.html)
* [ossutil 使用文档](https://help.aliyun.com/document_detail/120075.html)
* [JavaScript Obfuscator](https://github.com/javascript-obfuscator/javascript-obfuscator)
* [Terser 文档](https://terser.org/docs/)
* [好多粉官网](https://www.hduofen.cn/)
* [阿里云 CDN 文档](https://help.aliyun.com/product/27099.html)

---

## 更新日志

### v3.1.0 (2025-11-26)

* ✅ 新增统一备份目录管理（`.backups/`）
* ✅ 新增自动回滚功能
* ✅ 新增 CDN 自动刷新功能
* ✅ 优化备份管理工具
* ✅ 移除权限自动设置
* ✅ 完善使用文档

### v3.0.0 (2025-11-25)

* ✅ 重构部署脚本，添加完整的错误处理
* ✅ 添加部署验证和健康检查
* ✅ 优化 MacBook 兼容性

### v2.0.4 (2025-11-24)

* ✅ 完善 MacBook 兼容性
* ✅ 修复 sed 命令 MacBook 兼容问题
* ✅ 修复 terser 参数错误
* ✅ 优化混淆配置

### v2.0.0 (2025-11-24)

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

**最后更新时间**: 2024-11-26 17:30:00
**文档版本**: v3.1.0

```
