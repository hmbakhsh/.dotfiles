#!/bin/bash

SKETCHYBAR=/opt/homebrew/bin/sketchybar

# Keep the switch hot path to a single direct SketchyBar update. The full
# reconciliation (per-monitor placement, the dim pill on other monitors, app
# icons) is dispatched only after focus is painted.
args=()
if [[ -n "$AEROSPACE_PREV_WORKSPACE" ]]; then
  args+=(--set "space.$AEROSPACE_PREV_WORKSPACE" background.drawing=off icon.color=0xff9ca3af)
fi
args+=(--set "space.$AEROSPACE_FOCUSED_WORKSPACE"
  drawing=on
  background.drawing=on
  background.color=0x55ffffff
  icon.color=0xffffffff)

$SKETCHYBAR "${args[@]}"

$SKETCHYBAR --trigger aerospace_workspace_refresh >/dev/null 2>&1 &
