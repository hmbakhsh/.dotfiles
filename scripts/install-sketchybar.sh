#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_dir="$repo/sketchybar"
target="$HOME/.config/sketchybar"

mkdir -p "$HOME/.config"

if [[ -e "$target" && ! -L "$target" ]]; then
  echo "$target already exists and is not a symlink" >&2
  exit 1
fi

ln -sfn "$source_dir" "$target"
"$source_dir/plugins/build-status-font.py"

if command -v sketchybar >/dev/null 2>&1; then
  sketchybar --reload
fi
