#!/bin/sh

# front_app_switched passes the newly focused app's name in $INFO. On the
# first forced run after a (re)load there is no $INFO, so ask macOS instead.
app="$INFO"
if [ -z "$app" ]; then
  app=$(/usr/bin/lsappinfo info -only name "$(/usr/bin/lsappinfo front)" | /usr/bin/sed -n 's/.*"LSDisplayName"="\(.*\)"/\1/p')
fi

# The invisible helper Cmd-M focuses on an emptied workspace (see
# ~/.config/aerospace/focus-sink) is not an app worth naming.
[ "$app" = "AeroSpaceFocusSink" ] && app=""

sketchybar --set "$NAME" label="$app"
