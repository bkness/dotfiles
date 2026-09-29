# ---------------------------------------
# Hook Dispatcher
# ---------------------------------------
typeset -A _HOOKS

register_hook() {
  local event="$1"
  local fn="$2"

  # Skip if already registered for this event
  [[ " ${_HOOKS[$event]} " == *" $fn "* ]] && return

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
_LAST_PWD=""

_hook_chpwd() {
  local prev="$_LAST_PWD"
  _LAST_PWD="$PWD"

  fire_hook "on_dir_exit"  # fire exit for previous directory
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

# Auto-close Python virtualenv when leaving directory
_auto_deactivate_venv() {
  if [[ -n "$VIRTUAL_ENV" && "$PWD" != "$VIRTUAL_ENV"* ]]; then
    deactivate
  fi  
}
register_hook "on_dir_exit" "_auto_deactivate_venv"

# Auto-switch Node version when .nvmrc is present
auto-nvm() {
  [[ -f .nvmrc ]] || return
  typeset -f _lazy_nvm >/dev/null 2>&1 && _lazy_nvm
  local requested current
  requested=$(cat .nvmrc)
  current=$(node --version 2>/dev/null)
  [[ "$current" == "v${requested#v}" ]] && return
  nvm use --silent 2>/dev/null
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

# ---------------------------------------
# Dependency scan on project entry
# ---------------------------------------
# `forged scan --changed` exits in ~50ms when package.json + lockfile match a
# scan from the last week, so this is cheap on most cd's. A real scan can take
# ~20s, so it runs in the background and writes its one-line alert to a file;
# the next prompt prints it instead of scribbling over the line you're typing.
_FORGED_ALERT="${TMPDIR:-/tmp}/forged-alert.$$"

_forged_autoscan() {
  [[ -f package-lock.json ]] || return
  (( $+commands[forged] )) || return
  forged scan --changed --quiet >"$_FORGED_ALERT" 2>/dev/null &!
}
register_hook "on_dir_enter" "_forged_autoscan"

_forged_alert() {
  [[ -s "$_FORGED_ALERT" ]] || return
  echo; cat "$_FORGED_ALERT"; echo
  : >"$_FORGED_ALERT"
}
add-zsh-hook precmd _forged_alert
add-zsh-hook zshexit _forged_alert_cleanup
_forged_alert_cleanup() { rm -f "$_FORGED_ALERT" }

# ---------------------------------------
# Stale branch detector
# ---------------------------------------
# On entering a git repo, _gh_stale_warning (lib/github.zsh) fetches the
# default branch (at most every 5 min) and counts commits you haven't pulled.
# It used to run in the Ctrl+G entry point until the fetch blocked the UI
# (#64); here it runs in the background like _forged_autoscan, and the next
# prompt prints the warning. The fetch also refreshes starship's ⇣ count.
# Each warning shows once per repo until it changes, so cd-ing around inside a
# stale repo doesn't repeat it.
_STALE_ALERT="${TMPDIR:-/tmp}/git-stale-alert.$$"
_STALE_LAST=""

_git_stale_check() {
  (( $+functions[_gh_stale_warning] )) || return
  local top
  top=$(git rev-parse --show-toplevel 2>/dev/null) || return
  { print -r -- "$top"; _gh_stale_warning } >"$_STALE_ALERT" 2>/dev/null &!
}
register_hook "on_dir_enter" "_git_stale_check"

_git_stale_alert() {
  [[ -s "$_STALE_ALERT" ]] || return
  local lines=("${(@f)$(<"$_STALE_ALERT")}")
  : >"$_STALE_ALERT"
  local msg="${(F)lines[2,-1]}"
  [[ -n "$msg" ]] || return
  local key="${lines[1]}:$msg"
  [[ "$key" == "$_STALE_LAST" ]] && return
  _STALE_LAST="$key"
  print -r -- $'\n\e[33m'"$msg"$'\e[0m\n'
}
add-zsh-hook precmd _git_stale_alert
add-zsh-hook zshexit _git_stale_alert_cleanup
_git_stale_alert_cleanup() { rm -f "$_STALE_ALERT" }

# Wire on_exit — fires on normal exit and when terminal window is closed (SIGHUP)
# Guard: SHLVL=1 (outermost shell only) + fire_hook must be defined (full env loaded)
zshexit() { [[ $SHLVL -eq 1 ]] && typeset -f fire_hook > /dev/null && fire_hook "on_exit" }
TRAPHUP()  { [[ $SHLVL -eq 1 ]] && typeset -f fire_hook > /dev/null && fire_hook "on_exit" }

# ---------------------------------------
# Git lifecycle nags
# ---------------------------------------
_GIT_NAG_PUSH=0

_git_nag_pre() {
  [[ "$1" == git\ commit* ]] && echo "\n  \e[33m⚠  Don't forget to push, you absolute menace.\e[0m\n"
  if [[ "$1" == git\ push* || "$1" == gp ]]; then
    if ! git rev-parse @{u} &>/dev/null; then
      _GIT_NAG_PUSH=1
    else
      local ahead
      ahead=$(git rev-list @{u}..HEAD 2>/dev/null | wc -l)
      (( ahead > 0 )) && _GIT_NAG_PUSH=1 || _GIT_NAG_PUSH=0
    fi
  else
    _GIT_NAG_PUSH=0
  fi
}

_git_nag_post() {
  [[ $_GIT_NAG_PUSH -eq 1 ]] || return
  _GIT_NAG_PUSH=0
  if [[ $? -eq 0 ]]; then
    echo "\n  \e[33m⚠  Pushed. Now close that branch before it haunts you forever.\e[0m\n"
  else
    echo "\n  \e[31m✗  Push failed. Fix it before you forget what you were doing.\e[0m\n"
  fi
}

add-zsh-hook preexec _git_nag_pre
add-zsh-hook precmd _git_nag_post
