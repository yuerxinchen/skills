#!/bin/bash
# NN Skills 测试脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
PASS_COUNT=0
FAIL_COUNT=0

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  NN Skills 测试${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 测试函数
test_case() {
    local name="$1"
    local command="$2"

    echo -e "${BLUE}测试：${NC}$name"
    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}  ✓ 通过${NC}"
        ((PASS_COUNT++))
        return 0
    else
        echo -e "${RED}  ✗ 失败${NC}"
        ((FAIL_COUNT++))
        return 1
    fi
}

# 1. 检查文件存在
echo -e "${YELLOW}[1/4] 文件检查${NC}"
test_case "project-tracker SKILL.md" "[ -f '$CLAUDE_SKILLS_DIR/project-tracker/SKILL.md' ]"
test_case "project-tracker.sh" "[ -f '$CLAUDE_SKILLS_DIR/project-tracker/project-tracker.sh' ]"
test_case "list-pros SKILL.md" "[ -f '$CLAUDE_SKILLS_DIR/list-pros/SKILL.md' ]"
echo ""

# 2. 检查可执行权限
echo -e "${YELLOW}[2/4] 权限检查${NC}"
test_case "project-tracker.sh 可执行" "[ -x '$CLAUDE_SKILLS_DIR/project-tracker/project-tracker.sh' ]"
test_case "handler.sh 可执行" "[ -x '$CLAUDE_SKILLS_DIR/project-tracker/handler.sh' ]"
echo ""

# 3. 功能测试
echo -e "${YELLOW}[3/4] 功能测试${NC}"
test_case "setup命令" "$CLAUDE_SKILLS_DIR/project-tracker/project-tracker.sh setup"
test_case "list命令" "$CLAUDE_SKILLS_DIR/project-tracker/project-tracker.sh list"
echo ""

# 4. SKILL.md格式检查
echo -e "${YELLOW}[4/4] 格式检查${NC}"
test_case "SKILL.md有frontmatter" "grep -q '^---$' '$CLAUDE_SKILLS_DIR/list-pros/SKILL.md'"
test_case "SKILL.md有name字段" "grep -q '^name:' '$CLAUDE_SKILLS_DIR/list-pros/SKILL.md'"
test_case "SKILL.md有description字段" "grep -q '^description:' '$CLAUDE_SKILLS_DIR/list-pros/SKILL.md'"
echo ""

# 总结
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}✓ 所有测试通过！${NC} ($PASS_COUNT/$((PASS_COUNT + FAIL_COUNT)))"
else
    echo -e "${RED}✗ 部分测试失败${NC}"
    echo -e "  通过: ${GREEN}$PASS_COUNT${NC}"
    echo -e "  失败: ${RED}$FAIL_COUNT${NC}"
fi
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

exit $FAIL_COUNT
