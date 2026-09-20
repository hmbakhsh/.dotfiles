#!/bin/bash

AEROSPACE=/opt/homebrew/bin/aerospace
SKETCHYBAR=/opt/homebrew/bin/sketchybar
CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/icon_map.sh"

focused_workspace="${FOCUSED_WORKSPACE:-$($AEROSPACE list-workspaces --focused)}"

# Paint focus first. Workspace enumeration happens below, but should never
# delay the visible response to an AeroSpace focus change.
$SKETCHYBAR --set '/space\..*/' \
  background.drawing=off \
  icon.color=0xff9ca3af \
  --set "space.$focused_workspace" \
  drawing=on \
  background.drawing=on \
  icon.color=0xffffffff

windows="$($AEROSPACE list-windows --all --format '%{workspace}%{tab}%{app-name}')"

app_icon() {
  __icon_map "$1"
  APP_ICON="$icon_result"
}

args=()
while IFS= read -r workspace; do
  drawing=off
  app_icons=""
  seen_apps=" "

  while IFS=$'\t' read -r window_workspace app_name; do
    [[ "$window_workspace" == "$workspace" ]] || continue
    [[ "$seen_apps" == *" $app_name "* ]] && continue

    app_icon "$app_name"
    app_icons="${app_icons:+$app_icons }$APP_ICON"
    seen_apps="$seen_apps$app_name "
  done <<< "$windows"

  if [[ -n "$app_icons" ]] || [[ "$workspace" == "$focused_workspace" ]]; then
    drawing=on
  fi

  label_drawing=off
  [[ -n "$app_icons" ]] && label_drawing=on

  args+=(--set "space.$workspace"
    drawing="$drawing"
    label="$app_icons"
    label.drawing="$label_drawing")
done < <($AEROSPACE list-workspaces --all)

$SKETCHYBAR "${args[@]}"
