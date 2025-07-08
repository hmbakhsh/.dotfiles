# hmbakhsh's .dotfiles

### Getting started
#### Clone repo in ~/ directory
```bash
git clone https://github.com/hmbakhsh/.dotfiles.git
```

#### Copy-paste commands
```bash
ln -s ~/.dotfiles/vscode/settings.json ~/Library/Application Support/Code/User/settings.json
ln -s ~/.dotfiles/zsh/.zshrc ~/.zshrc
brew bundle --file=~/.dotfiles/brew/Brewfile
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
