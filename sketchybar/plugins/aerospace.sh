#!/bin/bash

AEROSPACE=/opt/homebrew/bin/aerospace
SKETCHYBAR=/opt/homebrew/bin/sketchybar
CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/icon_map.sh"

windows="$($AEROSPACE list-windows --all --format '%{workspace}%{tab}%{app-name}')"

app_icon() {
  __icon_map "$1"
  APP_ICON="$icon_result"
}

# Each workspace is drawn only on the bar of the monitor it lives on. The
# focused workspace gets the bright pill; the workspace showing on every other
# monitor gets a dim one, so each bar says what that screen is displaying.
args=()
while IFS='|' read -r workspace display visible focused; do
  # H holds "minimised" windows (see ~/.config/aerospace/minimize.sh) and has
  # no bar item.
  [[ "$workspace" == H ]] && continue

  app_icons=""
  seen_apps=" "

  while IFS=$'\t' read -r window_workspace app_name; do
    [[ "$window_workspace" == "$workspace" ]] || continue
    [[ "$seen_apps" == *" $app_name "* ]] && continue

    app_icon "$app_name"
    app_icons="${app_icons:+$app_icons }$APP_ICON"
    seen_apps="$seen_apps$app_name "
  done <<< "$windows"

  drawing=off
  if [[ -n "$app_icons" ]] || [[ "$visible" == true ]]; then
    drawing=on
  fi

  label_drawing=off
  [[ -n "$app_icons" ]] && label_drawing=on

  if [[ "$focused" == true ]]; then
    style=(background.drawing=on background.color=0x55ffffff icon.color=0xffffffff)
  elif [[ "$visible" == true ]]; then
    style=(background.drawing=on background.color=0x22ffffff icon.color=0xffffffff)
  else
    style=(background.drawing=off icon.color=0xff9ca3af)
  fi

  args+=(--set "space.$workspace"
    display="$display"
    drawing="$drawing"
    label="$app_icons"
    label.drawing="$label_drawing"
    "${style[@]}")
done < <($AEROSPACE list-workspaces --all \
  --format '%{workspace}|%{monitor-appkit-nsscreen-screens-id}|%{workspace-is-visible}|%{workspace-is-focused}')

$SKETCHYBAR "${args[@]}"
