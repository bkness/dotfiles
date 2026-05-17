export STARSHIP_CONFIG="$HOME/.config/starship.toml"

# Lazy-load starship on first prompt draw
_starship_lazy() {
  unfunction _starship_lazy
  eval "$(starship init zsh)"
}

precmd_functions+=(_starship_lazy)

# Transient prompt — collapse completed commands to ➜ before execution
# Starship's precmd restores the full prompt for each new line
_transient_line_finish() {
  PROMPT=$'%F{green}➜%f '
  RPROMPT=""
  zle reset-prompt
}
zle -N zle-line-finish _transient_line_finish
