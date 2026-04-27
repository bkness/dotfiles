export STARSHIP_CONFIG="$HOME/dev/dotfiles-v2/starship/starship.toml"

# Lazy-load starship on first prompt draw
_starship_lazy() {
  unfunction _starship_lazy
  eval "$(starship init zsh)"
}

precmd_functions+=(_starship_lazy)
