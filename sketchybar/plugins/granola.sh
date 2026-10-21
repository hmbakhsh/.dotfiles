#!/bin/bash

SKETCHYBAR=/opt/homebrew/bin/sketchybar

if [[ "$SENDER" == "mouse.clicked" ]]; then
  /usr/bin/open -a Granola
  exit 0
fi

if ! /usr/bin/pgrep -xq Granola; then
  $SKETCHYBAR --set "$NAME" icon.color=0x55ffffff label.drawing=off
  exit 0
fi

# Granola shows its floating "Nub" window while it is capturing a meeting.
# The window exists the rest of the time too, just off screen.
recording=$(/usr/bin/osascript -l JavaScript -e '
  ObjC.import("CoreGraphics");
  const windows = ObjC.deepUnwrap(ObjC.castRefToObject(
    $.CGWindowListCopyWindowInfo($.kCGWindowListOptionOnScreenOnly, 0)));
  windows.some(w => w.kCGWindowOwnerName === "Granola" && w.kCGWindowName === "Nub");
' 2>/dev/null)

if [[ "$recording" == "true" ]]; then
  $SKETCHYBAR --set "$NAME" icon.color=0xffff453a label="REC" label.color=0xffff453a label.drawing=on
else
  $SKETCHYBAR --set "$NAME" icon.color=0x99ebebf5 label.drawing=off
fi
