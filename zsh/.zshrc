# ---------------------------------------
# Zinit plugin manager
# ---------------------------------------

# Install zinit if missing
if [[ ! -f ~/.local/share/zinit/zinit.git/zinit.zsh ]]; then
  mkdir -p ~/.local/share/zinit
  git clone https://github.com/zdharma-continuum/zinit.git ~/.local/share/zinit/zinit.git
fi

# Load zinit
source ~/.local/share/zinit/zinit.git/zinit.zsh

# Load plugins
source ~/dev/dotfiles/zsh/plugins.zsh

autoload -U add-zsh-hook

# Define modules before loading them
ZSH_MODULES=(
  env
  tools  
  hooks
  aliases
  lib/cache
  dev
  starship
) 

for module in "${ZSH_MODULES[@]}"; do
  file="$HOME/dev/dotfiles/zsh/${module}.zsh"
  [[ -f $file ]] && source $file
done
