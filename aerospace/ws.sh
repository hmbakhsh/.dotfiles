#!/bin/bash
# Per-monitor workspace numbers. AeroSpace workspaces are global, so the
# second monitor gets its own range: the main monitor uses 1-10 and the
# secondary monitor 11-20 (force-assigned in aerospace.toml). Ctrl-N goes
# to workspace N of whichever monitor is focused; SketchyBar shows 11-20
# as 1-10.
#   ws.sh focus N   switch to workspace N on the focused monitor
#   ws.sh move N    send the focused window there
#   ws.sh other     send the focused window to the first empty workspace
#                   on the next monitor and follow it

AEROSPACE=/opt/homebrew/bin/aerospace

if [[ "$1" == other ]]; then
  current=$($AEROSPACE list-monitors --focused --format '%{monitor-id}')
  monitors=($($AEROSPACE list-monitors --format '%{monitor-id}'))
  (( ${#monitors[@]} > 1 )) || exit 0
  for i in "${!monitors[@]}"; do
    [[ "${monitors[$i]}" == "$current" ]] && target=${monitors[$(( (i + 1) % ${#monitors[@]} ))]}
  done
  if [[ "$($AEROSPACE list-monitors --format '%{monitor-id}|%{monitor-is-main}' | grep "^$target|")" == *true ]]; then
    range=$(seq 1 10)
  else
    range=$(seq 11 20)
  fi
  empty=" $($AEROSPACE list-workspaces --monitor "$target" --empty | tr '\n' ' ') "
  for ws in $range; do
    if [[ "$empty" == *" $ws "* ]]; then
      $AEROSPACE move-node-to-workspace --focus-follows-window "$ws"
      /opt/homebrew/bin/sketchybar --trigger aerospace_workspace_refresh
      exit 0
    fi
  done
  exit 0
fi

n=$2
if [[ "$($AEROSPACE list-monitors --focused --format '%{monitor-is-main}')" == false ]]; then
  n=$((n + 10))
fi

case "$1" in
  focus) $HOME/.config/aerospace/compact.sh switch "$n" ;;
  move)
    $AEROSPACE move-node-to-workspace "$n"
    /opt/homebrew/bin/sketchybar --trigger aerospace_workspace_refresh
    ;;
esac
