# Shared interactive shell. Keep credentials and machine-only additions in ~/.zshrc.local.
typeset -U path fpath
path=("$HOME/.local/bin" "$HOME/.bun/bin" "$HOME/.opencode/bin" $path)
[[ -o interactive ]] || return 0

# Cursor uses a minimal shell.
if [[ "$TERM_PROGRAM" == cursor || -n "$CURSOR_SESSION" || "$TERMINAL_EMULATOR" == cursor ]]; then
  PROMPT='$ '
  [[ ! -r ~/.zshrc.local ]] || source ~/.zshrc.local
  return 0
fi

export LS_COLORS='di=38;5;147:ln=38;5;117:or=38;5;204:pi=38;5;141:so=38;5;141:bd=38;5;111:cd=38;5;111:ex=38;5;211:*.tar=38;5;141:*.tgz=38;5;141:*.zip=38;5;141:*.jpg=38;5;117:*.jpeg=38;5;117:*.png=38;5;117:*.gif=38;5;117:*.mp4=38;5;111:*.mkv=38;5;111:*.mp3=38;5;75:*.flac=38;5;75:*.pdf=38;5;188:*.txt=38;5;188:*.md=38;5;188:*.py=38;5;71:*.js=38;5;71:*.ts=38;5;71:*.rs=38;5;71:*.go=38;5;71:*.json=38;5;204:*.yaml=38;5;204:*.yml=38;5;204:*.toml=38;5;204'
[[ -t 1 ]] && printf '\e[2 q'

# Installation is explicit (scripts/install-zsh.sh), never a network call on startup.
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
if [[ -r "$ZINIT_HOME/zinit.zsh" ]]; then
  source "$ZINIT_HOME/zinit.zsh"
  zinit light zsh-users/zsh-syntax-highlighting
  zinit light zsh-users/zsh-completions
  zinit light zsh-users/zsh-autosuggestions
  zinit snippet OMZL::git.zsh
  zinit snippet OMZP::git
  zinit snippet OMZP::sudo
fi
DISABLE_AUTO_TITLE=true

autoload -Uz compinit
_compdump="${ZDOTDIR:-$HOME}/.zcompdump-${ZSH_VERSION}-${options[login]}"
if [[ -s $_compdump && -n ${_compdump}(#qN.mh-24) && $_compdump -nt "$HOME/.dotfiles/zsh/.zshrc" ]]; then
  compinit -C -d "$_compdump"
else
  compinit -d "$_compdump" && touch "$_compdump"
fi
unset _compdump
(( $+functions[zinit] )) && zinit cdreplay -q

# Ubuntu's fzf predates --zsh; use its packaged integration instead.
if (( $+commands[fzf] )) && [[ -o zle && -t 0 ]]; then
  if fzf --help | command grep -q -- --zsh; then
    eval "$(fzf --zsh)"
  else
    for _fzf_file in /usr/share/doc/fzf/examples/{completion,key-bindings}.zsh; do
      [[ ! -r $_fzf_file ]] || source "$_fzf_file"
    done
    unset _fzf_file
  fi
fi

bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region
bindkey '^[[1;3D' backward-word
bindkey '^[[1;3C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word
bindkey '^[b' backward-word
bindkey '^[f' forward-word
bindkey '^[[1;3A' beginning-of-line
bindkey '^[[1;3B' end-of-line
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^x^e' edit-command-line

HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory sharehistory hist_ignore_space hist_ignore_all_dups
setopt hist_save_no_dups hist_ignore_dups hist_find_no_dups
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' show-completer false

autoload -Uz vcs_info add-zsh-hook
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats '%F{244}%b%f'
add-zsh-hook precmd vcs_info
setopt PROMPT_SUBST
PROMPT='%F{111}%1~%f${vcs_info_msg_0_:+ ${vcs_info_msg_0_}} %F{60}>%f '
export VISUAL=nvim EDITOR=nvim
[[ -n "$TMUX" ]] && export TERM=tmux-256color

alias c=clear
alias docker_sa='docker stop $(docker ps -q)'
alias ll='ls -l' la='ls -a' lla='ls -la' lt='ls --tree' l.='ls -dl .*'
alias lsa='ls -la'
alias cc=claude oc=opencode2
alias gst='git status' gcm='git commit -m '
alias py=python3 av='source .venv/bin/activate' dv=deactivate
alias njs='bun create next-app' scn='bunx --bun shadcn@latest init'
alias zrc='vim ~/.zshrc' szrcc='source ~/.zshrc'
alias szrc="tmux list-panes -s -F '#{pane_id}' | xargs -I{} tmux send-keys -t {} 'source ~/.zshrc' Enter"
if (( $+commands[bat] )); then
  alias cat=bat
elif (( $+commands[batcat] )); then
  alias bat=batcat cat=batcat
fi
[[ ! -r "$HOME/.dotfiles/scripts/gwt.sh" ]] || source "$HOME/.dotfiles/scripts/gwt.sh"

_lsd_cmd() {
  lsd -l --group-directories-first --blocks size,date,name --date='+%d/%m/%y' "$@"
}
unalias ls 2>/dev/null
ls() {
  if ! (( $+functions[_lsd_cmd] && $+commands[lsd] )); then
    command ls "$@"
    return
  fi
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    _lsd_cmd "$@"
    return
  fi
  local -a ignored
  local f ig
  while IFS= read -r f; do
    ignored+=("${f##*/}")
  done < <(git check-ignore -- *(N) .*(N) 2>/dev/null)
  if [[ ${#ignored[@]} -eq 0 ]]; then
    _lsd_cmd "$@"
    return
  fi
  _lsd_cmd "$@" | while IFS= read -r line; do
    local dim=false
    for ig in "${ignored[@]}"; do
      if [[ "$line" == *"$ig"* ]]; then
        printf '\e[2m%s\e[0m\n' "$line"
        dim=true
        break
      fi
    done
    $dim || printf '%s\n' "$line"
  done
}

unalias rm 2>/dev/null
rm() {
  local force_rm=false arg
  local -a new_args
  for arg in "$@"; do
    if [[ "$arg" == --force-rm ]]; then force_rm=true
    else new_args+=("$arg")
    fi
  done
  if $force_rm; then command rm "${new_args[@]}"
  else
    print -u2 'Use trash-cli instead. Usage: trash'
    return 1
  fi
}
unalias v 2>/dev/null
v() { if (( $# )); then nvim "$@"; else nvim .; fi }
if (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh)"
  z() {
    if (( $# )); then __zoxide_z "$@" || return
    else builtin cd ~ || return
    fi
    ls
  }
fi
zp() {
  if (( $+commands[pbcopy] )); then realpath "$1" | pbcopy
  elif (( $+commands[wl-copy] )); then realpath "$1" | wl-copy
  elif (( $+commands[xclip] )) && [[ -n $DISPLAY ]]; then realpath "$1" | xclip -selection clipboard
  else realpath "$1"
  fi
}

[[ ! -s "$HOME/.bun/_bun" ]] || source "$HOME/.bun/_bun"
export OPENCODE_DISABLE_CLAUDE_CODE_SKILLS=1
[[ ! -r ~/.zshrc.local ]] || source ~/.zshrc.local
true
