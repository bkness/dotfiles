# ---------------------------------------
# Zinit plugin manager
# ---------------------------------------
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/usr/local/share/dotnet:$PATH"

source ~/.local/share/zinit/zinit.git/zinit.zsh
source ~/dev/dotfiles/zsh/plugins.zsh

# Add custom completions to fpath BEFORE compinit
fpath=("$HOME/.zfunc" "${fpath[@]}")

autoload -Uz compinit
zstyle ':completion:*' menu yes select
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# Initialize zoxide eagerly (no lazy-load, ensures j/zoxide is always ready)
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

# Plugin registry — must load before hooks and project plugins
source ~/dev/dotfiles/zsh/lib/plugin-registry.zsh

# Hook dispatcher — must load before project plugins (they call register_hook)
source ~/dev/dotfiles/zsh/hooks.zsh

# Project plugins (register themselves into PLUGIN_REGISTRY + _HOOKS)
for file in ~/dev/dotfiles/zsh/plugins/project/*.zsh(N); do
  source "$file"
done

# Library utilities (skip plugin-registry, already loaded above)
for file in ~/dev/dotfiles/zsh/lib/*.zsh(N); do
  [[ "${file:t}" == "plugin-registry.zsh" ]] && continue
  source "$file"
done

# Core modules (hooks intentionally excluded — loaded above)
for module in env tools aliases dev starship; do
  file="$HOME/dev/dotfiles/zsh/${module}.zsh"
  [[ -f "$file" ]] && source "$file"
done

source "$HOME/dev/dotfiles/zsh/plugins/theme/neon-cockpit.zsh"

zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export PATH="$HOME/.local/bin:$PATH"

# Track shell count — auto online/offline (guard prevents sz/source from double-incrementing)
[[ -z "$_SHELL_REGISTERED" ]] && { _SHELL_REGISTERED=1; _shell_open; }
