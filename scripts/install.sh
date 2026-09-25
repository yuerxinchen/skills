#!/bin/bash
# NN Skills 安装脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  NN Skills 安装程序${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 检查目标目录
CLAUDE_SKILLS_DIR="$HOME/.claude/skills"

if [ ! -d "$CLAUDE_SKILLS_DIR" ]; then
    echo -e "${YELLOW}创建 Claude skills 目录...${NC}"
    mkdir -p "$CLAUDE_SKILLS_DIR"
fi

# 安装 project-tracker
echo -e "${BLUE}[1/3]${NC} 安装 project-tracker skill..."
if [ -d "$CLAUDE_SKILLS_DIR/project-tracker" ]; then
    echo -e "${YELLOW}  已存在，备份旧版本...${NC}"
    mv "$CLAUDE_SKILLS_DIR/project-tracker" "$CLAUDE_SKILLS_DIR/project-tracker.backup.$(date +%s)"
fi

cp -r "$PROJECT_ROOT/skills/project-tracker" "$CLAUDE_SKILLS_DIR/"
chmod +x "$CLAUDE_SKILLS_DIR/project-tracker/"*.sh
echo -e "${GREEN}  ✓ project-tracker 已安装${NC}"

# 安装 list-pros
echo -e "${BLUE}[2/3]${NC} 安装 list-pros skill..."
if [ -d "$CLAUDE_SKILLS_DIR/list-pros" ]; then
    echo -e "${YELLOW}  已存在，备份旧版本...${NC}"
    mv "$CLAUDE_SKILLS_DIR/list-pros" "$CLAUDE_SKILLS_DIR/list-pros.backup.$(date +%s)"
fi

cp -r "$PROJECT_ROOT/skills/list-pros" "$CLAUDE_SKILLS_DIR/"
chmod +x "$CLAUDE_SKILLS_DIR/list-pros/"*.sh 2>/dev/null || true
echo -e "${GREEN}  ✓ list-pros 已安装${NC}"

# 初始化配置
echo -e "${BLUE}[3/3]${NC} 初始化配置..."
if [ -x "$CLAUDE_SKILLS_DIR/project-tracker/project-tracker.sh" ]; then
    "$CLAUDE_SKILLS_DIR/project-tracker/project-tracker.sh" setup 2>/dev/null || true
    echo -e "${GREEN}  ✓ 配置已初始化${NC}"
else
    echo -e "${YELLOW}  跳过配置初始化（首次使用时会自动配置）${NC}"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ 安装完成！${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "安装位置："
echo "  • $CLAUDE_SKILLS_DIR/project-tracker/"
echo "  • $CLAUDE_SKILLS_DIR/list-pros/"
echo ""
echo "现在可以在 Claude Code 中使用："
echo ""
echo -e "  ${GREEN}/list-pros${NC}                    # 列出所有项目"
echo -e "  ${GREEN}/list-pros active${NC}             # 只显示进行中的项目"
echo -e "  ${GREEN}/list-pros --detail${NC}           # 详细模式"
echo ""
echo "如果命令不可用，请："
echo "  1. 等待几秒让 Claude Code 热重载 skills"
echo "  2. 或重启 Claude Code"
echo ""
echo -e "查看文档：${BLUE}cat $PROJECT_ROOT/README.md${NC}"
echo ""
