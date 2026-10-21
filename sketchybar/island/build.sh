#!/bin/bash
# Rebuild and restart the island after editing Sources/.
# ISLAND_SLOWMO=8 ./Island slows the animations for frame-by-frame checks.
set -e
cd "$(dirname "$0")"
swiftc -O -swift-version 5 -o Island Sources/*.swift
mkdir -p ~/.local/bin
ln -sf "$PWD/Island" ~/.local/bin/notch
pkill -x Island || true
nohup ./Island >/dev/null 2>&1 &
