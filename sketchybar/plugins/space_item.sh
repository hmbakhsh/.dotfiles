#!/bin/bash
# Properties for one AeroSpace workspace item. Sourced by sketchybarrc (items
# for workspaces that exist at startup) and aerospace.sh (items for workspaces
# created later, e.g. 11).

space_item_props() {
  local sid="$1"
  SPACE_ITEM_PROPS=(
    icon="$sid"
    icon.font="JetBrains Mono:Bold:16.0"
    icon.padding_left=8
    icon.padding_right=8
    label.font="sketchybar-app-font:Regular:16.0"
    label.color=0xffc5cece
    label.padding_left=1
    label.padding_right=8
    label.drawing=off
    background.color=0x55ffffff
    background.corner_radius=6
    background.height=26
    background.drawing=off
    click_script="/opt/homebrew/bin/aerospace workspace $sid"
  )
}
