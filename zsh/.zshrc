source <(fzf --zsh)
export PATH="/Users/hbak/.bun/bin:$PATH"

# Cursor compatibility fix - disable complex shell features when in Cursor
if [[ "$TERM_PROGRAM" == "cursor" ]] || [[ -n "$CURSOR_SESSION" ]] || [[ "$TERMINAL_EMULATOR" == "cursor" ]]; then
    # Minimal setup for Cursor - disable plugins and complex features
    export PS1='$ '
    return
fi


# colors for ls/lsd/etc
export LS_COLORS="di=38;5;147:ln=38;5;117:or=38;5;204:pi=38;5;141:so=38;5;141:bd=38;5;111:cd=38;5;111:ex=38;5;211:*.tar=38;5;141:*.tgz=38;5;141:*.zip=38;5;141:*.jpg=38;5;117:*.jpeg=38;5;117:*.png=38;5;117:*.gif=38;5;117:*.mp4=38;5;111:*.mkv=38;5;111:*.mp3=38;5;75:*.flac=38;5;75:*.pdf=38;5;188:*.txt=38;5;188:*.md=38;5;188:*.py=38;5;71:*.js=38;5;71:*.ts=38;5;71:*.rs=38;5;71:*.go=38;5;71:*.json=38;5;204:*.yaml=38;5;204:*.yml=38;5;204:*.toml=38;5;204"

# enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
#if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
#fi

echo -e "\e[2 q"

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in Powerlevel10k
# zinit ice depth=1; zinit light romkatv/powerlevel10k

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions

bindkey '^@' autosuggest-accept


# Add in snippets
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::aws
zinit snippet OMZP::sudo
zinit snippet OMZP::archlinux
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found

# prevent window title renaming (must come after snippets)
DISABLE_AUTO_TITLE="true"

# disable zsh/oh-my-zsh auto title updates if present (quietly)
{ unsetopt AUTO_TITLE } 2>/dev/null

# wipe any title-setting hooks added by plugins
precmd() { :; }


# Load completions
autoload -Uz compinit && compinit

zinit cdreplay -q

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Keybindings
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
# zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'
zstyle ':completion:*' show-completer false

# Theme configuration - Simple custom prompt
# ZSH_THEME="robbyrussell"

autoload -Uz vcs_info
zstyle ':vcs_info:git:*' formats '%F{244}%b%f'
precmd() { vcs_info }

setopt PROMPT_SUBST

# oxocarbon-style minimalist prompt (no icon, no extra space)
PROMPT='%F{111}%1~%f${vcs_info_msg_0_:+ ${vcs_info_msg_0_}} %F{60}>%f '

# Set to superior editing mode
export VISUAL=nvim
export EDITOR=nvim
export TERM="tmux-256color"


# aliases
alias c='clear'
alias charm='open -na "PyCharm.app"'
# docker
alias docker_sa='docker stop $(docker ps -q)'

# ls
alias ls="lsd -l -d --blocks size,date,name --date='+%d/%m/%y'"
alias ll='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'
alias l.='ls -dl .*'

#fzf
#alias fzf='fzf --preview="bat --color=always {} | head -500"'

# Set up fzf key bindings and fuzzy completion
#source <(fzf --zsh)
eval "$(zoxide init zsh)"

# macOS specific configurations
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Homebrew configuration
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        # Homebrew Python configuration
        export PATH="$(brew --prefix)/opt/python@3/libexec/bin:$PATH"
    fi
fi

# Custom cd function - disabled for Cursor compatibility
# cd() {
#     builtin cd "$@"
#     # Only run fancy output in interactive terminals, not in Cursor
#     if [ $? -eq 0 ] && [[ -t 1 ]] && [[ "$TERM_PROGRAM" != "cursor" ]] && [[ -z "$CURSOR_SESSION" ]]; then
#         clear
#         lsd -l --group-directories-first --blocks size,date,name --date='+%d/%m/%y'
#     fi
# }

alias ls="lsd -l --group-directories-first --blocks size,date,name --date='+%d/%m/%y'"
# This includes folders coming first in the ls
# alias ls="lsd -l --blocks size,date,name"
alias lsa="lsd -l -a"
alias cc="cursor ."
alias v='nvim .'

alias gst='git status'
alias gcm='git commit -m'

alias py="python3"
alias av="source .venv/bin/activate"
alias dv="deactivate"

alias njs="bun create next-app"
alias scn="bunx --bun shadcn@latest init"

alias zrc="vim ~/.zshrc"
alias szrcc="source ~/.zshrc"
alias szrc="tmux list-panes -s -F '#{pane_id}' | xargs -I{} tmux send-keys -t {} 'source ~/.zshrc' Enter"

z() {
  if [[ $# -eq 0 ]]; then
    builtin cd ~ || return
  else
    __zoxide_z "$@" || return
  fi
  ls
}

zp() {
	realpath "$1" | pbcopy
}

# cli new python project
np() {
    if [ $# -ne 1 ]; then
        echo "Usage: np <project-name>"
        return 1
    fi

    NAME=$1

    # Create project directory
    mkdir -p "$NAME"
    cd "$NAME" || return 1

    # Initialize uv
    uv init

    # Create virtual environment
    uv venv

    # Create basic project structure
    # mkdir -p src tests
    # touch src/__init__.py tests/__init__.py
    echo "# $NAME" > README.md
    echo "" >> README.md
    echo "A Python project." >> README.md

    # Activate the virtual environment
    source .venv/bin/activate


    CYAN='\033[0;36m'
    BLUE='\033[0;34m'
    PURPLE='\033[0;35m'
    NC='\033[0m'
    BOLD='\033[1m'

    echo "=================================================="
    echo -e "${CYAN}${BOLD}✨ Project '$NAME' Successfully Scaffolded! ✨${NC}"
    echo -e "${BLUE}   ✓ Git repository initialised${NC}"
    echo -e "${BLUE}   ✓ Virtual environment created and activated${NC}"
    echo -e "${PURPLE}${BOLD}  Happy coding!${NC}"
    echo "=================================================="
}


# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

### End of Zinit's installer chunk

# bun completions
[ -s "/Users/hbak/.bun/_bun" ] && source "/Users/hbak/.bun/_bun"
export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"
export PATH="$HOME/.dotnet/tools:$PATH"
export PATH="$HOME/.local/bin:$PATH"
