#!/usr/bin/env bash
set -euo pipefail
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
case ${1:-} in
  --box)
    sudo apt-get update
    sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y zsh git fzf zoxide lsd bat neovim trash-cli
    ;;
  --mac) ;; # Dependencies come from omakase/Brewfile.
  *)
    echo 'Usage: bash scripts/install-zsh.sh --box (Ubuntu ASCII Box) | --mac' >&2
    exit 1
    ;;
esac

backup="$HOME/.local/state/dotfiles-backups/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup"
chmod 700 "$backup"
for file in .zshrc .zshenv .zprofile .zshrc.local; do
  if [[ -e "$HOME/$file" || -L "$HOME/$file" ]]; then
    cp -L "$HOME/$file" "$backup/$file"
    chmod 600 "$backup/$file"
  fi
done

zinit_home="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
if [[ ! -d "$zinit_home" ]]; then
  mkdir -p "$(dirname "$zinit_home")"
  git clone --depth 1 https://github.com/zdharma-continuum/zinit.git "$zinit_home"
fi
# Warm plugins explicitly so normal startup needs no downloads. One shell per
# plugin: loading them together without a terminal can exit zsh mid-way.
for plugin in 'light zsh-users/zsh-syntax-highlighting' \
  'light zsh-users/zsh-completions' 'light zsh-users/zsh-autosuggestions' \
  'snippet OMZL::git.zsh' 'snippet OMZP::git' 'snippet OMZP::sudo'; do
  TERM=${TERM:-xterm-256color} zsh -fic 'source "$1/zinit.zsh" && zinit ${=2}' \
    -- "$zinit_home" "$plugin"
done

ln -sfn "$repo/zsh/.zshrc" "$HOME/.zshrc"
if [[ $1 == --mac ]]; then
  # The shared .zshrc does not set up Homebrew; login shells do.
  brew_env='eval "$(/opt/homebrew/bin/brew shellenv)"'
  if ! grep -qsF "$brew_env" "$HOME/.zprofile"; then
    printf '%s\n' "$brew_env" >> "$HOME/.zprofile"
  fi
  printf 'Installed Zsh. Backups: %s\n' "$backup"
  exit 0
fi
ln -sfn "$repo/zsh/box.zshenv" "$HOME/.zshenv"
ln -sfn "$repo/zsh/box.zprofile" "$HOME/.zprofile"
if [[ ! -e "$HOME/.zshrc.local" ]]; then
  install -m 600 "$repo/zsh/box.zshrc.local.example" "$HOME/.zshrc.local"
fi
zsh -lic ':'
sudo chsh -s "$(command -v zsh)" "$USER"
printf 'Installed Zsh. Backups: %s\n' "$backup"
