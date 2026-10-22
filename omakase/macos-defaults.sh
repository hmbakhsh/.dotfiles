#!/usr/bin/env bash
# System settings the setup expects. Safe to re-run.
set -euo pipefail

# SketchyBar replaces the menu bar, so hide the native one.
defaults write NSGlobalDomain _HIHideMenuBar -bool true

# Dock out of the way; Spaces stay in a fixed order for AeroSpace.
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock mru-spaces -bool false

# Fast key repeat, no accent popup when holding a key.
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Finder shows hidden files.
defaults write com.apple.finder AppleShowAllFiles -bool true

killall Dock Finder SystemUIServer 2>/dev/null || true
echo "macOS defaults applied (key repeat needs a log out to take effect)."
