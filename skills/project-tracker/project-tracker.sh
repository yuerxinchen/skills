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
    else
        echo -e "${RED}✗ 无效的导出文件${NC}"
    fi

    # 清理
    rm -rf "$temp_dir"
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
        *)
            echo -e "${RED}✗ 未知命令: $command${NC}"
            echo "可用命令: setup, list, export, import"
            return 1
            ;;
    esac
}

main "$@"
