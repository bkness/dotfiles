load_plugins() {
  local base="$HOME/dev/dotfiles/zsh/plugins"

  # ---- Load zinit plugins ----
  for plugin in "${ZINIT_PLUGINS[@]}"; do
    zinit light "$plugin"
  done

  # ---- Load local plugins ----
  for plugin in "${LOCAL_PLUGINS[@]}"; do
    local file="$base/$plugin.zsh"
    [[ -f "$file" ]] && source "$file"
  done
}
