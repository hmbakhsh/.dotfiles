#!/bin/zsh
# Called from on-window-detected when a new window would land on
# workspace 1 (Ghostty) or 2 (Helium). The rule has already floated it, so
# Ghostty/Helium never shrink. Move it to the earliest free workspace
# (falling back to 9), tile it there while that workspace is still hidden,
# then switch to it — one clean jump instead of a visible reshuffle.
#
# Floating utility popups (1Password, Raycast, etc.) never get here: their
# own rules sit above the route-away rule in aerospace.toml.
AEROSPACE=/opt/homebrew/bin/aerospace

target=$($AEROSPACE list-workspaces --monitor focused --empty | grep -vE '^[12]$' | head -1)
[ -z "$target" ] && target=9
$AEROSPACE move-node-to-workspace --window-id "$AEROSPACE_WINDOW_ID" "$target"
$AEROSPACE layout --window-id "$AEROSPACE_WINDOW_ID" tiling
$AEROSPACE focus --window-id "$AEROSPACE_WINDOW_ID"
