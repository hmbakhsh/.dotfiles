#!/bin/bash

# Dark mode gets a near-opaque bar so a bright wallpaper can't wash it out;
# light mode keeps the lighter translucent glass. For time-based switching set
# System Settings > Appearance to Auto; this follows whatever macOS picks.
if [[ "$(/usr/bin/defaults read -g AppleInterfaceStyle 2>/dev/null)" == Dark ]]; then
  /opt/homebrew/bin/sketchybar --bar color=0xf20b0b0d blur_radius=30
else
  /opt/homebrew/bin/sketchybar --bar color=0xd9161618 blur_radius=30
fi
