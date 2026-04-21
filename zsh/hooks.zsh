# ---------------------------------------
# Hooks
# ---------------------------------------

# Auto-use .nvmrc when entering a directory
load-nvmrc() {
  if [[ -f .nvmrc ]]; then
    command -v nvm >/dev/null || _lazy_nvm
    nvm use --silent
  fi
}
add-zsh-hook chpwd load-nvmrc


# Auto-activate Python virtualenv
auto-venv() {
  if [[ -f .venv/bin/activate ]]; then
    source .venv/bin/activate
  fi
}
add-zsh-hook chpwd auto-venv
