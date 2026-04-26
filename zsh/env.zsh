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
  --color=bg+:#0d1f12,bg:#030a06,fg:#00ADD8,fg+:#00ff41
  --color=hl:#00ADD8,hl+:#00ADD8,pointer:#00ff41,marker:#FF4500
  --color=border:#1a3a22,prompt:#00ff41,info:#FFD43B,header:#4a7a55
  --pointer=▶ --marker=●
)