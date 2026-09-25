# 项目跟踪系统 - 移植和使用指南

## 目录

- [1. 系统概述](#1-系统概述)
- [2. 快速开始](#2-快速开始)
- [3. 移植到其他机器](#3-移植到其他机器)
- [4. 命令参考](#4-命令参考)
- [5. 项目文件格式](#5-项目文件格式)
- [6. 配置管理](#6-配置管理)
- [7. 跨机器同步策略](#7-跨机器同步策略)
- [8. 故障排除](#8-故障排除)

---

## 1. 系统概述

### 1.1 功能特性

项目跟踪系统是一个轻量级工具，用于管理长期工作主题，跨会话记录项目进展。

**核心特性**：
- ✅ 跨会话持久化项目记录
- ✅ 四态状态管理（pending/active/completed/archived）
- ✅ 与Claude Code memory系统集成
- ✅ 智能检测默认目录
- ✅ 导出/导入支持多机器使用
- ✅ Git友好的Markdown存储格式

**设计理念**：
- **项目定义**：长期工作主题（如"插件开发"、"系统研究"）
- **存储方式**：每个项目一个Markdown文件 + 统一索引
- **配置机制**：工作目录独立配置，支持多项目并行

### 1.2 系统架构

```
~/.claude/
├── skills/
│   └── project-tracker/              # Skill定义目录
│       ├── skill.md                  # Skill说明文档
│       ├── handler.sh                # 命令路由器
│       └── project-tracker.sh        # 核心实现脚本
└── projects/
    └── <workdir-hash>/               # 工作目录独立配置
        ├── project-tracker-config.json  # 配置文件
        └── memory/                   # 项目文件存储目录（可配置）
            ├── MEMORY.md             # 索引文件（集成模式）
            ├── project_work_*.md     # 项目文件
            └── ...
```

**关键组件**：
1. **Skill定义**（`skill.md`）：声明可用命令和参数
2. **核心脚本**（`project-tracker.sh`）：实现所有业务逻辑
3. **配置文件**（`project-tracker-config.json`）：存储项目目录路径
4. **项目文件**（`project_work_*.md`）：Markdown格式的项目记录

---

## 2. 快速开始

### 2.1 首次使用

在Claude Code中直接使用命令即可，系统会自动初始化：

```bash
# 查看当前配置（首次使用会显示默认配置）
/setup-projects

# 列出所有项目
/list-pros
```

**智能检测逻辑**：
1. 检查是否有配置文件，有则使用配置的目录
2. 否则检查 `~/.claude/projects/<workdir-hash>/memory/` 是否存在
3. 如果存在memory目录，使用该目录（与memory系统集成）
4. 否则在当前工作目录创建 `.projects/`

### 2.2 指定自定义目录

如果需要使用特定目录存储项目：

```bash
# 设置项目目录（会自动初始化）
/setup-projects /path/to/my/projects

# 验证配置
/setup-projects
```

### 2.3 基本操作

```bash
# 列出所有项目
/list-pros

# 只显示进行中的项目
/list-pros active

# 详细模式查看所有信息
/list-pros --detail

# 查看已完成的项目详情
/list-pros completed --detail
```

---

## 3. 移植到其他机器

### 3.1 方案A：导出/导入（推荐用于一次性迁移）

#### 源机器操作

```bash
# 1. 导出项目数据
/export-projects ~/my-projects-backup.tar.gz

# 2. 将备份文件传输到目标机器
# 使用scp、rsync、云存储等方式
```

#### 目标机器操作

```bash
# 1. 确保已安装项目跟踪系统（见3.3节）

# 2. 导入项目数据
/import-projects ~/my-projects-backup.tar.gz

# 3. 验证导入结果
/list-pros
```

### 3.2 方案B：Git同步（推荐用于持续使用）

#### 初始设置

```bash
# 在源机器上
cd ~/.claude/projects/<workdir-hash>/memory
git init
git add *.md
git commit -m "Initial commit: project tracking data"

# 添加远程仓库（GitHub/GitLab/自建Git服务器）
git remote add origin git@github.com:username/claude-projects.git
git push -u origin main
```

#### 目标机器首次同步

```bash
# 1. 克隆项目数据
cd ~/.claude/projects/<workdir-hash>/
git clone git@github.com:username/claude-projects.git memory

# 2. 配置项目跟踪系统指向该目录
/setup-projects ~/.claude/projects/<workdir-hash>/memory

# 3. 验证
/list-pros
```

#### 日常同步

```bash
# 推送更新（源机器）
cd ~/.claude/projects/<workdir-hash>/memory
git add *.md
git commit -m "Update: project status changes"
git push

# 拉取更新（目标机器）
cd ~/.claude/projects/<workdir-hash>/memory
git pull
```

### 3.3 安装项目跟踪系统

#### 方法1：手动安装

```bash
# 1. 创建目标目录
mkdir -p ~/.claude/skills/project-tracker

# 2. 复制文件（从本仓库或已安装的机器）
cp skill.md ~/.claude/skills/project-tracker/
cp handler.sh ~/.claude/skills/project-tracker/
cp project-tracker.sh ~/.claude/skills/project-tracker/

# 3. 设置可执行权限
chmod +x ~/.claude/skills/project-tracker/handler.sh
chmod +x ~/.claude/skills/project-tracker/project-tracker.sh

# 4. 重启Claude Code或重新加载skills
```

#### 方法2：脚本安装

创建安装脚本 `install-project-tracker.sh`：

```bash
#!/bin/bash
set -e

SKILL_DIR="$HOME/.claude/skills/project-tracker"
SOURCE_DIR="./project-tracker"  # 指向源文件目录

echo "安装项目跟踪系统..."

# 创建目录
mkdir -p "$SKILL_DIR"

# 复制文件
cp "$SOURCE_DIR/skill.md" "$SKILL_DIR/"
cp "$SOURCE_DIR/handler.sh" "$SKILL_DIR/"
cp "$SOURCE_DIR/project-tracker.sh" "$SKILL_DIR/"

# 设置权限
chmod +x "$SKILL_DIR/handler.sh"
chmod +x "$SKILL_DIR/project-tracker.sh"

echo "✓ 安装完成：$SKILL_DIR"
echo "请重启Claude Code或重新加载skills"
```

运行安装：

```bash
chmod +x install-project-tracker.sh
./install-project-tracker.sh
```

#### 方法3：符号链接（开发模式）

如果你在开发或修改系统，可以使用符号链接：

```bash
# 假设源文件在 ~/dev/project-tracker
ln -s ~/dev/project-tracker ~/.claude/skills/project-tracker

# 这样修改源文件会立即生效，无需复制
```

---

## 4. 命令参考

### 4.1 /list-pros

列出项目列表。

**语法**：
```bash
/list-pros [status] [--detail]
```

**参数**：
- `status`（可选）：过滤状态
  - `active` - 进行中的项目
  - `pending` - 计划中的项目
  - `completed` - 已完成的项目
  - `archived` - 已归档的项目
  - `all` - 所有项目（默认）
- `--detail`（可选）：详细模式，显示完整信息

**示例**：

```bash
# 显示所有项目（标准模式）
/list-pros

# 只显示进行中的项目
/list-pros active

# 详细模式显示所有项目
/list-pros --detail

# 详细模式显示已完成的项目
/list-pros completed --detail
```

**标准模式输出**：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
项目名称                        状态           更新时间          描述
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
网络驱动优化                    active         2026-06-10        高性能网络驱动研究
通信库文档                      active         2026-06-28        通信库初始化文档编写
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
总计: 2 个项目
```

**详细模式输出**：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 项目: 网络驱动优化
状态: active
创建: 2026-06-10 | 更新: 2026-06-10
描述: 高性能网络驱动研究

📁 相关文件:
  - /path/to/project/doc/driver_analysis.md
  - /path/to/project/doc/performance_optimization.md

🏷️  标签: network, driver, performance, optimization

📝 详细说明:
[显示项目正文内容]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 4.2 /setup-projects

配置项目跟踪系统。

**语法**：
```bash
/setup-projects [path|--reset|--init]
```

**参数**：
- 无参数：显示当前配置
- `<path>`：设置项目目录并初始化
- `--reset`：重置为默认配置
- `--init`：在当前配置的目录初始化结构

**示例**：

```bash
# 显示当前配置
/setup-projects

# 设置自定义目录
/setup-projects /path/to/projects

# 重置为默认配置
/setup-projects --reset

# 初始化当前配置的目录
/setup-projects --init
```

**输出示例**：

```
当前配置：
  项目目录: /Users/nana/.claude/projects/-Volumes-volume2-aicloud/memory
  状态: 已初始化
```

### 4.3 /export-projects

导出所有项目数据到指定文件。

**语法**：
```bash
/export-projects <output-file>
```

**参数**：
- `output-file`：输出文件路径（.tar.gz格式）

**示例**：

```bash
# 导出到用户目录
/export-projects ~/my-projects-backup.tar.gz

# 导出到指定路径
/export-projects /tmp/projects-2026-09-25.tar.gz
```

**导出内容**：
- 所有 `project_work` 类型的Markdown文件
- MEMORY.md 或 PROJECTS.md 索引文件
- export-metadata.json（包含导出时间、源目录等元数据）

### 4.4 /import-projects

从备份文件导入项目数据。

**语法**：
```bash
/import-projects <input-file>
```

**参数**：
- `input-file`：输入文件路径（.tar.gz格式）

**示例**：

```bash
# 从备份文件导入
/import-projects ~/my-projects-backup.tar.gz

# 导入时会显示元数据信息
```

**注意事项**：
- 导入会覆盖目标目录中同名的项目文件
- 建议在导入前备份当前数据
- 导入后建议运行 `/list-pros` 验证

---

## 5. 项目文件格式

### 5.1 Frontmatter格式

每个项目文件使用YAML frontmatter存储元数据：

```yaml
---
name: 项目名称
description: 简短描述（一句话说明项目内容）
type: project_work
status: active
created: 2026-09-25
updated: 2026-09-25
files:
  - /path/to/related/file1.md
  - /path/to/related/file2.cc
tags:
  - tag1
  - tag2
  - tag3
originSessionId: optional-session-id
---

[项目详细说明、进展记录、关键决策等正文内容]
```

### 5.2 字段说明

#### 核心必需字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `name` | string | 项目名称，用于标识和显示 |
| `description` | string | 简短描述，一句话说明项目内容 |
| `type` | string | 固定值 `project_work`，标识为项目跟踪记录 |
| `status` | enum | 项目状态，见下表 |
| `created` | date | 创建日期，格式 YYYY-MM-DD |

#### 常用可选字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `updated` | date | 最后更新日期，格式 YYYY-MM-DD |
| `files` | array | 相关文件列表，绝对路径 |
| `tags` | array | 标签列表，用于分类和搜索 |

#### 偶尔使用字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `originSessionId` | string | 创建项目的会话ID，用于追溯 |

### 5.3 状态定义

| 状态 | 说明 | 使用场景 |
|------|------|----------|
| `pending` | 计划中 | 已规划但未开始的项目 |
| `active` | 进行中 | 当前正在进行的项目 |
| `completed` | 已完成 | 工作已完成但可能需要参考 |
| `archived` | 已归档 | 不再活跃，长期存档 |

### 5.4 文件命名规范

**格式**：`project_work_<slug>.md`

**示例**：
- `project_work_network_driver.md` - 网络驱动优化
- `project_work_comm_lib_doc.md` - 通信库文档
- `project_work_plugin_dev.md` - 插件开发

**命名规则**：
- 前缀：`project_work_` - 标识为项目工作记录
- slug：使用小写字母、数字、下划线
- 后缀：`.md` - Markdown格式

### 5.5 完整示例

```markdown
---
name: 分布式系统优化研究
description: 深入研究分布式系统在特定场景下的性能优化机制
type: project_work
status: active
created: 2026-09-15
updated: 2026-09-25
files:
  - /path/to/project/doc/system-optimization.md
  - /path/to/project/.claude/optimization_memory.md
tags:
  - distributed
  - optimization
  - performance
  - research
---

## 项目背景

研究分布式系统的性能优化方案和实现机制。

## 当前进展

### 已完成
- ✅ 多节点扩展场景分析
- ✅ 核心算法详解
- ✅ 测试场景构建

### 进行中
- 🔄 调用链完整追踪
- 🔄 回调机制深入分析

### 待完成
- ⏳ 性能对比测试
- ⏳ 多节点场景的完整测试验证

## 关键文档

主工作文档：`system-optimization.md`（~2900行，13章）
- 第9章：核心实现深度分析
- 第12章：多节点扩展示例
- 第13章：关键操作详解

研究上下文记忆：`.claude/optimization_memory.md`

## 参考资源

- 系统源码：`/path/to/system/source/`
- 插件代码：`/path/to/plugins/`

## 里程碑

- [x] 2026-09-15 项目启动
- [x] 2026-09-20 完成基础分析
- [ ] 2026-10-01 完成性能对比测试
- [ ] 2026-10-15 完成多节点验证

---

最后更新：2026-09-25
```

---

## 6. 配置管理

### 6.1 配置文件位置

配置文件按工作目录隔离：

```
~/.claude/projects/<workdir-hash>/project-tracker-config.json
```

其中 `<workdir-hash>` 是当前工作目录的MD5哈希值。

**查看当前工作目录的配置文件**：

```bash
# 计算hash（macOS）
echo -n "$PWD" | md5

# 配置文件完整路径示例
~/.claude/projects/a1b2c3d4e5f6/project-tracker-config.json
```

### 6.2 配置文件格式

```json
{
  "project_dir": "/path/to/your/projects"
}
```

**字段说明**：
- `project_dir`：项目文件存储目录的绝对路径

### 6.3 手动修改配置

如果需要手动修改配置（不推荐，建议使用 `/setup-projects`）：

```bash
# 1. 找到配置文件
workdir_hash=$(echo -n "$PWD" | md5)
config_file="$HOME/.claude/projects/$workdir_hash/project-tracker-config.json"

# 2. 编辑配置文件
vim "$config_file"

# 3. 确保JSON格式正确
cat "$config_file"
```

### 6.4 多工作目录配置

不同工作目录可以配置不同的项目存储位置：

```bash
# 在工作目录A
cd /path/to/project-a
/setup-projects /path/to/storage-a

# 在工作目录B
cd /path/to/project-b
/setup-projects /path/to/storage-b

# 两者互不干扰，各自独立管理
```

---

## 7. 跨机器同步策略

### 7.1 Git同步详细步骤

#### 7.1.1 初始化Git仓库

```bash
# 1. 进入项目目录
cd ~/.claude/projects/<workdir-hash>/memory

# 2. 初始化Git
git init

# 3. 创建.gitignore（可选）
cat > .gitignore << 'EOF'
# 忽略临时文件
*.tmp
*.swp
*~

# 忽略备份文件
*.bak
EOF

# 4. 添加所有项目文件
git add *.md .gitignore

# 5. 首次提交
git commit -m "Initial commit: project tracking data"
```

#### 7.1.2 设置远程仓库

**方案A：GitHub**

```bash
# 1. 在GitHub创建私有仓库（推荐private）
# 仓库名例如：claude-projects

# 2. 添加远程仓库
git remote add origin git@github.com:username/claude-projects.git

# 3. 推送
git branch -M main
git push -u origin main
```

**方案B：GitLab**

```bash
# 1. 在GitLab创建项目
git remote add origin git@gitlab.com:username/claude-projects.git
git branch -M main
git push -u origin main
```

**方案C：自建Git服务器**

```bash
# 假设你有自己的Git服务器
git remote add origin git@your-server.com:path/to/claude-projects.git
git branch -M main
git push -u origin main
```

#### 7.1.3 日常工作流程

**推送更新**：

```bash
cd ~/.claude/projects/<workdir-hash>/memory

# 查看变化
git status

# 添加修改的文件
git add project_work_*.md MEMORY.md

# 提交
git commit -m "Update: $(date +%Y-%m-%d) - project status changes"

# 推送到远程
git push
```

**拉取更新**：

```bash
cd ~/.claude/projects/<workdir-hash>/memory

# 拉取最新变化
git pull

# 解决冲突（如果有）
# 编辑冲突文件，然后：
git add <conflict-file>
git commit
```

**自动同步脚本**：

创建 `~/.claude/scripts/sync-projects.sh`：

```bash
#!/bin/bash
# 自动同步项目数据

PROJECT_DIR="$HOME/.claude/projects/<workdir-hash>/memory"
cd "$PROJECT_DIR" || exit 1

# 拉取最新
echo "拉取最新变化..."
git pull

# 添加本地修改
echo "添加本地修改..."
git add -A

# 检查是否有变化
if ! git diff --staged --quiet; then
    echo "提交变化..."
    git commit -m "Auto sync: $(date +%Y-%m-%d\ %H:%M:%S)"
    
    echo "推送到远程..."
    git push
    
    echo "✓ 同步完成"
else
    echo "没有变化需要同步"
fi
```

使用：

```bash
chmod +x ~/.claude/scripts/sync-projects.sh
~/.claude/scripts/sync-projects.sh
```

### 7.2 导出/导入最佳实践

#### 7.2.1 定期备份

创建自动备份脚本 `~/.claude/scripts/backup-projects.sh`：

```bash
#!/bin/bash
# 定期备份项目数据

BACKUP_DIR="$HOME/Backups/claude-projects"
DATE=$(date +%Y-%m-%d)
BACKUP_FILE="$BACKUP_DIR/projects-backup-$DATE.tar.gz"

mkdir -p "$BACKUP_DIR"

# 执行导出（需要在Claude Code中运行）
echo "创建备份: $BACKUP_FILE"
# 注意：这个命令需要在Claude Code session中执行
# /export-projects "$BACKUP_FILE"

# 保留最近30天的备份
find "$BACKUP_DIR" -name "projects-backup-*.tar.gz" -mtime +30 -delete

echo "✓ 备份完成"
```

#### 7.2.2 云存储集成

**上传到云存储**：

```bash
#!/bin/bash
# 备份后上传到云存储

BACKUP_FILE="/path/to/backup.tar.gz"

# 上传到Dropbox（需要安装dropbox-cli）
# ~/dropbox_uploader.sh upload "$BACKUP_FILE" /Projects/

# 上传到AWS S3（需要aws-cli）
# aws s3 cp "$BACKUP_FILE" s3://your-bucket/claude-projects/

# 上传到阿里云OSS（需要ossutil）
# ossutil cp "$BACKUP_FILE" oss://your-bucket/claude-projects/

echo "✓ 已上传到云存储"
```

### 7.3 同步策略对比

| 方案 | 优点 | 缺点 | 适用场景 |
|------|------|------|----------|
| **Git同步** | • 版本控制<br>• 冲突解决<br>• 多人协作 | • 需要Git知识<br>• 配置略复杂 | 持续使用多台机器 |
| **导出/导入** | • 简单直接<br>• 无需额外配置 | • 手动操作<br>• 无版本历史 | 一次性迁移 |
| **云存储同步** | • 自动同步<br>• 多平台支持 | • 需要同步软件<br>• 可能有冲突 | 个人多设备使用 |

**推荐组合**：
- 主要方式：Git同步（版本控制 + 多机同步）
- 备份方式：定期导出到云存储（灾难恢复）

---

## 8. 故障排除

### 8.1 命令找不到

**问题**：运行 `/list-pros` 等命令时提示找不到

**可能原因**：
1. Skill未正确安装
2. Claude Code未加载skill
3. 文件权限问题

**解决方案**：

```bash
# 1. 检查skill目录是否存在
ls -la ~/.claude/skills/project-tracker/

# 2. 检查文件权限
ls -l ~/.claude/skills/project-tracker/*.sh

# 3. 确保脚本可执行
chmod +x ~/.claude/skills/project-tracker/handler.sh
chmod +x ~/.claude/skills/project-tracker/project-tracker.sh

# 4. 重启Claude Code
```

### 8.2 配置文件问题

**问题**：配置不生效或显示错误的目录

**解决方案**：

```bash
# 1. 查看当前配置
/setup-projects

# 2. 重置配置
/setup-projects --reset

# 3. 重新设置
/setup-projects /correct/path

# 4. 手动检查配置文件
workdir_hash=$(echo -n "$PWD" | md5)
cat "$HOME/.claude/projects/$workdir_hash/project-tracker-config.json"
```

### 8.3 项目列表为空

**问题**：运行 `/list-pros` 显示没有项目

**可能原因**：
1. 项目目录不正确
2. 项目文件格式错误
3. 项目文件类型不是 `project_work`

**解决方案**：

```bash
# 1. 确认项目目录
/setup-projects

# 2. 手动检查项目文件
project_dir=$(grep project_dir ~/.claude/projects/*/project-tracker-config.json | cut -d'"' -f4)
ls -la "$project_dir"/*.md

# 3. 检查文件frontmatter
head -15 "$project_dir"/project_work_*.md

# 4. 确认type字段为project_work
grep "^type:" "$project_dir"/*.md
```

### 8.4 导入失败

**问题**：导入备份文件时出错

**解决方案**：

```bash
# 1. 验证备份文件完整性
tar -tzf backup-file.tar.gz

# 2. 检查备份文件结构
tar -xzf backup-file.tar.gz -C /tmp/test-extract
ls -la /tmp/test-extract/

# 3. 手动导入
tar -xzf backup-file.tar.gz -C /tmp/
cp /tmp/project-tracker-export/*.md "$project_dir/"

# 4. 清理
rm -rf /tmp/test-extract /tmp/project-tracker-export
```

### 8.5 Git同步冲突

**问题**：Git pull时出现合并冲突

**解决方案**：

```bash
cd ~/.claude/projects/<workdir-hash>/memory

# 1. 查看冲突文件
git status

# 2. 查看冲突内容
git diff

# 3. 编辑冲突文件，选择保留的版本
vim <conflict-file>

# 4. 标记为已解决
git add <conflict-file>

# 5. 完成合并
git commit

# 6. 推送
git push
```

**预防冲突**：
- 每次修改前先 `git pull`
- 不要同时在多台机器编辑同一个项目文件
- 使用分支策略（每台机器一个分支）

### 8.6 权限问题

**问题**：脚本执行时提示权限被拒绝

**解决方案**：

```bash
# 1. 检查文件权限
ls -l ~/.claude/skills/project-tracker/*.sh

# 2. 添加可执行权限
chmod +x ~/.claude/skills/project-tracker/*.sh

# 3. 检查目录权限
ls -ld ~/.claude/skills/project-tracker/

# 4. 确保所有者正确
ls -l ~/.claude/skills/project-tracker/
# 如果所有者不是当前用户，修改：
sudo chown -R $(whoami) ~/.claude/skills/project-tracker/
```

### 8.7 性能问题

**问题**：项目文件很多时，列表命令很慢

**优化建议**：

1. **归档旧项目**：
```bash
# 将completed项目改为archived
# 编辑项目文件，修改status字段
```

2. **分离存储**：
```bash
# 将归档项目移到单独目录
mkdir -p "$project_dir/archive"
mv "$project_dir"/project_work_old_*.md "$project_dir/archive/"
```

3. **定期清理**：
```bash
# 删除不再需要的项目
rm "$project_dir"/project_work_obsolete_*.md
# 更新索引文件
```

### 8.8 调试模式

如果遇到难以诊断的问题，可以启用调试模式：

```bash
# 在脚本开头添加调试输出
sed -i '2i set -x' ~/.claude/skills/project-tracker/project-tracker.sh

# 运行命令查看详细执行过程
/list-pros

# 关闭调试模式
sed -i '/set -x/d' ~/.claude/skills/project-tracker/project-tracker.sh
```

---

## 附录

### A. 完整安装包结构

```
project-tracker/
├── README.md                    # 本文档
├── install.sh                   # 安装脚本
├── skill.md                     # Skill定义
├── handler.sh                   # 命令路由器
├── project-tracker.sh           # 核心实现
└── examples/                    # 示例
    ├── sample-project.md        # 示例项目文件
    └── MEMORY.md.template       # 索引模板
```

### B. 环境要求

- **操作系统**：macOS, Linux
- **Shell**：bash 4.0+
- **工具依赖**：
  - `tar` - 用于导出/导入
  - `md5sum` 或 `md5` - 用于计算目录hash
  - `git`（可选）- 用于Git同步

### C. 更新日志

- **v1.0.0** (2026-09-25)
  - 初始版本发布
  - 支持基本的项目跟踪功能
  - 导出/导入功能
  - Git同步支持

---

## 帮助和支持

如果遇到问题或有功能建议，请：

1. 查看本文档的"故障排除"章节
2. 检查 `~/.claude/skills/project-tracker/skill.md` 获取最新说明
3. 在Claude Code会话中询问具体问题

---

**文档版本**：1.0.0  
**最后更新**：2026-09-25  
**维护者**：Claude Code Project Tracker
