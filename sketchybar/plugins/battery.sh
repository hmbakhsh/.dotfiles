#!/bin/bash

SKETCHYBAR=/opt/homebrew/bin/sketchybar
battery_info=$(/usr/bin/pmset -g batt)
percentage=$(printf '%s' "$battery_info" | /usr/bin/grep -Eo '[0-9]+%' | /usr/bin/head -1 | /usr/bin/tr -d '%')

[[ -n "$percentage" ]] || exit 0

charging=false
if printf '%s' "$battery_info" | /usr/bin/grep -q "AC Power"; then
  charging=true
fi

level=$((percentage / 10 * 10))
(( percentage == 100 )) && level=100

if [[ "$charging" == true ]]; then
  codepoint=$((0xE010 + level / 10))
  color=0xffa6e3a1
else
  codepoint=$((0xE000 + level / 10))
  if (( percentage <= 20 )); then
    color=0xffff6b6b
  elif (( percentage <= 40 )); then
    color=0xffffc857
  else
    color=0xffffffff
  fi
fi

icon=$(/usr/bin/perl -CSD -e 'print chr(shift)' "$codepoint")

$SKETCHYBAR --set "$NAME" \
  icon="$icon" \
  icon.color="$color" \
  label="${percentage}%"
