# Aliases

# Git — core muscle-memory shortcuts
alias gs="git status" # desc: Check the status of the working directory 
alias gc="git commit" # desc: Commit changes using 'git commit'
alias gca="git commit -a -m" # desc: Stage all changes and commit with a message 
alias gp="git push" # desc: Push changes to the remote repository
alias gpl="git pull" # desc: Pull changes from the remote repository 
alias gl="git log --oneline --graph --decorate" # desc: Show a concise and visually appealing commit history 
alias gr="git restore" # desc: Restore changes in the working directory 
alias gss="git switch" # desc: Switch branches
alias gst="git stash" # desc: Save changes to a new stash using 'git stash'
alias gstp="git stash pop" # desc: Apply the most recent stash and remove it from the stash list using 'git stash pop'
alias gb="git branch" # desc: List, create, or delete branches using 'git branch'
alias gco="git checkout" # desc: Switch branch or restore files

# GitHub dashboard
alias ghui="github_ui" # desc: Open GitHub dashboard

# Online / offline status (updates weballtech.com/api/status)
online()  { curl -sL -X POST https://www.weballtech.com/api/status \
              -H 'Content-Type: application/json' \
              -H "Authorization: Bearer $WEBALLTECH_TOKEN" \
              -d '{"online":true}' > /dev/null && echo "● online" }
offline() { curl -sL -X POST https://www.weballtech.com/api/status \
              -H 'Content-Type: application/json' \
              -H "Authorization: Bearer $WEBALLTECH_TOKEN" \
              -d '{"online":false}' > /dev/null && echo "○ offline" }

# Shell counter — accounts for Claude shell (baseline = 1)
# online triggers at 2, offline triggers back at 1
_push_shell_status() {
  local version=$(forged version 2>/dev/null | sed 's/forged-cli v//' || echo "unknown")
  local plugins=${#PLUGIN_REGISTRY}
  local hooks=${#_HOOKS}
  curl -sL -X POST https://www.weballtech.com/api/forged-status \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $WEBALLTECH_TOKEN" \
    -d "{\"type\":\"shell\",\"data\":{\"version\":\"$version\",\"plugins\":$plugins,\"hooks\":$hooks}}" \
    > /dev/null
}

_shell_open() {
  local count=$(( $(cat ~/.shell_count 2>/dev/null || echo 0) + 1 ))
  echo $count > ~/.shell_count
  if [[ $count -eq 1 ]]; then
    online &!
    _push_shell_status &!
  fi
}

_shell_close() {
  local count=$(( $(cat ~/.shell_count 2>/dev/null || echo 1) - 1 ))
  [[ $count -lt 0 ]] && count=0
  echo $count > ~/.shell_count
  [[ $count -le 0 ]] && offline
}

register_hook "on_exit" "_shell_close"

# Clean shell exit
bye() { exit }

# Shell
alias c="clear" # desc: Clear terminal
alias ..="cd .." # desc: Up one directory
alias ll="eza -la --icons" # desc: List all files (detailed, icons)
alias ls="eza --icons" # desc: List files (icons)
alias cat="bat" # desc: View file with syntax highlight
alias safe="zsh -f" # desc: Start shell without config
alias reload="exec zsh -l" # desc: Reload shell config
alias sz="source ~/.zshrc" # desc: Reload zsh config
alias mkdir="mkdir -p"  # desc: Create directories (with parents)
alias grep="grep --color=auto" # desc: Colored grep output

