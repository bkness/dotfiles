# ---------------------------------------
# Environment variables
# ---------------------------------------

export EDITOR="code"
export VISUAL="code"

# Dev root
export DEV_ROOT="$HOME/dev/projects"

# Quality of life
setopt NO_BEEP
setopt PROMPT_SUBST
setopt INTERACTIVE_COMMENTS

[[ -f ~/.secrets ]] && source ~/.secrets

# ---------------------------------------
# Lazy-load NVM
# ---------------------------------------

export NVM_DIR="$HOME/.nvm"

_lazy_nvm() {
  unfunction _lazy_nvm
  [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
}

nvm()    { typeset -f _lazy_nvm >/dev/null 2>&1 && _lazy_nvm; command nvm "$@" }
node()   { typeset -f _lazy_nvm >/dev/null 2>&1 && _lazy_nvm; command node "$@" }
npm()    { typeset -f _lazy_nvm >/dev/null 2>&1 && _lazy_nvm; command npm "$@" }
npx()    { typeset -f _lazy_nvm >/dev/null 2>&1 && _lazy_nvm; command npx "$@" }
forged() { typeset -f _lazy_nvm >/dev/null 2>&1 && _lazy_nvm; command forged "$@" }

# UI theme for fzf — matches devforge palette in neon-cockpit.zsh
FZF_THEME=(
  --color=fg:#c8ffd4,bg:#000000,hl:#00ff00
  --color=fg+:#00ff00,bg+:#001100,hl+:#00ff00
  --color=border:#00ff00
  --color=prompt:#00ff00,pointer:#00ff00,marker:#00ff00
)
