# ---------------------------------------
# History configuration
# ---------------------------------------

HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history

setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt INC_APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt SHARE_HISTORY


# ---------------------------------------
# fzf configuration
# ---------------------------------------

export FZF_DEFAULT_OPTS="
  --height 40%
  --layout=reverse
  --border
"

# Load fzf keybindings + completion
if [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
  source /usr/share/fzf/key-bindings.zsh
  source /usr/share/fzf/completion.zsh
elif [[ -f ~/.fzf/shell/key-bindings.zsh ]]; then
  source ~/.fzf/shell/key-bindings.zsh
  source ~/.fzf/shell/completion.zsh
fi

# ---------------------------------------
# fzf-tab tuning
# ---------------------------------------

# Use fzf for completion menus
zstyle ':completion:*' menu no

# Switch groups with comma or dot
zstyle ':fzf-tab:*' switch-group ',' '.'

# Show a preview window for files
zstyle ':fzf-tab:complete:*:' fzf-preview \
'bat --style=numbers --color=always --line-range=:500 {} 2>/dev/null'

# ---------------------------------------
# Enhanced Ctrl-R history search
# ---------------------------------------

fzf-history-widget() {
  BUFFER=$(fc -l 1 \
  | sed 's/^[ ]*[0-9]*[ ]*//' \
  | fzf --tac --no-sort \
        --preview 'echo {}' \
        --preview-window=down:3:wrap)
  CURSOR=$#BUFFER
  zle reset-prompt
}
zle -N fzf-history-widget
bindkey '^R' fzf-history-widget


# ---------------------------------------
# Fuzzy directory jump
# ---------------------------------------

fcd() {
  local dir
  dir=$(fd . "${1:-.}" -td | fzf) && cd "$dir"
}

# ---------------------------------------
# Lazy-load zoxide
# ---------------------------------------

_zoxide_lazy() {
  unfunction _zoxide_lazy
  eval "$(zoxide init zsh)"
}
add-zsh-hook chpwd _zoxide_lazy

# ---------------------------------------
# Project dashboard
# ---------------------------------------

# Open dashboard with Ctrl+D
bindkey '^D' dashboard

# Preview command function for project dashboard
project_preview_cmd() {
  if command -v eza >/dev/null; then
    echo "eza -la --icons {}"
  else
    echo "ls -la {}"
  fi
}