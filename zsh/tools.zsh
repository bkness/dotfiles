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
# fzf keybindings + completion
# (colors + zstyles owned by plugins/theme/neon-cockpit.zsh)
# ---------------------------------------

if [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
  source /usr/share/fzf/key-bindings.zsh
  source /usr/share/fzf/completion.zsh
elif [[ -f ~/.fzf/shell/key-bindings.zsh ]]; then
  source ~/.fzf/shell/key-bindings.zsh
  source ~/.fzf/shell/completion.zsh
fi

zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# ---------------------------------------
# Enhanced Ctrl-R history search
# ---------------------------------------

# desc: Enhanced Ctrl-R history search with fzf preview
fzf-history-widget() {
  zle -I
  local saved="$BUFFER"
  local result
  result=$(fc -l 1 \
    | sed 's/^[ ]*[0-9]*[ ]*//' \
    | fzf --tac --no-sort \
        --preview='echo {} | bat --language=bash --color=always --style=plain' \
        --preview-window=right:60%:wrap \
        --height 70% --reverse --border \
        --prompt="History > " \
        --color=fg:#00ff00,bg:#000000,hl:#00ff00 \
        --color=fg+:#00ff00,bg+:#001100,hl+:#00ff00 \
        --color=border:#00ff00 \
        --color=prompt:#00ff00,pointer:#00ff00,marker:#00ff00 \
        --border-label="History Search"
  ) || { BUFFER="$saved"; CURSOR=$#BUFFER; zle reset-prompt; return; }
  BUFFER="$result"
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
# Project dashboard
# ---------------------------------------

# desc: Open project dashboard (bind manually or via palette)
project_ui_widget() {
  zle -I
  { project_ui } always {
    zle reset-prompt
  }
}

zle -N project_ui_widget

# # Preview command function for project dashboard
# project_visuals_cmd() {
#   if command -v eza >/dev/null; then
#     echo "eza -la --icons --color=always {}"
#   else
#     echo "ls -la {}"
#   fi
# }

# Git helper
is_git_repo() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1
}

  # Test preview command
# project_visuals_cmd() {
#   if is_git_repo; then
#     echo "echo 'Git Repository Detected' && git status --short --color=always"
#   else
#     echo "echo 'No Git Repository' && ls -la --color=always {}"
#   fi
# }
 # --preview '[[ $(file --mime {}) == *text* ]] && bat --color=always --style=plain {} || ls -la --color=always {}' \