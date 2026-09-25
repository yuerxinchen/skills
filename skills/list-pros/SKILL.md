---
name: list-pros
description: 列出项目列表，支持状态过滤和详细模式
---

当用户调用此 skill 时，使用 Bash 工具执行：

```bash
/Users/nana/.claude/skills/project-tracker/project-tracker.sh list [用户参数]
```

**参数说明**：
- 无参数：显示所有项目
- `active` / `pending` / `completed` / `archived`：按状态过滤
- `--detail`：详细模式，显示文件列表、标签和正文内容
- 可组合：`active --detail`

**示例**：
- `/list-pros` → 执行 `project-tracker.sh list`
- `/list-pros active` → 执行 `project-tracker.sh list active`
- `/list-pros --detail` → 执行 `project-tracker.sh list --detail`
