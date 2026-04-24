# ------# ---------------------------------------
# Zinit plugin manager
# ---------------------------------------
export PATH="/opt/homebrew/bin:$PATH"

# Load zinit
source ~/.local/share/zinit/zinit.git/zinit.zsh
# Load plugins
source ~/dev/dotfiles/zsh/plugins.zsh

_fpath=("$HOME/.zfunc" "${fpath[@]}")
# Only rebuild completion cache once a day
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C # skip security check, use cache
fi

# source ~/dev/dotfiles/zsh/lib/plugins.zsh
source ~/dev/dotfiles/zsh/lib/plugin-registry.zsh

# Load all project plugin files
for file in ~/dev/dotfiles/zsh/plugins/project/*.zsh(N); do
  source "$file"
done

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

# Load all internal library files
for file in ~/dev/dotfiles/zsh/lib/*.zsh(N); do
  source "$file"
done

for module in "${ZSH_MODULES[@]}"; do
  file="$HOME/dev/dotfiles/zsh/${module}.zsh"
  [[ -f $file ]] && source $file
done

# Load a few important annexes, without Turbo
# Default prompt with Git info
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

### End of Zinit's installer chunk
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
