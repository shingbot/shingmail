#!/usr/bin/env bash
# 安装 shingmail-skill 到 agent 的 skills 目录
# 用法: ./install.sh [目标目录]
#   默认: ${OPENCODE_SKILLS_DIR:-~/.config/opencode/skills}
set -euo pipefail

SRC_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SRC_DIR/shingmail-skill"
DEST="${1:-${OPENCODE_SKILLS_DIR:-$HOME/.config/opencode/skills}}"
TARGET="$DEST/shingmail-skill"

if [ ! -f "$SRC/SKILL.md" ] || [ ! -f "$SRC/scripts/shingmail" ]; then
  echo "安装失败：当前目录缺少 shingmail-skill/SKILL.md 或 scripts/shingmail" >&2
  exit 1
fi

mkdir -p "$DEST"
rm -rf "$TARGET"
cp -R "$SRC" "$TARGET"
find "$TARGET" -name '.DS_Store' -delete 2>/dev/null || true
chmod +x "$TARGET/scripts/shingmail"

echo "已安装: $TARGET"
echo
echo "下一步:"
echo "  $TARGET/scripts/shingmail init --token '<agent-token>'"
echo "  $TARGET/scripts/shingmail settings"