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

# Shared curl helper — all weballtech API calls go through here
_weballtech_post() {
  local endpoint="$1" payload="$2"
  curl -sL -X POST "https://www.weballtech.com${endpoint}" \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $WEBALLTECH_TOKEN" \
    -d "$payload" > /dev/null
}

# Online / offline status (updates weballtech.com/api/status)
online()  { _weballtech_post "/api/status" '{"online":true}'  && echo "● online"  }
offline() { _weballtech_post "/api/status" '{"online":false}' && echo "○ offline" }

# Push shell metadata — skips curl if version/plugins/hooks unchanged
_push_shell_status() {
  local version=$(forged version 2>/dev/null | sed 's/forged-cli v//' || echo "unknown")
  local plugins=${#PLUGIN_REGISTRY[@]}
  local hooks=${#_HOOKS[@]}
  local meta="$version-$plugins-$hooks"
  [[ "$meta" == "$(cat ~/.shell_meta_cache 2>/dev/null)" ]] && return
  echo "$meta" > ~/.shell_meta_cache
  _weballtech_post "/api/forged-status" "{\"type\":\"shell\",\"data\":{\"version\":\"$version\",\"plugins\":$plugins,\"hooks\":$hooks}}"
}

_shell_open() {
  local count=$(( $(cat ~/.shell_count 2>/dev/null || echo 0) + 1 ))
  echo $count > ~/.shell_count
  if [[ $count -eq 1 ]]; then
    online &!
    _push_shell_status &!
  fi
  [[ "$(jq -r '.musicOnStart' ~/.forged-settings.json 2>/dev/null)" == "true" ]] && { 
    pgrep -qx "Music" || open -a Music &!
    sleep 2
    osascript -e 'open location "musics://music.apple.com/us/station/bad-omens-similar-artists-station/ra.467610583"' &!
}
}

_shell_close() {
  local count=$(( $(cat ~/.shell_count 2>/dev/null || echo 1) - 1 ))
  [[ $count -lt 0 ]] && count=0
  echo $count > ~/.shell_count
  [[ $count -le 0 ]] && offline
}

register_hook "on_exit" "_shell_close"

# Forged scan wrapper — runs scan then pushes cache to weballtech
scan() {
  forged scan "$@"
  local cache="$HOME/.forged-scan-cache.json"
  [[ -f "$cache" ]] && _weballtech_post "/api/forged-status" "{\"type\":\"scanner\",\"data\":$(cat $cache)}" &!
}

# Clean shell exit
bye() { exit }

# Shell
alias mplay='osascript -e "tell application \"Music\" to playpause"' # desc: Toggle play/pause in Music app 
alias mnext='osascript -e "tell application \"Music\" to next track"' # desc: Skip to next track in Music app
alias mprev='osascript -e "tell application \"Music\" to previous track"' # desc: Skip to previous track in Music app
alias omens='osascript -e "open location \"musics://music.apple.com/us/station/bad-omens-similar-artists-station/ra.467610583\""' # desc: Bad Omens station
alias prevail='osascript -e "open location \"musics://music.apple.com/us/station/i-prevail-similar-artists-station/ra.948448824"' # desc: I Prevail station
alias horizon='osascript -e "open location \"musics://music.apple.com/us/station/bring-me-the-horizon-similar-artists-station/ra.121043936"' # desc: Bring me the Horizon station
alias mymusic='osascript -e "open location \"musics://music.apple.com/us/station/brandons-station/ra.u-40787829f08b63e81abb70ff757aa95f"' #desc: My Music station
alias wat='open "https://www.weballtech.com"' # desc: Open WebAllTech website
alias apistat='open "https://www.weballtech.com/api/"' # desc: Open WebAllTech API status page
alias music="open -a Music" # desc: Open Music app
alias c="clear" # desc: Clear terminal
alias ..="cd .." # desc: Up one directory
alias ll="eza -la --icons" # desc: List all files (detailed, icons)
alias ls="eza --icons" # desc: List files (icons)
alias cat="bat" # desc: View file with syntax highlight
alias safe="zsh -f" # desc: Start shell without config
reload() {
  local count=$(( $(cat ~/.shell_count 2>/dev/null || echo 1) - 1 ))
  [[ $count -lt 0 ]] && count=0
  echo $count > ~/.shell_count
  exec zsh -l
}
alias sz="source ~/.zshrc" # desc: Reload zsh config
alias mkdir="mkdir -p"  # desc: Create directories (with parents)
alias grep="grep --color=auto" # desc: Colored grep output

