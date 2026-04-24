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

# Auto-activate Python virtualenv
auto-venv() {
  if [[ -f .venv/bin/activate ]]; then
    source .venv/bin/activate
  fi
}
register_hook "on_dir_enter" "auto-venv"

# Auto-switch Node version when .nvmrc is present
auto-nvm() {
  [[ -f .nvmrc ]] || return
  command -v nvm >/dev/null 2>&1 || return
  local requested
  requested=$(cat .nvmrc)
  local current
  current=$(node --version 2>/dev/null)
  [[ "$current" == "v${requested#v}" ]] && return
  nvm use --silent
}
register_hook "on_dir_enter" "auto-nvm"

project_detect() {
  [[ -f package.json && -f requirements.txt ]] && echo "fullstack" && return
  [[ -f package.json && ! -f requirements.txt ]] && echo "node" && return
  [[ -f requirements.txt && ! -f package.json ]] && echo "python" && return
  [[ -f Cargo.toml && ! -f package.json && ! -f requirements.txt ]] && echo "rust" && return
  [[ -f go.mod ]] && echo "go" && return
  echo "unknown"
}

# Wire the dispatcher into zsh's chpwd event
autoload -Uz add-zsh-hook
add-zsh-hook chpwd _hook_chpwd
