#!/usr/bin/env bash
# Omakase macOS: AeroSpace + SketchyBar + Zsh on a fresh Apple Silicon Mac.
#
#   curl -fsSL https://raw.githubusercontent.com/hmbakhsh/.dotfiles/main/install.sh | bash
#
# Options (after `bash -s --` when piped):
#   --no-macos-defaults   leave Dock, menu bar, key repeat and Finder settings alone
#   --no-brew             skip Homebrew packages (configs only)
# Safe to re-run. Anything it replaces is moved to ~/.local/state/dotfiles-backups/.
set -euo pipefail

REPO_URL=${DOTFILES_REPO:-https://github.com/hmbakhsh/.dotfiles.git}

main() {
  local macos_defaults=true brew=true arg
  for arg in "$@"; do
    case $arg in
      --no-macos-defaults) macos_defaults=false ;;
      --no-brew) brew=false ;;
      *) die "unknown option: $arg" ;;
    esac
  done

  [[ $(uname -s) == Darwin ]] || die "macOS only."
  [[ $(uname -m) == arm64 ]] || die "Apple Silicon only (configs use /opt/homebrew)."

  step "Xcode Command Line Tools"
  if ! xcode-select -p >/dev/null 2>&1; then
    xcode-select --install || true
    echo "Finish the installer dialog; waiting..."
    until xcode-select -p >/dev/null 2>&1; do sleep 5; done
  fi

  if $brew; then
    step "Homebrew"
    sudo -v
    # Keep sudo alive for casks that install system-wide (fonts).
    while true; do sudo -n true; sleep 50; kill -0 $$ || exit; done 2>/dev/null &
    if [[ ! -x /opt/homebrew/bin/brew ]]; then
      NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
  fi
  [[ ! -x /opt/homebrew/bin/brew ]] || eval "$(/opt/homebrew/bin/brew shellenv)"

  step "Dotfiles"
  local repo
  repo=$(local_repo)
  if [[ -z $repo ]]; then
    repo="$HOME/.dotfiles"
    if [[ -d $repo/.git ]]; then
      git -C "$repo" pull --ff-only || warn "could not update $repo; using it as is."
    else
      git clone --depth 1 "$REPO_URL" "$repo"
    fi
  fi
  [[ $repo == "$HOME/.dotfiles" ]] || warn "zsh expects the repo at ~/.dotfiles (found $repo)."

  if $brew; then
    step "Packages (omakase/Brewfile)"
    brew bundle --file="$repo/omakase/Brewfile" || warn "some packages failed; re-run to retry."
  fi

  step "Configs"
  BACKUP="$HOME/.local/state/dotfiles-backups/$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$HOME/.config"
  link "$repo/aerospace" "$HOME/.config/aerospace"
  link "$repo/sketchybar" "$HOME/.config/sketchybar"
  link "$repo/SHORTCUTS.txt" "$HOME/.config/SHORTCUTS.txt"
  bash "$repo/scripts/install-zsh.sh" --mac

  step "SketchyBar status font + AeroSpace focus helper"
  mkdir -p "$HOME/Library/Fonts"
  "$repo/sketchybar/plugins/build-status-font.py"
  "$repo/aerospace/focus-sink/build.sh"

  if $macos_defaults; then
    step "macOS defaults"
    bash "$repo/omakase/macos-defaults.sh"
  fi

  step "Start"
  if pgrep -xq AeroSpace; then
    aerospace reload-config || true
    sketchybar --reload 2>/dev/null || true
  elif [[ -d /Applications/AeroSpace.app ]]; then
    open -a AeroSpace  # starts SketchyBar too (after-startup-command)
  fi

  cat <<EOF

Done.$([[ -d ${BACKUP:-} ]] && printf ' Replaced files are in %s.' "$BACKUP")

Next:
  1. Allow AeroSpace in System Settings > Privacy & Security > Accessibility,
     then quit and reopen AeroSpace.
  2. Open a new terminal for the new shell.
  3. Press ctrl-shift-/ for the shortcut cheat sheet.
  Optional: list the calendars the bar should show (comma-separated) in
  $repo/sketchybar/calendars.local
EOF
}

# The repo this script lives in, when run from a checkout rather than curl.
local_repo() {
  local dir
  [[ -n ${BASH_SOURCE[0]:-} && -f ${BASH_SOURCE[0]} ]] || return 0
  dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
  [[ ! -f $dir/omakase/Brewfile ]] || printf '%s\n' "$dir"
}

# Symlink $1 to $2, moving anything already at $2 (other than a link) to $BACKUP.
link() {
  if [[ -e $2 && ! -L $2 ]]; then
    mkdir -p "$BACKUP"
    mv "$2" "$BACKUP/"
  fi
  ln -sfn "$1" "$2"
  echo "  $2 -> $1"
}

step() { printf '\n\033[1;34m==>\033[0m \033[1m%s\033[0m\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

# Piped through curl, stdin is the script; prompts need the terminal.
if [[ ! -t 0 ]] && { : </dev/tty; } 2>/dev/null; then main "$@" </dev/tty; else main "$@"; fi
