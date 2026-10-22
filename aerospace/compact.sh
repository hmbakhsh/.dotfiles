#!/bin/zsh
# Keep numbered workspaces gap-free: 1, 2, 4 becomes 1, 2, 3.
# Main monitor: 1 (Ghostty) and 2 (Helium) are reserved, so 3-10 are
# compacted. Second monitor: 11-20. Letter workspaces are left alone.
#
#   compact.sh            close gaps. The focused workspace counts as
#                         occupied even when empty, so closing its last
#                         window doesn't slide other windows in under you.
#                         Run from exec-on-workspace-change and
#                         on-focus-changed (AeroSpace has no window-closed
#                         callback).
#   compact.sh switch N   switch to workspace N (ws.sh, bar clicks). Closes
#                         gaps first — the focused workspace too, since we
#                         are leaving it — while everything that moves is
#                         still hidden, then jumps straight to wherever N's
#                         windows ended up: one switch, no number flip.
AEROSPACE=/opt/homebrew/bin/aerospace

if [[ "$1" == switch ]]; then
  switch_to=$2
  [[ "$switch_to" == "$($AEROSPACE list-workspaces --focused)" ]] && exit 0
else
  # Bursts of events: let only the last run in a 50ms window do the work.
  token_file="${TMPDIR:-/tmp}/aerospace-compact.token"
  token="$$.$RANDOM"
  echo "$token" > "$token_file"
  /bin/sleep 0.05
  [[ "$(<"$token_file")" == "$token" ]] || exit 0
fi

focused_ws=$($AEROSPACE list-workspaces --focused)
focused_win=$($AEROSPACE list-windows --focused --format '%{window-id}' 2>/dev/null)

typeset -A wins   # workspace -> space-separated window ids
while read -r ws id; do
  wins[$ws]+="$id "
done < <($AEROSPACE list-windows --all --format '%{workspace} %{window-id}')

moved=0
compact() {
  local first=$1 last=$2 target=$1 ws id
  for (( ws = first; ws <= last; ws++ )); do
    if [[ -z "${wins[$ws]}" ]]; then
      # An empty focused workspace holds its slot, unless we're leaving it.
      [[ "$ws" == "$focused_ws" && -z "$switch_to" ]] || continue
    fi
    if (( ws != target )); then
      for id in ${=wins[$ws]}; do
        $AEROSPACE move-node-to-workspace --window-id "$id" "$target"
      done
      if [[ "$ws" == "$focused_ws" && -z "$switch_to" ]]; then
        $AEROSPACE workspace "$target"
        [[ -n "$focused_win" ]] && $AEROSPACE focus --window-id "$focused_win"
      fi
      moved=1
    fi
    [[ "$ws" == "$switch_to" ]] && new_target=$target
    (( target++ ))
  done
  # Switching to an empty workspace in this range: take the next free slot.
  if [[ -n "$switch_to" && -z "$new_target" ]] && (( switch_to >= first && switch_to <= last )); then
    new_target=$target
  fi
}

compact 3 10
compact 11 20

if [[ -n "$switch_to" ]]; then
  $AEROSPACE workspace "${new_target:-$switch_to}"
elif (( moved )); then
  /opt/homebrew/bin/sketchybar --trigger aerospace_workspace_refresh
fi
exit 0
