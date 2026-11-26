#!/usr/bin/env bash
# 安装 shingmail 技能到 agent 的 skills 目录
# 用法: ./install.sh [目标目录]
#   默认: ${OPENCODE_SKILLS_DIR:-~/.config/opencode/skills}
set -euo pipefail

SRC_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${1:-${OPENCODE_SKILLS_DIR:-$HOME/.config/opencode/skills}}"
TARGET="$DEST/shingmail"
LEGACY="$DEST/shingmail-skill"

if [ ! -f "$SRC_DIR/SKILL.md" ] || [ ! -f "$SRC_DIR/scripts/shingmail" ]; then
  echo "安装失败：仓库根目录缺少 SKILL.md 或 scripts/shingmail" >&2
  exit 1
fi

mkdir -p "$DEST"

# 旧版目录名为 shingmail-skill，安装新版时顺手清掉，避免同一技能两份
if [ -d "$LEGACY" ]; then
  rm -rf "$LEGACY"
  echo "已移除旧版: $LEGACY"
fi

rm -rf "$TARGET"
mkdir -p "$TARGET/scripts"
cp "$SRC_DIR/SKILL.md" "$TARGET/SKILL.md"
cp "$SRC_DIR/scripts/shingmail" "$TARGET/scripts/shingmail"
chmod +x "$TARGET/scripts/shingmail"
find "$TARGET" -name '.DS_Store' -delete 2>/dev/null || true

echo "已安装: $TARGET"
echo
echo "下一步:"
echo "  $TARGET/scripts/shingmail init --token '<agent-token>'"
echo "  $TARGET/scripts/shingmail settings"