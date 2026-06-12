#!/usr/bin/env bash
# Symlink agents/*.md into ~/.claude/agents/ so repo edits go live immediately.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${HOME}/.claude/agents"
mkdir -p "$TARGET_DIR"

for src in "$REPO_DIR"/agents/*.md; do
  name="$(basename "$src")"
  dest="$TARGET_DIR/$name"
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    echo "backup: $dest -> $dest.bak"
    mv "$dest" "$dest.bak"
  fi
  ln -sfn "$src" "$dest"
  echo "linked: $dest -> $src"
done
