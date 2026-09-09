# Box manages agent/environment exports in the pre-interactive part of .bashrc.
# Read them in place on every shell (including ssh commands); never copy credentials.
if [[ -r "$HOME/.bashrc" ]]; then
  source <(awk '/^# If not running interactively/ {exit} /^export / {print}' "$HOME/.bashrc")
fi
typeset -U path
path=("$HOME/.local/bin" "$HOME/.opencode/bin" /usr/local/bin $path)
