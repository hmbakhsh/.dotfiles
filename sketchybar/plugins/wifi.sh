#!/bin/bash

SKETCHYBAR=/opt/homebrew/bin/sketchybar
device=$(/usr/sbin/networksetup -listallhardwareports | /usr/bin/awk '/Hardware Port: (Wi-Fi|AirPort)/ { getline; print $2; exit }')

if [[ -n "$device" ]] && /usr/sbin/ipconfig getifaddr "$device" >/dev/null 2>&1; then
  color=0xffffffff
else
  color=0xff9ca3af
fi

$SKETCHYBAR --set "$NAME" icon.color="$color"
