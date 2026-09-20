#!/bin/bash

SKETCHYBAR=/opt/homebrew/bin/sketchybar
focused_workspace="$AEROSPACE_FOCUSED_WORKSPACE"

# Keep the switch hot path to a single direct SketchyBar update. The slower
# occupancy/icon reconciliation is dispatched only after focus is painted.
$SKETCHYBAR --set '/space\..*/' \
  background.drawing=off \
  icon.color=0xff9ca3af \
  --set "space.$focused_workspace" \
  drawing=on \
  background.drawing=on \
  icon.color=0xffffffff

$SKETCHYBAR --trigger aerospace_workspace_refresh >/dev/null 2>&1 &
