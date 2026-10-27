#!/bin/zsh
# Dedicated Helium window for browser automation (Codex computer use etc.).
# Opens in the background in the 36 Labs profile; aerospace.toml parks it on
# hidden workspace Z (matched by the "agent-window" title), so it never lands
# next to my own Helium window or switches my workspace.
#
#   agent-browser.sh open    reuse or open the window, print its window id
#   agent-browser.sh close   close it
AEROSPACE=/opt/homebrew/bin/aerospace
HELIUM=/Applications/Helium.app/Contents/MacOS/Helium

find_win() { $AEROSPACE list-windows --workspace Z --format '%{window-id}|%{app-bundle-id}' | awk -F'|' '$2=="net.imput.helium"{print $1; exit}'; }

case "${1:-open}" in
  open)
    id=$(find_win)
    if [[ -z $id ]]; then
      "$HELIUM" --profile-directory="Profile 3" --new-window 'data:text/html,<title>agent-window</title><p>Agent browser window. Safe to close.</p>' >/dev/null 2>&1 &!
      for _ in {1..20}; do /bin/sleep 0.25; id=$(find_win); [[ -n $id ]] && break; done
    fi
    [[ -n $id ]] || { echo "agent window did not appear" >&2; exit 1; }
    echo "$id" ;;
  close)
    id=$(find_win); [[ -n $id ]] && $AEROSPACE close --window-id "$id" ;;
  *) echo "usage: agent-browser.sh [open|close]" >&2; exit 2 ;;
esac
