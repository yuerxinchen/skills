# NN Skills - 项目跟踪系统

Claude Code 的自定义技能集合，用于管理长期工作主题和项目进展。

## 目录

- [快速开始](#快速开始)
- [功能特性](#功能特性)
- [安装方法](#安装方法)
- [使用指南](#使用指南)
- [命令参考](#命令参考)
- [移植到其他机器](#移植到其他机器)
- [创建自定义Skill](#创建自定义skill)
- [故障排除](#故障排除)

---

## 快速开始

### 一键安装

```bash
cd /Users/nana/SRC/github/nn-skills
./scripts/install.sh
```

安装后，在 Claude Code 中使用：

```bash
/list-pros                    # 列出所有项目
/list-pros active             # 只显示进行中的项目
/list-pros --detail           # 详细模式
```

---

## 功能特性

### 项目跟踪系统

管理长期工作主题，跨会话记录项目进展：

- ✅ **四态状态管理**：pending → active → completed → archived
- ✅ **智能目录检测**：自动集成 Claude Code memory 系统
- ✅ **跨会话持久化**：项目数据在所有会话中共享
- ✅ **导出/导入**：支持多机器迁移
- ✅ **Git友好**：Markdown格式，易于版本控制
- ✅ **彩色输出**：状态标识清晰直观

### 当前包含的Skills

1. **`/list-pros`** - 列出项目列表
   - 支持状态过滤（active/pending/completed/archived）
   - 支持详细模式（--detail）
   - 彩色表格输出

2. **`/setup-projects`** - 配置项目目录
   - 智能检测默认目录
   - 支持自定义路径
   - 自动初始化结构

3. **`/export-projects`** - 导出项目数据
   - 打包为 tar.gz 格式
   - 包含完整元数据
   - 用于跨机器迁移

4. **`/import-projects`** - 导入项目数据
   - 从备份文件恢复
   - 显示导出信息
   - 验证数据完整性

---

## 安装方法

### 方法1：使用安装脚本（推荐）

```bash
# 克隆或下载本仓库
cd /Users/nana/SRC/github/nn-skills

# 运行安装脚本
./scripts/install.sh

# 验证安装
ls -la ~/.claude/skills/project-tracker/
ls -la ~/.claude/skills/list-pros/
```

### 方法2：手动安装

```bash
# 复制skills到Claude目录
cp -r skills/project-tracker ~/.claude/skills/
cp -r skills/list-pros ~/.claude/skills/

# 设置可执行权限
chmod +x ~/.claude/skills/project-tracker/*.sh
chmod +x ~/.claude/skills/list-pros/*.sh

# 初始化配置（可选）
~/.claude/skills/project-tracker/project-tracker.sh setup
```

### 方法3：符号链接（开发模式）

适合开发和调试：

```bash
# 使用符号链接
ln -s /Users/nana/SRC/github/nn-skills/skills/project-tracker ~/.claude/skills/
ln -s /Users/nana/SRC/github/nn-skills/skills/list-pros ~/.claude/skills/

# 修改源代码会立即生效
```

---

## 使用指南

### 首次使用

Claude Code 会自动检测并加载 skills（支持热重载）。

```bash
# 在 Claude Code 中输入
/list-pros
```

如果命令不可用，等待几秒或发送一条新消息触发重新加载。

### 基本操作

#### 列出项目

```bash
# 显示所有项目
/list-pros

# 只显示活跃项目
/list-pros active

# 详细模式
/list-pros --detail

# 组合使用
/list-pros completed --detail
```

#### 配置管理

```bash
# 查看当前配置
/setup-projects

# 设置自定义目录
/setup-projects /path/to/projects

# 重置为默认
/setup-projects --reset

# 初始化目录
/setup-projects --init
```

#### 导出和导入

```bash
# 导出项目数据
/export-projects ~/my-projects-backup.tar.gz

# 导入项目数据
/import-projects ~/my-projects-backup.tar.gz
```

### 项目文件格式

每个项目是一个 Markdown 文件，包含 YAML frontmatter：

```yaml
---
name: 项目名称
description: 简短描述
type: project_work
status: active  # pending/active/completed/archived
created: 2026-09-25
updated: 2026-09-25
files:
  - /path/to/related/file1
  - /path/to/related/file2
tags:
  - tag1
  - tag2
---

[项目详细说明、进展记录、关键决策]
```

---

## 命令参考

### /list-pros [status] [--detail]

列出项目列表。

**参数**：
- `status`（可选）：`active`, `pending`, `completed`, `archived`, `all`
- `--detail`（可选）：显示详细信息

**示例**：
```bash
/list-pros                    # 所有项目（标准模式）
/list-pros active             # 进行中的项目
/list-pros --detail           # 详细模式
/list-pros active --detail    # 组合使用
```

**输出格式**：

标准模式：
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
项目名称          状态      更新时间      描述
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
VFIO热迁移分析    active    2026-06-10    VFIO和MLX5驱动...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
总计: 1 个项目
```

详细模式：包含文件列表、标签、完整正文内容

### /setup-projects [path|--reset|--init]

配置项目跟踪系统。

**用法**：
```bash
/setup-projects                      # 显示当前配置
/setup-projects /path/to/projects    # 设置目录
/setup-projects --reset              # 重置配置
/setup-projects --init               # 初始化目录
```

### /export-projects <output-file>

导出所有项目数据。

**用法**：
```bash
/export-projects ~/backup.tar.gz
```

**导出内容**：
- 所有 `project_work` 类型的文件
- MEMORY.md 或 PROJECTS.md 索引
- 元数据文件（导出时间、源目录）

### /import-projects <input-file>

导入项目数据。

**用法**：
```bash
/import-projects ~/backup.tar.gz
```

**注意**：导入会覆盖同名文件，建议先备份。

---

## 移植到其他机器

### 方案A：导出/导入（一次性迁移）

**源机器**：
```bash
# 在 Claude Code 中
/export-projects ~/my-projects-backup.tar.gz

# 传输文件到目标机器（scp/rsync/云存储）
```

**目标机器**：
```bash
# 1. 安装 nn-skills
cd /path/to/nn-skills
./scripts/install.sh

# 2. 在 Claude Code 中导入
/import-projects ~/my-projects-backup.tar.gz

# 3. 验证
/list-pros
```

### 方案B：Git同步（持续使用）

**初始化Git仓库**（源机器）：
```bash
cd ~/.claude/projects/<workdir-hash>/memory
git init
git add *.md
git commit -m "Initial commit"
git remote add origin git@github.com:username/claude-projects.git
git push -u origin main
```

**克隆到目标机器**：
```bash
# 1. 克隆数据
cd ~/.claude/projects/<workdir-hash>/
git clone git@github.com:username/claude-projects.git memory

# 2. 配置指向该目录
/setup-projects ~/.claude/projects/<workdir-hash>/memory

# 3. 验证
/list-pros
```

**日常同步**：
```bash
# 推送更新
cd ~/.claude/projects/<workdir-hash>/memory
git add *.md
git commit -m "Update: $(date +%Y-%m-%d)"
git push

# 拉取更新
cd ~/.claude/projects/<workdir-hash>/memory
git pull
```

### 方案C：完整项目打包

如果要打包整个 nn-skills 项目：

```bash
# 打包
cd /Users/nana/SRC/github/
tar -czf nn-skills.tar.gz nn-skills/

# 在目标机器解压并安装
tar -xzf nn-skills.tar.gz
cd nn-skills/
./scripts/install.sh
```

---

## 创建自定义Skill

### Skill的工作原理

Claude Code 的 skill 是**指令型**的：
- Skill 文件（`SKILL.md`）告诉 Claude **如何操作**
- Claude 读取指令后，使用工具（Bash/Read/Write等）执行
- **不是**系统直接执行脚本

### 创建新Skill的步骤

#### 1. 创建Skill目录

```bash
mkdir -p ~/.claude/skills/my-skill
```

#### 2. 创建SKILL.md

```markdown
---
name: my-skill
description: 简短描述这个skill的功能
---

当用户调用此 skill 时，使用 Bash 工具执行：

\`\`\`bash
/path/to/my-script.sh [用户参数]
\`\`\`

**参数说明**：
- 参数1：说明
- 参数2：说明

**示例**：
- `/my-skill` → 执行 `my-script.sh`
- `/my-skill arg` → 执行 `my-script.sh arg`
```

#### 3. 创建实现脚本

```bash
#!/bin/bash
# my-script.sh

echo "Hello from my-skill!"
echo "Arguments: $@"
```

#### 4. 设置权限

```bash
chmod +x ~/.claude/skills/my-skill/my-script.sh
```

#### 5. 测试

```bash
# 在 Claude Code 中
/my-skill test
```

### Skill模板

完整模板在 `docs/skill-template/` 目录。

---

## 故障排除

### 命令找不到

**问题**：输入 `/list-pros` 提示 "Unknown command"

**解决**：
1. 检查文件是否存在：
   ```bash
   ls -la ~/.claude/skills/list-pros/SKILL.md
   ```

2. 检查文件名是否正确（必须是 `SKILL.md`，全大写）

3. 等待几秒让热重载生效，或发送新消息触发

4. 重启 Claude Code

### 脚本不执行

**问题**：命令识别了但没有执行

**原因**：Claude Code 的 skill 是指令型，需要 Claude 读取后执行

**验证**：检查是否看到 Claude 使用 Bash 工具执行脚本

### 权限问题

**问题**：脚本执行时提示权限被拒绝

**解决**：
```bash
chmod +x ~/.claude/skills/project-tracker/*.sh
chmod +x ~/.claude/skills/list-pros/*.sh
```

### 项目列表为空

**问题**：`/list-pros` 显示没有项目

**解决**：
1. 检查配置：`/setup-projects`
2. 验证项目文件存在且格式正确
3. 确认 `type: project_work` 字段存在

### 导入失败

**问题**：导入备份文件出错

**解决**：
```bash
# 验证文件完整性
tar -tzf backup.tar.gz

# 手动解压检查
tar -xzf backup.tar.gz -C /tmp/test
ls -la /tmp/test/project-tracker-export/
```

---

## 项目结构

```
nn-skills/
├── README.md                        # 本文档
├── LICENSE                          # 许可证
├── .gitignore                       # Git忽略文件
├── skills/                          # Skills代码
│   ├── project-tracker/             # 项目跟踪核心
│   │   ├── SKILL.md                 # Skill定义
│   │   ├── handler.sh               # 命令路由
│   │   ├── project-tracker.sh       # 核心脚本（12KB）
│   │   └── list-pros.sh             # list-pros包装
│   └── list-pros/                   # list-pros快捷命令
│       ├── SKILL.md                 # Skill定义
│       └── handler.sh               # 命令处理
├── scripts/                         # 工具脚本
│   ├── install.sh                   # 安装脚本
│   ├── uninstall.sh                 # 卸载脚本
│   └── test.sh                      # 测试脚本
└── docs/                            # 文档
    ├── migration-guide.md           # 移植指南（详细版）
    ├── skill-development.md         # Skill开发指南
    └── skill-template/              # Skill模板
        ├── SKILL.md
        └── handler.sh
```

---

## 技术细节

### 配置存储

配置文件按工作目录隔离：
```
~/.claude/projects/<workdir-hash>/project-tracker-config.json
```

其中 `<workdir-hash>` 是当前工作目录的 MD5 哈希值。

### 智能目录检测

系统自动检测最合适的默认目录：

1. 检查是否有配置文件 → 使用配置的目录
2. 检查 `~/.claude/projects/<hash>/memory/` 是否存在 → 使用（集成模式）
3. 否则使用 `$PWD/.projects/`

### 数据格式

- **索引文件**：`MEMORY.md` 或 `PROJECTS.md`
- **项目文件**：`project_work_<slug>.md`
- **配置文件**：JSON格式
- **备份文件**：tar.gz格式

---

## 环境要求

- **操作系统**：macOS, Linux
- **Shell**：bash 4.0+
- **Claude Code**：2.1.0+ (支持skill热重载)
- **工具依赖**：
  - `tar` - 导出/导入
  - `md5sum` 或 `md5` - 目录hash
  - `git` (可选) - 版本控制

---

## 许可证

MIT License

---

## 更新日志

### v1.0.0 (2026-09-25)

- 初始发布
- 支持项目列表、配置、导出、导入
- 四态状态管理
- 智能目录检测
- Git同步支持
- 完整文档

---

## 贡献

欢迎提交 Issue 和 Pull Request！

---

## 相关资源

- [Claude Code 官方文档](https://docs.anthropic.com/claude/docs)
- [项目跟踪移植指南（详细版）](docs/migration-guide.md)
- [Skill 开发指南](docs/skill-development.md)

---

**作者**：nana  
**创建时间**：2026-09-25  
**最后更新**：2026-09-25
