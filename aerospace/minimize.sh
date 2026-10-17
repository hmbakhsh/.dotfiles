#!/bin/bash
# Instant "minimise" for AeroSpace: park windows on hidden workspace H instead
# of using the macOS Dock animation.
#   minimize.sh hide     park the focused window
#   minimize.sh restore  bring the most recently parked window back here

AEROSPACE=/opt/homebrew/bin/aerospace
HIDDEN=H
STACK="$HOME/.cache/aerospace-minimized"
mkdir -p "$(dirname "$STACK")"
touch "$STACK"

case "$1" in
  hide)
    id=$($AEROSPACE list-windows --focused --format '%{window-id}') || exit 0
    $AEROSPACE move-node-to-workspace --window-id "$id" "$HIDDEN"
    echo "$id" >> "$STACK"
    # If that emptied the workspace, macOS keeps the parked app frontmost, so
    # a Dock click or Raycast launch is a no-op. Hand focus to an invisible
    # helper app so reactivating the parked app is a focus change AeroSpace
    # sees. Not Finder: Finder in front shows the auto-hidden menu bar.
    # Helper source: focus-sink/ (run focus-sink/build.sh to rebuild).
    if ! $AEROSPACE list-windows --focused --format '%{window-id}' >/dev/null 2>&1; then
      # Relaunch each time: a running helper doesn't reliably take focus on
      # reopen; a fresh launch does.
      # Wait for the old one to exit first, or LaunchServices may still see
      # it and fail the launch (error -600).
      /usr/bin/pkill -x AeroSpaceFocusSink
      for _ in {1..50}; do /usr/bin/pgrep -xq AeroSpaceFocusSink || break; sleep 0.02; done
      /usr/bin/open -a "$HOME/Applications/AeroSpaceFocusSink.app" 2>/dev/null \
        || { sleep 0.1; /usr/bin/open -a "$HOME/Applications/AeroSpaceFocusSink.app"; }
    fi
    ;;
  restore)
    parked=" $($AEROSPACE list-windows --workspace "$HIDDEN" --format '%{window-id}' | tr '\n' ' ') "
    current=$($AEROSPACE list-workspaces --focused)
    # Newest first; skip ids that were closed or moved out of H by hand.
    while read -r id; do
      [[ "$parked" == *" $id "* ]] || continue
      $AEROSPACE move-node-to-workspace --window-id "$id" "$current"
      $AEROSPACE focus --window-id "$id"
      grep -vx "$id" "$STACK" > "$STACK.tmp"; mv "$STACK.tmp" "$STACK"
      exit 0
    done < <(tail -r "$STACK")
    # Nothing tracked: fall back to any window still sitting in H.
    id=$(echo $parked | awk '{print $NF}')
    [[ -n "$id" ]] || exit 0
    $AEROSPACE move-node-to-workspace --window-id "$id" "$current"
    $AEROSPACE focus --window-id "$id"
    ;;
  on-app-activated)
    # Run from SketchyBar's front_app_switched ($2 = app name). AeroSpace
    # doesn't always follow a Dock click / Raycast launch onto H, so when an
    # app comes forward with no window here but one parked on H, pull the
    # newest parked one back.
    app="$2"
    current=$($AEROSPACE list-workspaces --focused)
    [[ -n "$app" && "$current" != "$HIDDEN" ]] || exit 0
    $AEROSPACE list-windows --workspace "$current" --format '%{app-name}' | grep -qxF "$app" && exit 0
    parked=" $($AEROSPACE list-windows --workspace "$HIDDEN" --format '%{window-id}|%{app-name}' \
      | awk -F'|' -v app="$app" '$2 == app { printf "%s ", $1 }') "
    [[ "$parked" != "  " ]] || exit 0
    id=""
    while read -r candidate; do
      [[ "$parked" == *" $candidate "* ]] && { id="$candidate"; break; }
    done < <(tail -r "$STACK")
    [[ -n "$id" ]] || id=$(echo $parked | awk '{print $NF}')
    $AEROSPACE move-node-to-workspace --window-id "$id" "$current"
    $AEROSPACE focus --window-id "$id"
    grep -vx "$id" "$STACK" > "$STACK.tmp"; mv "$STACK.tmp" "$STACK"
    ;;
  on-workspace-change)
    # Run from exec-on-workspace-change. Clicking a parked app in the Dock,
    # Cmd-Tab or Raycast focuses its window, which drags focus onto H. Send
    # that window back to the workspace we came from instead.
    [[ "$AEROSPACE_FOCUSED_WORKSPACE" == "$HIDDEN" ]] || exit 0
    id=$($AEROSPACE list-windows --focused --format '%{window-id}' 2>/dev/null)
    [[ -n "$id" ]] || exit 0
    target="$AEROSPACE_PREV_WORKSPACE"
    [[ -n "$target" && "$target" != "$HIDDEN" ]] || target=1
    $AEROSPACE move-node-to-workspace --focus-follows-window --window-id "$id" "$target"
    grep -vx "$id" "$STACK" > "$STACK.tmp"; mv "$STACK.tmp" "$STACK"
    exit 0
    ;;
esac

/opt/homebrew/bin/sketchybar --trigger aerospace_workspace_refresh >/dev/null 2>&1
