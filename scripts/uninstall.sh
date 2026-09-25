#!/bin/bash
# NN Skills 卸载脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CLAUDE_SKILLS_DIR="$HOME/.claude/skills"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  NN Skills 卸载程序${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 询问是否删除配置和数据
echo -e "${YELLOW}是否删除项目数据和配置？${NC}"
echo "  1) 仅删除 skills 代码（保留数据）"
echo "  2) 删除 skills 代码和配置文件"
echo "  3) 完全删除（包括所有项目数据）"
echo ""
read -p "请选择 [1-3]: " choice

echo ""

# 删除 skills
echo -e "${BLUE}[1/2]${NC} 删除 skills..."
if [ -d "$CLAUDE_SKILLS_DIR/project-tracker" ]; then
    rm -rf "$CLAUDE_SKILLS_DIR/project-tracker"
    echo -e "${GREEN}  ✓ project-tracker 已删除${NC}"
else
    echo -e "${YELLOW}  project-tracker 不存在${NC}"
fi

if [ -d "$CLAUDE_SKILLS_DIR/list-pros" ]; then
    rm -rf "$CLAUDE_SKILLS_DIR/list-pros"
    echo -e "${GREEN}  ✓ list-pros 已删除${NC}"
else
    echo -e "${YELLOW}  list-pros 不存在${NC}"
fi

# 删除配置和数据（根据用户选择）
if [ "$choice" = "2" ] || [ "$choice" = "3" ]; then
    echo -e "${BLUE}[2/2]${NC} 删除配置文件..."
    find "$HOME/.claude/projects" -name "project-tracker-config.json" -delete 2>/dev/null || true
    echo -e "${GREEN}  ✓ 配置文件已删除${NC}"
fi

if [ "$choice" = "3" ]; then
    echo -e "${RED}警告：即将删除所有项目数据！${NC}"
    read -p "确认删除？输入 'yes' 继续: " confirm

    if [ "$confirm" = "yes" ]; then
        echo -e "${BLUE}删除项目数据...${NC}"
        # 这里只是示例，实际需要用户确认具体路径
        echo -e "${YELLOW}  请手动删除项目数据目录${NC}"
        echo "  示例：rm -rf ~/.claude/projects/<workdir-hash>/memory/project_work_*.md"
    else
        echo -e "${YELLOW}  已取消数据删除${NC}"
    fi
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ 卸载完成！${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
