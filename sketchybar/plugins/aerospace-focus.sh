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
  # The workspace just left disappears at once if it's empty (no app icons)
  # and not still showing on another monitor, instead of waiting for the
  # debounced full refresh.
  prev_drawing=on
  if [[ "$($SKETCHYBAR --query "space.$AEROSPACE_PREV_WORKSPACE" 2>/dev/null)" == *'"label": {'*'"value": ""'* ]] &&
     ! /opt/homebrew/bin/aerospace list-workspaces --monitor all --visible | /usr/bin/grep -qx "$AEROSPACE_PREV_WORKSPACE"; then
    prev_drawing=off
  fi
  $SKETCHYBAR --set "space.$AEROSPACE_PREV_WORKSPACE" drawing="$prev_drawing" background.drawing=off icon.color=0x99ebebf5
fi

$SKETCHYBAR --trigger aerospace_workspace_refresh >/dev/null 2>&1 &
