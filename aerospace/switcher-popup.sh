#!/bin/bash
# Opens the window switcher in a small floating Ghostty window.
# The fixed title is what the float rule in .aerospace.toml matches on.
open -na Ghostty --args \
  --title=aerospace-switcher \
  --window-width=110 --window-height=22 \
  --confirm-close-surface=false \
  -e $HOME/.config/aerospace/switcher.sh
