---
name: project-tracker
description: 项目跟踪系统 - 管理长期工作主题，跨会话记录项目进展。使用 /list-pros 列出项目，/setup-projects 配置目录。
---

# 项目跟踪系统

管理长期工作主题，跨会话记录项目进展。

## 命令列表

### /list-pros [status] [--detail]

列出项目列表。

**参数**：
- `status`（可选）：过滤状态 - `active`, `pending`, `completed`, `archived`, `all`（默认显示所有）
- `--detail`（可选）：显示详细信息

**示例**：
```bash
/list-pros                    # 显示所有项目
/list-pros active             # 只显示进行中的项目
/list-pros completed          # 只显示已完成的项目
/list-pros --detail           # 详细模式
/list-pros active --detail    # 组合使用
```

### /setup-projects [path|--reset|--init]

配置项目跟踪系统。

**参数**：
- 无参数：显示当前配置
- `<path>`：设置项目目录并初始化
- `--reset`：重置为默认配置
- `--init`：在当前配置的目录初始化结构

**示例**：
```bash
/setup-projects                                    # 显示当前配置
/setup-projects /path/to/projects                  # 设置并初始化
/setup-projects --reset                            # 重置配置
/setup-projects --init                             # 初始化目录
```

### /export-projects <output-file>

导出所有项目数据到指定文件（用于迁移到其他机器）。

**示例**：
```bash
/export-projects ~/my-projects-backup.tar.gz
```

### /import-projects <input-file>

从备份文件导入项目数据。

**示例**：
```bash
/import-projects ~/my-projects-backup.tar.gz
```

## Implementation

调用 `project-tracker.sh` 脚本处理所有命令。
