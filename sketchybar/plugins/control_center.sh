#!/bin/bash

if [[ "$BUTTON" == "right" ]]; then
  /usr/bin/open 'x-apple.systempreferences:com.apple.BluetoothSettings'
  exit
fi

/usr/bin/osascript <<'APPLESCRIPT'
tell application "System Events"
  tell process "ControlCenter"
    set controlCenterItem to first menu bar item of menu bar 1 whose description starts with "Control Cent"
    perform action "AXPress" of controlCenterItem
  end tell
end tell
APPLESCRIPT
