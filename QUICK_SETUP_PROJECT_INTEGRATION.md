# 快速配置：项目跟踪系统与文档自动路由集成

## 📋 概述

这份文档用于在新机器上快速配置**项目自动识别**和**文档自动路由**功能，使得 `/list-pros` 项目跟踪系统能够与 `/grill-with-docs`、`/domain-modeling` 等 skills 自动联动。

## 📜 许可声明

**版权所有 (c) 2026 nana**

本文档基于 MIT License 发布（见项目根目录的 LICENSE 文件）。

### 依赖项说明

- **平台**：本配置方案设计用于 [Claude Code](https://claude.ai/code) 平台（Anthropic 官方产品）
- **Skills 生态**：文档中提到的 skills（如 `mattpocock-skills` 中的 `grill-with-docs`、`domain-modeling`）为 Claude Code 生态系统的公开可用组件
- **内容性质**：本文档仅说明如何配置和使用这些功能，**不包含任何第三方专有代码**
- **合理使用**：对外部 skills 的引用仅限于功能名称和使用说明，符合合理使用原则

### 致谢

本配置方案的灵感和参考来源：
- **[mattpocock-skills](https://github.com/mattpocock/claude-code-skills)** - Matt Pocock 的优秀 Claude Code skills 集合，特别是其 domain-modeling 和 grilling skills 的设计理念
- **Claude Code 官方文档** - Anthropic 团队提供的平台文档和最佳实践
- **ADR 格式规范** - 架构决策记录的社区标准格式

**免责声明**：本项目是独立开发的工具，不隶属于上述任何项目或组织。所有商标和品牌名称归其各自所有者所有。

**配置后的效果：**
- 说项目名称 → 自动切换项目上下文
- 提到代码路径 → 自动识别所属项目
- 调用 grill-with-docs → ADR 自动创建到项目的 `adr/` 目录
- 创建 CONTEXT.md → 自动关联到项目目录

---

## 🚀 快速部署步骤

### 步骤 1：复制并发送配置指令

**直接复制下面的整段文字，粘贴发送给 Claude：**

```
请帮我配置项目跟踪系统与文档路由的集成：

1. 为所有现有项目文件（在 memory 目录下，文件名匹配 project_work_*.md）添加以下字段：
   - doc_dir: 文档目录路径（格式：doc/project/<项目slug>/）
   - aliases: 项目别名列表（包含项目名称的各种常用说法）

2. 创建系统级 ADR 记录这个架构决策：
   - 位置：doc/adr/0001-multi-project-documentation-organization.md
   - 内容：记录多项目文档组织的架构、项目识别机制、文档路由规则

3. 将项目识别和文档路由的工作流程规则保存到 memory：
   - 文件：memory/project_identification_workflow.md
   - 类型：feedback
   - 包含：自动识别触发点、匹配策略、文档路由规则、与 skills 集成方式

4. 更新 memory/MEMORY.md 索引，添加指向 project_identification_workflow.md 的链接

配置要求：
- 项目识别支持：显式切换、路径推断、关键词推断、会话保持
- 文档路由规则：项目级 ADR 放 doc/project/<项目名>/adr/，系统级放 doc/adr/
- CONTEXT.md 懒创建：只在需要记录术语时创建到 doc/project/<项目名>/CONTEXT.md
- 自动创建目录：首次创建文档时自动创建项目目录和 adr/ 子目录

请按照我们之前讨论的完整设计执行配置。
```

### 步骤 2：（可选）提供项目映射信息

如果 Claude 询问项目的 doc_dir 映射，提供以下信息：

```
现有项目的 doc_dir 映射：

project_work_project1.md  → doc/project/project1/
project_work_project2.md  → doc/project/project2/
project_work_project3.md  → doc/project/project3/

别名建议：
- 项目1：Project1、project1、项目1简称
- 项目2：Project2、project2、项目2简称
- 项目3：Project3、project3、项目3简称
```

### 步骤 3：验证配置

配置完成后，测试以下场景：

```
# 测试 1：显式项目切换
"看一下项目1"

# 测试 2：自动识别
"调用 /grill-with-docs 分析某个设计决策"

# 测试 3：列出项目
"/list-pros"
```

---

## 📝 配置详情

### 1. 项目文件增强字段

每个 `project_work_*.md` 文件需要添加：

```yaml
---
name: 项目名称
description: 项目描述
type: project_work
status: active|pending|completed|archived
created: YYYY-MM-DD
updated: YYYY-MM-DD
doc_dir: doc/project/<项目slug>/          # 新增
aliases:                                   # 新增
  - 别名1
  - 别名2
  - 别名3
files:
  - /path/to/code/
  - /path/to/docs/
tags:
  - tag1
  - tag2
---
```

**字段说明：**

- `doc_dir`：项目文档目录的相对路径（相对于工作目录根）
- `aliases`：用户可能用来称呼这个项目的各种说法（用于自动识别）

### 2. 目录结构

配置后的文档组织结构：

```
<工作目录>/
├── doc/
│   ├── adr/                        # 系统级 ADR（跨项目）
│   │   └── 0001-multi-project-documentation-organization.md
│   ├── project/                    # 项目特定文档
│   │   ├── <项目名>/
│   │   │   ├── CONTEXT.md         # 项目术语表（懒创建）
│   │   │   ├── adr/               # 项目 ADR
│   │   │   └── *.md               # 其他项目文档
│   ├── <其他现有目录>/             # 保持不变
│   └── *.md                        # 通用文档
└── .claude/
    └── projects/
        └── <workdir-hash>/
            └── memory/
                ├── MEMORY.md
                ├── project_work_*.md
                └── project_identification_workflow.md
```

### 3. 项目识别机制

**触发方式：**

1. **显式切换**：用户说 "看一下 <项目名>"
2. **路径推断**：用户提到代码路径，匹配项目的 `files` 字段
3. **关键词推断**：从对话内容提取关键词，搜索 name/aliases/tags/description
4. **会话保持**：识别后设置会话变量，后续操作自动关联

**匹配策略：**

- 搜索字段：name → aliases → tags → description → files
- 忽略大小写、空格、连字符
- 多个匹配时展示列表，优先推荐 active 和最近更新的项目

### 4. 文档路由规则

| 文档类型 | 有项目上下文 | 无项目上下文 |
|---------|------------|------------|
| ADR | `doc/project/<项目名>/adr/NNNN-xxx.md` | `doc/adr/NNNN-xxx.md` |
| CONTEXT.md | `doc/project/<项目名>/CONTEXT.md` | 不创建（使用 CLAUDE.md） |
| 项目文档 | `doc/project/<项目名>/xxx.md` | `doc/xxx.md` |
| 跨项目分析 | `doc/xxx.md`（明确是跨项目时） | `doc/xxx.md` |

**自动创建目录：**
- 首次创建文档时自动创建 `doc/project/<项目名>/` 和 `adr/` 子目录
- CONTEXT.md 懒创建，只在需要记录术语时创建

---

## 🔧 自定义配置参数

根据你的实际环境，可能需要调整以下内容：

### 参数 1：工作目录路径

如果你的代码在不同位置，需要更新项目文件中的 `files` 字段：

```yaml
files:
  - /YOUR/ACTUAL/PATH/to/code/
  - /YOUR/ACTUAL/PATH/to/doc/project/<项目名>/
```

### 参数 2：项目 doc_dir 命名规则

默认规则：项目名 → 小写 → 空格转连字符

```
"项目优化"  → "project-optimization"
"系统研究"  → "system-research"
"性能测试"  → "performance-testing"
```

如果你想用不同的命名，在配置时告诉 Claude：

```
项目的 doc_dir 映射规则：
- <项目名1> → doc/project/<自定义名称1>/
- <项目名2> → doc/project/<自定义名称2>/
```

### 参数 3：项目别名

根据你的实际使用习惯，调整 `aliases` 列表：

```yaml
aliases:
  - 项目全称
  - 项目简称
  - 英文名称
  - 常用缩写
  - 相关技术名称
```

**示例：**
```yaml
# 示例项目
aliases:
  - 项目A
  - ProjectA
  - 项目A优化
  - 技术栈名称
```

### 参数 4：现有文档迁移策略

**默认策略：** 现有文档不迁移，新文档采用新规则

**如果你想迁移现有文档：**
```
请将以下文档迁移到项目目录：
- doc/xxx.md → doc/project/<项目名>/xxx.md
- doc/yyy.md → doc/project/<项目名>/yyy.md
```

---

## 📚 核心文件模板

### 模板 1：project_identification_workflow.md

这是核心规则文件，应包含以下内容：

```markdown
---
name: 项目自动识别和文档路由工作流程
description: 当用户讨论项目或创建文档时，自动识别项目上下文并将文档路由到正确的目录
type: feedback
---

[详细的识别触发点、匹配策略、文档路由规则、边界情况处理...]
```

### 模板 2：系统级 ADR

`doc/adr/0001-multi-project-documentation-organization.md`

```markdown
# ADR 0001: 多项目文档组织架构

## 状态
已接受 (YYYY-MM-DD)

## 背景
[为什么需要这个机制]

## 决策
[采用的方案]

## 理由
[为什么采用这个方案而不是其他方案]

## 权衡
[优缺点分析]

## 后果
[正面和负面影响]
```

---

## 🧪 测试场景

配置完成后，测试以下场景确保一切正常：

### 场景 1：显式项目切换
```
用户："看一下项目A"
期望：Claude 回复确认已切换，并说明文档将创建在 doc/project/project-a/
```

### 场景 2：路径推断
```
用户："分析 src/module/core.cc 的实现"
期望：Claude 自动识别为对应项目
```

### 场景 3：关键词推断
```
用户："调用 /grill-with-docs 讨论某个技术选型的设计决策"
期望：
1. Claude 识别关键词关联到对应项目
2. 创建 ADR 到 doc/project/<项目名>/adr/0001-xxx.md
```

### 场景 4：多项目匹配
```
用户："看一下优化相关的东西"
期望：Claude 展示匹配的项目列表，让用户选择
```

### 场景 5：跨项目分析
```
用户："对比项目A和项目B的实现差异"
期望：Claude 识别为跨项目操作，文档创建在 doc/ 根目录
```

### 场景 6：CONTEXT.md 创建
```
用户："记录某个术语到项目词汇表"
期望：创建或更新 doc/project/<项目名>/CONTEXT.md
```

---

## ⚠️ 常见问题

### Q1: 项目识别错误怎么办？

**纠正方式：**
```
"不对，我说的是 <正确的项目名>"
"切换到 <项目名>"
"退出项目上下文"（清除当前项目）
```

### Q2: 文档创建在错误的目录？

**检查清单：**
1. 项目文件中的 `doc_dir` 字段是否正确
2. 是否有明确的项目上下文（会话变量是否设置）
3. 是否是跨项目文档（应该放 doc/ 根目录）

**手动纠正：**
```
"把这个文档移到 doc/project/<正确的项目名>/"
```

### Q3: Claude 没有自动识别项目？

**可能原因：**
1. 关键词不在 aliases 列表中 → 补充别名
2. 置信度太低 → 提供更多上下文信息
3. memory 文件未正确加载 → 检查 MEMORY.md 索引

**临时解决：**
```
"当前项目是 <项目名>"（显式指定）
```

### Q4: 如何添加新项目？

**步骤：**
1. 使用 `/list-pros` 或项目跟踪系统创建新项目
2. 确保新项目文件包含 `doc_dir` 和 `aliases` 字段
3. 首次创建文档时会自动创建目录结构

### Q5: 现有项目如何补充 aliases？

**编辑项目文件：**
```
"编辑 memory/project_work_xxx.md，在 aliases 字段添加：<新别名>"
```

---

## 🔄 版本历史

- **v1.0** (2026-09-25): 初始版本
  - 基础项目识别机制
  - 文档自动路由
  - grill-with-docs 集成

---

## 📖 相关资源

- **项目跟踪系统文档**：见 `/list-pros` 和 `/setup-projects` 命令
- **Domain Modeling Skill**：`mattpocock-skills:domain-modeling`
- **Grilling Skill**：`mattpocock-skills:grilling`
- **ADR 格式规范**：见 mattpocock-skills 的 ADR-FORMAT.md
- **CONTEXT.md 格式规范**：见 mattpocock-skills 的 CONTEXT-FORMAT.md

---

## 💡 提示

**第一次使用时：**
1. 复制"步骤 1"中的配置指令发送给 Claude
2. 等待配置完成
3. 测试几个场景验证功能正常
4. 根据实际使用补充项目别名

**日常使用：**
- 说话自然，不需要特意提及项目名
- Claude 会从你的对话中自动识别项目
- 如果识别错误，直接纠正即可
- 调用 skills 时无需手动指定文档路径

**最佳实践：**
- 为项目添加足够多的别名（至少 3-5 个）
- 定期更新项目的 `updated` 字段（有助于优先级排序）
- 跨项目的通用文档不要强制归类到某个项目
- CONTEXT.md 只记录真正需要解释的术语，避免过度文档化

---

**祝配置顺利！有问题随时在对话中询问 Claude。**
