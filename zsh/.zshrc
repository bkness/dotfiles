# ---------------------------------------
# Zinit plugin manager
# ---------------------------------------
export PATH="/opt/homebrew/bin:$PATH"

# Install zinit if missing
if [[ ! -f ~/.local/share/zinit/zinit.git/zinit.zsh ]]; then
  mkdir -p ~/.local/share/zinit
  git clone https://github.com/zdharma-continuum/zinit.git ~/.local/share/zinit/zinit.git
fi

# Load zinit
source ~/.local/share/zinit/zinit.git/zinit.zsh

# Load plugins
source ~/dev/dotfiles/zsh/plugins.zsh

# source ~/dev/dotfiles/zsh/lib/plugins.zsh
source ~/dev/dotfiles/zsh/lib/plugin-registry.zsh

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

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

### End of Zinit's installer chunk
