#!/bin/zsh
# snap.sh left|right — put the focused window on one half of the screen.
#
# The alt-shift-left/right binding starts this, then runs a native 'move'
# itself, so the common case (a tiled window next to others) is instant and
# this script has nothing to do. It handles the rest:
#   floating, other windows here -> tile it beside them (e.g. System Settings)
#   alone on the workspace       -> float it and set its frame to that half
#                                   (AeroSpace can't tile one window to half)
AEROSPACE=/opt/homebrew/bin/aerospace
dir=$1

read -r win_id pid layout <<< "$($AEROSPACE list-windows --focused --format '%{window-id} %{app-pid} %{window-layout}')"
[ -z "$win_id" ] && exit 0
count=$($AEROSPACE list-windows --workspace focused --count)

if (( count > 1 )); then
    [[ $layout == floating ]] || exit 0
    $AEROSPACE layout --window-id "$win_id" tiling
    $AEROSPACE move "$dir"
    $AEROSPACE balance-sizes
    exit 0
fi

# Turning a tiled window floating makes AeroSpace restore its old floating
# frame a moment later, which would land on top of ours: set it again after.
was_tiled=0
if [[ $layout != floating ]]; then
    $AEROSPACE layout --window-id "$win_id" floating
    was_tiled=1
fi

# Half of the screen under the mouse (AeroSpace centres the mouse on the
# focused monitor), below the 40px SketchyBar bar.
/usr/bin/osascript -l JavaScript - "$dir" "$pid" "$was_tiled" <<'EOF'
ObjC.import('AppKit')
function run(argv) {
    const [dir, pid, wasTiled] = argv
    const bar = 40
    const mouse = $.NSEvent.mouseLocation
    const screens = $.NSScreen.screens.js
    const screen = screens.find(s => {
        const f = s.frame
        return mouse.x >= f.origin.x && mouse.x < f.origin.x + f.size.width &&
               mouse.y >= f.origin.y && mouse.y < f.origin.y + f.size.height
    }) || screens[0]
    const f = screen.frame
    const primaryH = screens[0].frame.size.height
    const top = primaryH - (f.origin.y + f.size.height) + bar
    const w = Math.floor(f.size.width / 2)
    const h = f.size.height - bar
    const x = dir === 'left' ? f.origin.x : f.origin.x + f.size.width - w
    const proc = Application('System Events').processes.whose({ unixId: Number(pid) })[0]
    const win = proc.windows[0]
    win.position = [x, top]
    win.size = [w, h]
    if (wasTiled === '1') {
        delay(0.1)
        win.position = [x, top]
        win.size = [w, h]
    }
}
EOF
