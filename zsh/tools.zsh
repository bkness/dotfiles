# ---------# ---------------------------------------
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

# completions FIRST
zstyle ':fzf-tab:*' fzf-flags \
  --height=80% \
  --layout=reverse \
  --border=rounded \
  --margin=1 \
  --padding=1 \
  --info=inline \
  --color=fg:#00ff00,bg:#000000,hl:#00ff00 \
  --color=fg+:#00ff00,bg+:#001100,hl+:#00ff00 \
  --color=border:#00ff00 \
  --color=prompt:#00ff00,pointer:#00ff00,marker:#00ff00 \
  --preview-window=right:50%

# Enable group switching with < and >
zstyle ':fzf-tab:*' switch-group '<' '>'

# Directory preview (Matrix‑style)
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'

# File preview (with bat)
zstyle ':fzf-tab:complete:*:*' fzf-preview 'bat --color=always --style=plain $realpath 2>/dev/null || ls -la --color=always $realpath'

# Colorize file lists
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# Don’t show Zsh’s built‑in menu
zstyle ':completion:*' menu no
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
  dir=$(command fd . "${1:-.}" -td | fzf) && cd "$dir"
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
dashboard_widget() {
  project_dashboard
  zle reset-prompt
}

zle -N dashboard_widget
bindkey '^G' dashboard_widget

# Preview command function for project dashboard
project_visuals_cmd() {
  if command -v eza >/dev/null; then
    echo "eza -la --icons --color=always {}"
  else
    echo "ls -la {}"
  fi
}

# Git helper
is_git_repo() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1
}
