# Shared Zsh

The shared `.zshrc` follows the current Mac prompt, history, word-jump keys,
git aliases, `cc`/`oc`, `v`, zoxide, custom lsd listing, trash-first `rm`, and
`scripts/gwt.sh`. Zinit supplies highlighting, completion and suggestions.
Ubuntu's older fzf uses its packaged completion/key-binding scripts; `batcat`
is aliased as `bat` and `cat` when necessary.

## ASCII Box / Ubuntu

```sh
git clone --depth 1 https://github.com/hmbakhsh/.dotfiles ~/.dotfiles
cd ~/.dotfiles
bash scripts/install-zsh.sh --box
exec zsh -l
```

For an existing clone, inspect `git status` and use `git pull --ff-only` first.
The installer backs up shell files under `~/.local/state/dotfiles-backups/`,
installs apt dependencies and Zinit plugins, links the config, and sets the
login shell. It does not restart running terminal sessions.

Box's `.zshenv` reads only the managed exports before the interactive section
of its existing `.bashrc`, including Box-provided agent environment. Its
`.zprofile` sources the existing POSIX `.profile` for login environment setup.
The local overlay preserves the Box shell helper with Zsh-compatible variable
names and cleanup. Keep Box-managed `.bashrc` and `.profile` in place.

## Machine-local configuration

Use `~/.zshrc.local` (mode `600`) for credentials, machine-only paths, and
platform-specific utilities. `*.local` is ignored by this repo. Do not copy
the Mac's complete live `.zshrc` to another machine: it includes a local
AdsPower seat and laptop integrations. `box-up` and `box-down` belong on the
laptop that controls the Box.

The existing Mac live `.zshrc` remains independent and retains its local
utilities (including media helpers), paths and credentials. To opt into this
shared config on another Mac, back up the live file first, move machine-only
additions to `~/.zshrc.local`, install dependencies with Homebrew, install
Zinit and the plugins listed in the installer, then link `zsh/.zshrc`.
Never commit the local overlay or shell backups.
