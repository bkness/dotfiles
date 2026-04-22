# Global plugin registry
typeset -A PLUGIN_REGISTRY
typeset -A PLUGIN_PRIORITY

register_plugin() {
    local name="$1"
    local fn="$2"
    local priority="${3:-100}"

    PLUGIN_REGISTRY[$name]="$fn"
    PLUGIN_PRIORITY[$name]="$priority"
}

# External plugins (zinit)
ZINIT_PLUGINS=(
  zsh-users/zsh-completions
  Aloxaf/fzf-tab
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-syntax-highlighting
)

# Internal plugins (your files)
LOCAL_PLUGINS=(
  project/node
  project/python
  project/rust
)
