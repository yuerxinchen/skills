#!/bin/bash
# Project Tracker - 项目跟踪系统核心脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 获取当前工作目录的hash
get_workdir_hash() {
    echo -n "$PWD" | md5sum | cut -d' ' -f1 2>/dev/null || echo -n "$PWD" | md5 | cut -d' ' -f1
}

# 获取配置文件路径
get_config_path() {
    local workdir_hash=$(get_workdir_hash)
    echo "$HOME/.claude/projects/$workdir_hash/project-tracker-config.json"
}

# 智能检测默认目录
detect_default_dir() {
    local workdir_hash=$(get_workdir_hash)
    local memory_dir="$HOME/.claude/projects/$workdir_hash/memory"

    if [ -d "$memory_dir" ]; then
        echo "$memory_dir"
    else
        echo "$PWD/.projects"
    fi
}

# 读取配置
read_config() {
    local config_file=$(get_config_path)
    if [ -f "$config_file" ]; then
        cat "$config_file"
    else
        # 返回默认配置
        local default_dir=$(detect_default_dir)
        echo "{\"project_dir\": \"$default_dir\"}"
    fi
}

# 获取项目目录
get_project_dir() {
    local config=$(read_config)
    echo "$config" | grep -o '"project_dir"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)".*/\1/'
}

# 保存配置
save_config() {
    local project_dir="$1"
    local config_file=$(get_config_path)
    local config_dir=$(dirname "$config_file")

    mkdir -p "$config_dir"
    echo "{\"project_dir\": \"$project_dir\"}" > "$config_file"
}

# 初始化项目目录
init_project_dir() {
    local project_dir="$1"

    mkdir -p "$project_dir"

    # 检查是否已有MEMORY.md（集成模式）
    if [ -f "$project_dir/MEMORY.md" ]; then
        echo -e "${GREEN}✓ 检测到现有MEMORY.md，集成模式${NC}"
        # 确保有"项目跟踪"章节
        if ! grep -q "## 项目跟踪" "$project_dir/MEMORY.md"; then
            echo "" >> "$project_dir/MEMORY.md"
            echo "## 项目跟踪" >> "$project_dir/MEMORY.md"
            echo "" >> "$project_dir/MEMORY.md"
            echo -e "${GREEN}✓ 已添加'项目跟踪'章节到MEMORY.md${NC}"
        fi
    else
        # 创建独立的PROJECTS.md
        if [ ! -f "$project_dir/PROJECTS.md" ]; then
            cat > "$project_dir/PROJECTS.md" << 'EOF'
# 项目跟踪索引

## 进行中的项目

## 已完成的项目

## 计划中的项目

## 已归档的项目
EOF
            echo -e "${GREEN}✓ 已创建PROJECTS.md索引文件${NC}"
        fi
    fi
}

# 命令：setup-projects
cmd_setup() {
    local arg="$1"

    if [ -z "$arg" ]; then
        # 显示当前配置
        local project_dir=$(get_project_dir)
        echo -e "${BLUE}当前配置：${NC}"
        echo "  项目目录: $project_dir"
        if [ -d "$project_dir" ]; then
            echo -e "  状态: ${GREEN}已初始化${NC}"
        else
            echo -e "  状态: ${YELLOW}未初始化${NC}"
        fi
    elif [ "$arg" = "--reset" ]; then
        # 重置配置
        local config_file=$(get_config_path)
        rm -f "$config_file"
        echo -e "${GREEN}✓ 配置已重置为默认值${NC}"
        cmd_setup ""
    elif [ "$arg" = "--init" ]; then
        # 初始化当前配置的目录
        local project_dir=$(get_project_dir)
        init_project_dir "$project_dir"
        echo -e "${GREEN}✓ 项目目录已初始化: $project_dir${NC}"
    else
        # 设置新目录并初始化
        local new_dir=$(cd "$arg" && pwd)  # 转换为绝对路径
        save_config "$new_dir"
        init_project_dir "$new_dir"
        echo -e "${GREEN}✓ 项目目录已设置并初始化: $new_dir${NC}"
    fi
}

# 解析frontmatter
parse_frontmatter() {
    local file="$1"
    local field="$2"

    awk -v field="$field" '
        BEGIN { in_frontmatter=0 }
        /^---$/ { in_frontmatter++; next }
        in_frontmatter == 1 && $0 ~ "^" field ":" {
            sub("^" field ":[[:space:]]*", "")
            print
            exit
        }
    ' "$file"
}

# 列出项目
cmd_list() {
    local status_filter="$1"
    local detail_mode=0

    # 检查是否有--detail参数
    if [ "$status_filter" = "--detail" ] || [ "$2" = "--detail" ]; then
        detail_mode=1
        if [ "$status_filter" = "--detail" ]; then
            status_filter=""
        fi
    fi

    local project_dir=$(get_project_dir)

    if [ ! -d "$project_dir" ]; then
        echo -e "${RED}✗ 项目目录不存在: $project_dir${NC}"
        echo "请先运行: /setup-projects"
        return 1
    fi

    # 查找所有project_work类型的文件
    local project_files=()
    while IFS= read -r -d '' file; do
        local type=$(parse_frontmatter "$file" "type")
        if [ "$type" = "project_work" ]; then
            project_files+=("$file")
        fi
    done < <(find "$project_dir" -maxdepth 1 -name "*.md" -type f -print0)

    if [ ${#project_files[@]} -eq 0 ]; then
        echo -e "${YELLOW}没有找到任何项目${NC}"
        return 0
    fi

    # 标准模式：表格输出
    if [ $detail_mode -eq 0 ]; then
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        printf "%-30s %-12s %-15s %s\n" "项目名称" "状态" "更新时间" "描述"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

        for file in "${project_files[@]}"; do
            local name=$(parse_frontmatter "$file" "name")
            local status=$(parse_frontmatter "$file" "status")
            local updated=$(parse_frontmatter "$file" "updated")
            local desc=$(parse_frontmatter "$file" "description")

            # 状态过滤
            if [ -n "$status_filter" ] && [ "$status_filter" != "all" ] && [ "$status" != "$status_filter" ]; then
                continue
            fi

            # 状态颜色
            local status_colored="$status"
            case "$status" in
                active)
                    status_colored="${GREEN}$status${NC}"
                    ;;
                completed)
                    status_colored="${BLUE}$status${NC}"
                    ;;
                pending)
                    status_colored="${YELLOW}$status${NC}"
                    ;;
                archived)
                    status_colored="${RED}$status${NC}"
                    ;;
            esac

            printf "%-30s %-20s %-15s %s\n" "$name" "$status_colored" "$updated" "$desc"
        done

        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo "总计: ${#project_files[@]} 个项目"
    else
        # 详细模式
        for file in "${project_files[@]}"; do
            local name=$(parse_frontmatter "$file" "name")
            local status=$(parse_frontmatter "$file" "status")
            local created=$(parse_frontmatter "$file" "created")
            local updated=$(parse_frontmatter "$file" "updated")
            local desc=$(parse_frontmatter "$file" "description")

            # 状态过滤
            if [ -n "$status_filter" ] && [ "$status_filter" != "all" ] && [ "$status" != "$status_filter" ]; then
                continue
            fi

            echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "📋 ${GREEN}项目${NC}: $name"
            echo -e "状态: $status"
            echo -e "创建: $created | 更新: $updated"
            echo -e "描述: $desc"

            # 提取文件列表
            echo -e "\n📁 ${YELLOW}相关文件${NC}:"
            awk '/^files:$/,/^[a-z]/ {
                if ($0 ~ /^[[:space:]]*-/) {
                    sub(/^[[:space:]]*-[[:space:]]*/, "")
                    print "  - " $0
                }
            }' "$file"

            # 提取标签
            echo -e "\n🏷️  ${YELLOW}标签${NC}:"
            awk '/^tags:$/,/^[a-z]/ {
                if ($0 ~ /^[[:space:]]*-/) {
                    sub(/^[[:space:]]*-[[:space:]]*/, "")
                    printf "%s ", $0
                }
            }' "$file"
            echo ""

            # 显示正文内容（跳过frontmatter）
            echo -e "\n📝 ${YELLOW}详细说明${NC}:"
            awk 'BEGIN{p=0} /^---$/{p++; next} p==2{print}' "$file" | head -20
        done
        echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    fi
}

# 导出项目
cmd_export() {
    local output_file="$1"

    if [ -z "$output_file" ]; then
        echo -e "${RED}✗ 请指定输出文件路径${NC}"
        echo "用法: /export-projects <output-file>"
        return 1
    fi

    local project_dir=$(get_project_dir)

    if [ ! -d "$project_dir" ]; then
        echo -e "${RED}✗ 项目目录不存在${NC}"
        return 1
    fi

    # 创建临时目录
    local temp_dir=$(mktemp -d)
    local export_dir="$temp_dir/project-tracker-export"
    mkdir -p "$export_dir"

    # 复制所有project_work文件
    find "$project_dir" -maxdepth 1 -name "*.md" -type f | while read file; do
        local type=$(parse_frontmatter "$file" "type")
        if [ "$type" = "project_work" ]; then
            cp "$file" "$export_dir/"
        fi
    done

    # 复制MEMORY.md或PROJECTS.md
    if [ -f "$project_dir/MEMORY.md" ]; then
        cp "$project_dir/MEMORY.md" "$export_dir/"
    elif [ -f "$project_dir/PROJECTS.md" ]; then
        cp "$project_dir/PROJECTS.md" "$export_dir/"
    fi

    # 创建元数据文件
    cat > "$export_dir/export-metadata.json" << EOF
{
    "export_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "source_dir": "$project_dir",
    "version": "1.0"
}
EOF

    # 打包
    tar -czf "$output_file" -C "$temp_dir" "project-tracker-export"

    # 清理
    rm -rf "$temp_dir"

    echo -e "${GREEN}✓ 项目数据已导出到: $output_file${NC}"
}

# 导入项目
cmd_import() {
    local input_file="$1"

    if [ -z "$input_file" ]; then
        echo -e "${RED}✗ 请指定输入文件路径${NC}"
        echo "用法: /import-projects <input-file>"
        return 1
    fi

    if [ ! -f "$input_file" ]; then
        echo -e "${RED}✗ 文件不存在: $input_file${NC}"
        return 1
    fi

    local project_dir=$(get_project_dir)

    # 创建目标目录
    mkdir -p "$project_dir"

    # 创建临时目录
    local temp_dir=$(mktemp -d)

    # 解压
    tar -xzf "$input_file" -C "$temp_dir"

    # 复制文件
    local import_dir="$temp_dir/project-tracker-export"
    if [ -d "$import_dir" ]; then
        cp -r "$import_dir"/*.md "$project_dir/" 2>/dev/null || true
        echo -e "${GREEN}✓ 项目数据已导入到: $project_dir${NC}"

        # 显示元数据
        if [ -f "$import_dir/export-metadata.json" ]; then
            echo -e "${BLUE}导出信息:${NC}"
            cat "$import_dir/export-metadata.json"
        fi

        # 自动更新索引
        update_index
    else
        echo -e "${RED}✗ 无效的导出文件${NC}"
    fi

    # 清理
    rm -rf "$temp_dir"
}

# 更新索引文件
update_index() {
    local project_dir=$(get_project_dir)
    local index_file=""

    # 判断使用哪个索引文件
    if [ -f "$project_dir/MEMORY.md" ]; then
        index_file="$project_dir/MEMORY.md"
    elif [ -f "$project_dir/PROJECTS.md" ]; then
        index_file="$project_dir/PROJECTS.md"
    else
        echo -e "${YELLOW}没有找到索引文件，跳过更新${NC}"
        return 0
    fi

    echo -e "${BLUE}正在更新索引...${NC}"

    # 备份索引文件
    cp "$index_file" "$index_file.backup"

    # 查找所有project_work文件
    local project_files=()
    while IFS= read -r -d '' file; do
        local type=$(parse_frontmatter "$file" "type")
        if [ "$type" = "project_work" ]; then
            project_files+=("$file")
        fi
    done < <(find "$project_dir" -maxdepth 1 -name "project_work_*.md" -type f -print0)

    if [ ${#project_files[@]} -eq 0 ]; then
        echo -e "${YELLOW}没有找到项目文件${NC}"
        return 0
    fi

    # 生成新的项目跟踪章节内容
    local new_entries=""
    for file in "${project_files[@]}"; do
        local name=$(parse_frontmatter "$file" "name")
        local status=$(parse_frontmatter "$file" "status")
        local desc=$(parse_frontmatter "$file" "description")
        local filename=$(basename "$file")

        new_entries+="- [$name]($filename) — $status | $desc"$'\n'
    done

    # 更新MEMORY.md或PROJECTS.md
    if [ -f "$project_dir/MEMORY.md" ]; then
        # 使用awk更新"## 项目跟踪"章节
        awk -v new_content="$new_entries" '
            BEGIN { in_section=0; printed=0 }
            /^## 项目跟踪$/ {
                print $0
                print ""
                printf "%s", new_content
                in_section=1
                printed=1
                next
            }
            /^##[[:space:]]/ && in_section==1 {
                in_section=0
            }
            in_section==0 { print }
        ' "$index_file" > "$index_file.tmp"
        mv "$index_file.tmp" "$index_file"
    fi

    echo -e "${GREEN}✓ 索引已更新${NC}"
}

# 创建新项目
cmd_create() {
    local project_name="$1"

    if [ -z "$project_name" ]; then
        echo -e "${RED}✗ 请提供项目名称${NC}"
        echo "用法: project-tracker.sh create <项目名称>"
        return 1
    fi

    local project_dir=$(get_project_dir)

    if [ ! -d "$project_dir" ]; then
        echo -e "${RED}✗ 项目目录不存在: $project_dir${NC}"
        echo "请先运行: /setup-projects"
        return 1
    fi

    # 生成文件名（转换为slug）
    local slug=$(echo "$project_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_')
    local filename="project_work_${slug}.md"
    local filepath="$project_dir/$filename"

    if [ -f "$filepath" ]; then
        echo -e "${RED}✗ 项目文件已存在: $filename${NC}"
        return 1
    fi

    # 交互式输入
    echo -e "${BLUE}创建新项目: $project_name${NC}"
    echo ""

    read -p "简短描述: " description
    echo ""
    echo "初始状态:"
    echo "  1) pending  - 计划中"
    echo "  2) active   - 进行中"
    read -p "选择 [1-2, 默认1]: " status_choice

    local status="pending"
    if [ "$status_choice" = "2" ]; then
        status="active"
    fi

    read -p "标签 (逗号分隔，可选): " tags_input

    # 处理标签
    local tags_yaml=""
    if [ -n "$tags_input" ]; then
        tags_yaml="tags:"$'\n'
        IFS=',' read -ra TAGS <<< "$tags_input"
        for tag in "${TAGS[@]}"; do
            tag=$(echo "$tag" | xargs) # trim空格
            tags_yaml+="  - $tag"$'\n'
        done
    fi

    local today=$(date +%Y-%m-%d)

    # 创建项目文件
    cat > "$filepath" << EOF
---
name: $project_name
description: $description
type: project_work
status: $status
created: $today
updated: $today
${tags_yaml}---

## 项目背景

TODO: 描述项目背景和目标

## 当前进展

### 已完成
- ✅ 项目立项

### 进行中
- 🔄 TODO

### 待完成
- ⏳ TODO

## 相关资源

- 文档：
- 代码：

---

最后更新：$today
EOF

    echo ""
    echo -e "${GREEN}✓ 项目已创建: $filepath${NC}"
    echo ""

    # 自动更新索引
    update_index

    echo ""
    echo -e "${BLUE}提示：${NC}"
    echo "  • 使用编辑器打开: vi $filepath"
    echo "  • 查看项目列表: /list-pros"
    echo "  • 查看项目详情: /list-pros --detail"
}

# 主函数
main() {
    local command="$1"
    shift

    case "$command" in
        setup)
            cmd_setup "$@"
            ;;
        list)
            cmd_list "$@"
            ;;
        export)
            cmd_export "$@"
            ;;
        import)
            cmd_import "$@"
            ;;
        create)
            cmd_create "$@"
            ;;
        update-index)
            update_index
            ;;
        *)
            echo -e "${RED}✗ 未知命令: $command${NC}"
            echo "可用命令: setup, list, export, import, create, update-index"
            return 1
            ;;
    esac
}

main "$@"
