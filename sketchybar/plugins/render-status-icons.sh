#!/bin/bash

set -e

ASSET_DIR="$HOME/.config/sketchybar/assets/status"
/bin/mkdir -p "$ASSET_DIR"

render() {
  local svg="$1"
  /bin/rm -f "$svg.png"
  /opt/homebrew/bin/rsvg-convert \
    --width 256 \
    --height 256 \
    --output "$svg.png" \
    "$svg"
}

for level in 0 10 20 30 40 50 60 70 80 90 100; do
  fill_width=$((level * 34 / 100))

  if (( level <= 20 )); then
    color="#ff6b6b"
  elif (( level <= 40 )); then
    color="#ffc857"
  else
    color="#ffffff"
  fi

  fill=""
  if (( fill_width > 0 )); then
    fill="<rect x=\"12\" y=\"24\" width=\"$fill_width\" height=\"16\" rx=\"5\" fill=\"$color\"/>"
  fi

  cat > "$ASSET_DIR/battery-$level.svg" <<SVG
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <rect x="7" y="18" width="45" height="28" rx="9" fill="none" stroke="$color" stroke-width="5"/>
  <rect x="54" y="27" width="5" height="10" rx="2.5" fill="$color"/>
  $fill
</svg>
SVG
  render "$ASSET_DIR/battery-$level.svg"

  cat > "$ASSET_DIR/battery-charging-$level.svg" <<SVG
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <rect x="7" y="18" width="45" height="28" rx="9" fill="none" stroke="#a6e3a1" stroke-width="5"/>
  <rect x="54" y="27" width="5" height="10" rx="2.5" fill="#a6e3a1"/>
  ${fill//${color}/#a6e3a1}
  <path d="M34 20 L24 34 H31 L28 45 L41 29 H34 Z" fill="#354747" stroke="#a6e3a1" stroke-width="2" stroke-linejoin="round"/>
</svg>
SVG
  render "$ASSET_DIR/battery-charging-$level.svg"
done

cat > "$ASSET_DIR/wifi-connected.svg" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64" fill="none">
  <path d="M9 24 C22 11 42 11 55 24" stroke="#89b4fa" stroke-width="7" stroke-linecap="round"/>
  <path d="M19 35 C27 27 37 27 45 35" stroke="#89b4fa" stroke-width="7" stroke-linecap="round"/>
  <circle cx="32" cy="47" r="5" fill="#89b4fa"/>
</svg>
SVG
render "$ASSET_DIR/wifi-connected.svg"

cat > "$ASSET_DIR/wifi-disconnected.svg" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64" fill="none">
  <path d="M9 24 C22 11 42 11 55 24" stroke="#9ca3af" stroke-width="7" stroke-linecap="round"/>
  <path d="M19 35 C27 27 37 27 45 35" stroke="#9ca3af" stroke-width="7" stroke-linecap="round"/>
  <circle cx="32" cy="47" r="5" fill="#9ca3af"/>
  <path d="M13 12 L51 52" stroke="#ff6b6b" stroke-width="6" stroke-linecap="round"/>
</svg>
SVG
render "$ASSET_DIR/wifi-disconnected.svg"
