# ---------------------------------------
# Hook Dispatcher
# ---------------------------------------
typeset -A _HOOKS

register_hook() {
  local event="$1"
  local fn="$2"         # fixed: was "2", missing $

  if [[ -z "${_HOOKS[$event]}" ]]; then
    _HOOKS[$event]="$fn"
  else
    _HOOKS[$event]="${_HOOKS[$event]} $fn"
  fi
}

fire_hook() {
  local event="$1"
  [[ -z "${_HOOKS[$event]}" ]] && return 0   # fixed: was -n, logic inverted

  for fn in ${(z)_HOOKS[$event]}; do
    if typeset -f "$fn" >/dev/null 2>&1; then
      "$fn"
    else
      echo "⚠️  Hook '$fn' registered for '$event' but not found" >&2
    fi
  done
}

# ---------------------------------------
# Built-in zsh hook integration
# ---------------------------------------
_hook_chpwd() {
  fire_hook "on_dir_enter"

  local type
  type=$(project_detect)
  [[ "$type" != "unknown" ]] && fire_hook "on_enter/$type"  # fixed: was missing event arg
}

add-zsh-hook chpwd _hook_chpwd

Auto-activate Python virtualenv
auto-venv() {
  if [[ -f .venv/bin/activate ]]; then
    source .venv/bin/activate
  fi
}
add-zsh-hook chpwd auto-venv

project_detect() {
    local type="unknown"
   
# Monorepo / fullstack awareness
[[ -f package.json && -f requirements.txt ]] && echo "fullstack" && return
[[ -f requirements.txt && ! -f package.json ]] && echo "python" && return
[[ -f Cargo.toml  && ! -f package.json && ! -f requirements.txt ]] && echo "rust" && return
   
    echo "unknown"
}




# # In a rust.zsh setup hook, runs once
# if [[ ! -f "$HOME/.zfunc/_cargo" ]]; then
#   rustup completions zsh cargo > ~/.zfunc/_cargo
#   rustup completions zsh > ~/.zfunc/_rustup
# fi
