#!/bin/bash
# Properties for one AeroSpace workspace item. Sourced by sketchybarrc (items
# for workspaces that exist at startup) and aerospace.sh (items for workspaces
# created later, e.g. 11).

space_item_props() {
  local sid="$1" label="$1"
  # 11-20 are the second monitor's 1-10 (see ~/.config/aerospace/ws.sh).
  [[ "$sid" =~ ^[0-9]+$ ]] && (( sid > 10 )) && label=$((sid - 10))
  SPACE_ITEM_PROPS=(
    icon="$label"
    icon.font="SF Pro Rounded:Semibold:14.0"
    icon.padding_left=9
    icon.padding_right=9
    label.font="sketchybar-app-font:Regular:16.0"
    label.color=0xd9ffffff
    label.padding_left=1
    label.padding_right=8
    label.drawing=off
    background.color=0x40ffffff
    background.corner_radius=8
    background.height=24
    background.drawing=off
    click_script="/opt/homebrew/bin/aerospace workspace $sid"
  )
}
