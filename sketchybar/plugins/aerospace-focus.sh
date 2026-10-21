#!/bin/bash

SKETCHYBAR=/opt/homebrew/bin/sketchybar

# Keep the switch hot path to direct SketchyBar updates. The full
# reconciliation (per-monitor placement, the dim pill on other monitors, app
# icons, items for new workspaces) is dispatched only after focus is painted.
# Two calls, because a --set on a missing item aborts the rest of its call.
# H (minimised windows) is never shown, even while focus passes through it.
[[ "$AEROSPACE_FOCUSED_WORKSPACE" == H ]] || $SKETCHYBAR --set "space.$AEROSPACE_FOCUSED_WORKSPACE" \
  drawing=on \
  background.drawing=on \
  background.color=0x40ffffff \
  icon.color=0xffffffff
if [[ -n "$AEROSPACE_PREV_WORKSPACE" ]]; then
  $SKETCHYBAR --set "space.$AEROSPACE_PREV_WORKSPACE" background.drawing=off icon.color=0x99ebebf5
fi

$SKETCHYBAR --trigger aerospace_workspace_refresh >/dev/null 2>&1 &
