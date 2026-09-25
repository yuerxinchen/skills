#!/bin/bash
# Skill handler for project-tracker commands

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_TRACKER="$SCRIPT_DIR/project-tracker.sh"

# 解析命令
case "$1" in
    list-pros)
        shift
        "$PROJECT_TRACKER" list "$@"
        ;;
    setup-projects)
        shift
        "$PROJECT_TRACKER" setup "$@"
        ;;
    export-projects)
        shift
        "$PROJECT_TRACKER" export "$@"
        ;;
    import-projects)
        shift
        "$PROJECT_TRACKER" import "$@"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Available commands: list-pros, setup-projects, export-projects, import-projects"
        exit 1
        ;;
esac
