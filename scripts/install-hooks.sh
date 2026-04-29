#!/bin/bash
#
# 安装 Git Hooks
# 将仓库内 scripts/git-hooks/ 设置为 Git hooks 目录

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "⚙️  配置 Git hooks..."
cd "$REPO_ROOT"
git config core.hooksPath scripts/git-hooks

echo "✔ Git hooks 已激活 (scripts/git-hooks/)"
echo "  • pre-commit  → SwiftLint + SwiftFormat 检查"
echo "  • commit-msg  → Conventional Commits 格式校验"

# 检查工具是否安装
MISSING=""
if ! command -v swiftlint &>/dev/null; then
    MISSING="$MISSING swiftlint"
fi
if ! command -v swiftformat &>/dev/null; then
    MISSING="$MISSING swiftformat"
fi

if [ -n "$MISSING" ]; then
    echo ""
    echo "⚠  Missing tools:$MISSING"
    echo "   Install: brew install$MISSING"
fi
