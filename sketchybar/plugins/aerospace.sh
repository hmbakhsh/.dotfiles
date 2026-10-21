#!/bin/bash

AEROSPACE=/opt/homebrew/bin/aerospace
SKETCHYBAR=/opt/homebrew/bin/sketchybar
CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/icon_map.sh"
source "$CONFIG_DIR/plugins/space_item.sh"

windows="$($AEROSPACE list-windows --all --format '%{workspace}%{tab}%{app-name}')"

app_icon() {
  __icon_map "$1"
  APP_ICON="$icon_result"
}

# Items that exist now. Workspaces created after startup (e.g. 11) get an
# item added below; a --set on a missing item would abort the whole batch.
existing=" $($SKETCHYBAR --query bar | /usr/bin/grep -o '"space\.[^"]*"' | /usr/bin/tr -d '"' | /usr/bin/tr '\n' ' ') "

# Each workspace is drawn only on the bar of the monitor it lives on. The
# focused workspace gets the bright pill; the workspace showing on every other
# monitor gets a dim one, so each bar says what that screen is displaying.
args=()
seen=" "
order=()
while IFS='|' read -r workspace display visible focused; do
  seen="$seen$workspace "

  if [[ "$existing" != *" space.$workspace "* ]]; then
    space_item_props "$workspace"
    args+=(--add item "space.$workspace" left
      --set "space.$workspace" "${SPACE_ITEM_PROPS[@]}")
  fi
  order+=("space.$workspace")

  # H holds "minimised" windows (see ~/.config/aerospace/minimize.sh) and is
  # never shown.
  if [[ "$workspace" == H ]]; then
    args+=(--set space.H drawing=off)
    continue
  fi

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
    style=(background.drawing=on background.color=0x40ffffff icon.color=0xffffffff)
  elif [[ "$visible" == true ]]; then
    style=(background.drawing=on background.color=0x1fffffff icon.color=0xffffffff)
  else
    style=(background.drawing=off icon.color=0x99ebebf5)
  fi

  args+=(--set "space.$workspace"
    display="$display"
    drawing="$drawing"
    label="$app_icons"
    label.drawing="$label_drawing"
    "${style[@]}")
done < <($AEROSPACE list-workspaces --all \
  --format '%{workspace}|%{monitor-appkit-nsscreen-screens-id}|%{workspace-is-visible}|%{workspace-is-focused}')

# Hide items for workspaces that no longer exist (empty, non-persistent).
for item in $existing; do
  [[ "$seen" == *" ${item#space.} "* ]] && continue
  args+=(--set "$item" drawing=off)
  order+=("$item")
done

# New items land at the end of the left side; put every workspace item back
# in AeroSpace's order (hidden leftovers last), ahead of the other left items.
# --reorder only shuffles the slots of the items it is given, so list them all.
args+=(--reorder "${order[@]}" aerospace_workspace_listener)

$SKETCHYBAR "${args[@]}"
