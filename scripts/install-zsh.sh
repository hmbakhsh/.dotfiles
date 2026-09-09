#!/usr/bin/env bash
set -euo pipefail
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
if [[ ${1:-} != --box ]]; then
  echo 'Usage: bash scripts/install-zsh.sh --box (Ubuntu ASCII Box)' >&2
  exit 1
fi
sudo apt-get update
sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y zsh git fzf zoxide lsd bat neovim trash-cli

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
# Warm plugins explicitly so normal startup needs no downloads.
TERM=${TERM:-xterm-256color} zsh -fic '
  source "$1/zinit.zsh"
  zinit light zsh-users/zsh-syntax-highlighting
  zinit light zsh-users/zsh-completions
  zinit light zsh-users/zsh-autosuggestions
  zinit snippet OMZL::git.zsh
  zinit snippet OMZP::git
  zinit snippet OMZP::sudo
' -- "$zinit_home"

ln -sfn "$repo/zsh/.zshrc" "$HOME/.zshrc"
ln -sfn "$repo/zsh/box.zshenv" "$HOME/.zshenv"
ln -sfn "$repo/zsh/box.zprofile" "$HOME/.zprofile"
if [[ ! -e "$HOME/.zshrc.local" ]]; then
  install -m 600 "$repo/zsh/box.zshrc.local.example" "$HOME/.zshrc.local"
fi
zsh -lic ':'
sudo chsh -s "$(command -v zsh)" "$USER"
printf 'Installed Zsh. Backups: %s\nExisting panes: exec zsh -l\n' "$backup"
