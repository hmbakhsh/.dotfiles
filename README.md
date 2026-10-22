# hmbakhsh's .dotfiles

## Omakase macOS

A keyboard-driven Mac in one command: [AeroSpace](https://github.com/nikitabobko/AeroSpace)
tiling, a [SketchyBar](https://github.com/FelixKratz/SketchyBar) menu bar in place of
Apple's, and a fast Zsh. For a fresh Apple Silicon Mac.

```bash
curl -fsSL https://raw.githubusercontent.com/hmbakhsh/.dotfiles/main/install.sh | bash
```

It installs Xcode Command Line Tools, Homebrew and [`omakase/Brewfile`](omakase/Brewfile)
(AeroSpace, SketchyBar, Ghostty, Helium, Raycast, SF Pro, shell tools), clones this repo
to `~/.dotfiles`, links the configs, and applies [`omakase/macos-defaults.sh`](omakase/macos-defaults.sh)
(hidden menu bar and Dock, fast key repeat). Re-running is safe; anything it replaces is
moved to `~/.local/state/dotfiles-backups/`.

Skip parts with `curl ... | bash -s -- --no-macos-defaults` or `--no-brew`.

**After install:** allow AeroSpace under System Settings → Privacy & Security →
Accessibility, reopen it, then open a new terminal.

### Using it

Press **ctrl-shift-/** for the full cheat sheet ([`SHORTCUTS.txt`](SHORTCUTS.txt)). The basics:

| Keys | Action |
| --- | --- |
| ctrl-1 … ctrl-0 | go to workspace 1–10 (per monitor) |
| ctrl-h/j/k/l | focus left/down/up/right |
| alt-shift-arrows | snap window to that half |
| alt-shift-f | fullscreen |
| cmd-m / cmd-shift-m | instant minimise / restore |
| ctrl-; then 1…0 | move window to workspace |

Workspace 1 is for Ghostty and 2 for Helium; other apps opened there move to the next
free workspace.

### Making it yours

| What | Where |
| --- | --- |
| Keys, float rules, gaps | `aerospace/aerospace.toml` |
| Bar items | `sketchybar/sketchybarrc` |
| Calendars in the bar (comma-separated; default all) | `sketchybar/calendars.local` |
| Secrets, machine-only shell setup | `~/.zshrc.local` |

`*.local` files are git-ignored. To keep your own changes, fork this repo and install with
`curl ... | DOTFILES_REPO=https://github.com/you/.dotfiles.git bash`.

---

## Personal setup

### Getting started
#### Clone repo in ~/ directory
```bash
git clone https://github.com/hmbakhsh/.dotfiles.git
```

#### Copy-paste commands
```bash
ln -s ~/.dotfiles/vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
ln -s ~/.dotfiles/zsh/.zshrc ~/.zshrc
ln -s ~/.dotfiles/nvim ~/.config/nvim
ln -s ~/.dotfiles/.tmux.conf ~/.tmux.conf
ln -s ~/.dotfiles/copyfile /opt/homebrew/bin/copyfile # dependency: brew install reattach-to-user-namespace
brew bundle --file=~/.dotfiles/brew/Brewfile
~/.dotfiles/scripts/install-sketchybar.sh
ln -s ~/.dotfiles/aerospace ~/.config/aerospace
~/.dotfiles/aerospace/focus-sink/build.sh # Cmd-M helper app
```
---
### FAQ
#### How to symlink to a directory
```bash
ln -s path/to/dotfile/ where/the/file/needs/to/be/stored
```

#### How to store all currently installed formulae & casks
```bash
brew bundle dump --file=~/Brewfile --force
```

### Personal agent skills

Personal skills and global agent instructions are managed from `agents/`:

```bash
python3 ~/.dotfiles/agents/install.py
python3 ~/.dotfiles/agents/install.py --check
```

See [`agents/README.md`](agents/README.md).
