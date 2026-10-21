#!/bin/zsh
# Called from on-window-detected when a new window would land on
# workspace 1 (Ghostty) or 2 (Helium). Bounces it to the earliest
# free workspace instead, falling back to 9 if none are free.
#
# Floating utility popups (1Password, Raycast, etc.) are exempt: they're
# meant to float on top of whatever workspace is focused, and moving them
# elsewhere makes them vanish off-screen right after they open.
AEROSPACE=/opt/homebrew/bin/aerospace
EXCLUDED_APP_IDS=(com.1password.1password com.raycast.macos com.apple.systempreferences com.hbak.HexCustom com.apple.LocalAuthentication.UIAgent com.apple.SecurityAgent com.apple.coreservices.uiagent cc.ffitch.shottr)

read -r app_id window_layout <<< "$($AEROSPACE list-windows --all --format '%{window-id}%{tab}%{app-bundle-id}%{tab}%{window-layout}' | awk -F '\t' -v id="$AEROSPACE_WINDOW_ID" '$1 == id { print $2, $3 }')"
if [[ "$window_layout" == floating ]] || (( ${EXCLUDED_APP_IDS[(Ie)$app_id]} )); then
    exit 0
fi

target=$($AEROSPACE list-workspaces --monitor focused --empty | grep -vE '^[12]$' | head -1)
[ -z "$target" ] && target=9
$AEROSPACE move-node-to-workspace --focus-follows-window --window-id "$AEROSPACE_WINDOW_ID" "$target"
