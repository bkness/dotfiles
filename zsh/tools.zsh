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

# Ctrl-R history search handled by Atuin (initialized in .zshrc)

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
  _PROJECT_MSG=""
  { project_ui } always {
    zle reset-prompt
    [[ -n "$_PROJECT_MSG" ]] && zle -M "$_PROJECT_MSG"
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