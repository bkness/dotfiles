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
alias gbclean='git config --global alias.cleanup '"'"'!f() { branch=$(git rev-parse --abbrev-ref HEAD) || exit 1; case "$branch" in main|master) echo "Refusing to delete $branch. Checkout a feature branch first."; exit 1 ;; esac; if git show-ref --verify --quiet refs/heads/main; then base=main; elif git show-ref --verify --quiet refs/heads/master; then base=master; else echo "Could not find local main or master branch."; exit 1; fi; git checkout "$base" && git pull origin "$base" && git branch -d "$branch" && git push origin --delete "$branch"; }; f'"'"' # desc: Clean up current branch and delete remote'
alias nukebranches="git fetch --prune && git branch -r | grep -v 'HEAD\|main\|master' | sed 's/origin\///' | xargs -I{} git push origin --delete '{}'" # desc: Delete all remote branches except main and master
alias gco="git checkout" # desc: Switch branch or restore files

# GitHub dashboard
alias ghui="github_ui" # desc: Open GitHub dashboard

# Govee globals
GOVEE_OFFICE="6F:1C:60:74:F4:5B:55:F0"
GOVEE_MAIN="72:50:C6:35:33:33:59:46"
GOVEE_OL_1="10:CE:60:74:F4:5E:18:26"
GOVEE_OL_2="6E:3D:60:74:F4:55:DB:44"
GOVEE_KITCHEN_1="38:BF:60:74:F4:5E:91:20"
GOVEE_KITCHEN_2="36:5E:60:74:F4:48:8A:4A"
GOVEE_KITCHEN_3="74:F3:60:74:F4:5B:66:7A"
GOVEE_HALLWAY="18:C5:60:74:F4:40:62:10"
GOVEE_DREAMVIEW="3B:03:CF:36:39:34:24:3C"

# Govee light boot up function
_govee_boot() {
  local model="${1:-H6008}"
  shift
  local lights=("$@")

  for light in "${lights[@]}"; do
    curl -s -X PUT "http://localhost:8000/lights/${light}/control?model=${model}" -H "x-api-key: $GOVEE_SERVER_KEY" -H "Content-Type: application/json" -d '{"name": "turn", "value": "on"}' >/dev/null &!
  done 
} 

_govee_color() {
  local model="$1"
  local device="$2"
  local r="$3" g="$4" b="$5"
  curl -s -X PUT "http://localhost:8000/lights/${device}/control?model=${model}" \
    -H "x-api-key: $GOVEE_SERVER_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"name\": \"color\", \"value\": {\"r\": $r, \"g\": $g, \"b\": $b}}" >/dev/null &!
}

_govee_apply() {
  local device="$1" model="$2" action="$3"
  case "$action" in
    on|off)
      curl -s -X PUT "http://localhost:8000/lights/${device}/control?model=${model}" \
        -H "x-api-key: $GOVEE_SERVER_KEY" -H "Content-Type: application/json" \
        -d "{\"name\": \"turn\", \"value\": \"$action\"}" >/dev/null &!
      ;;
    pink)  _govee_color "$model" "$device" 255 0 128 ;;
    blue)  _govee_color "$model" "$device" 0 100 255 ;;
    red)   _govee_color "$model" "$device" 255 0 0 ;;
    white) _govee_color "$model" "$device" 255 255 255 ;;
    green) _govee_color "$model" "$device" 0 255 0 ;;
    purple) _govee_color "$model" "$device" 75 0 130 ;;
  esac
}


govee() {
  while true; do
    local room action

    room=$(printf "office\nmain\nliving room\nkitchen\nhallway\ndreamview\nall\n— exit —" | \
      fzf --prompt="💡 room > " --height=50% --border --no-sort)
    [[ -z "$room" || "$room" == "— exit —" ]] && return

    action=$(printf "on\noff\npink\nblue\nred\nwhite\ngreen\npurple\n← back" | \
      fzf --prompt="⚡ action > " --height=50% --border --no-sort)
    [[ -z "$action" ]] && return
    [[ "$action" == "← back" ]] && continue

      case "$room" in
        office)        _govee_apply "$GOVEE_OFFICE"    "H6008" "$action" ;;
        main)          _govee_apply "$GOVEE_OFFICE"    "H6008" "$action"
                      _govee_apply "$GOVEE_MAIN"      "H610A" "$action" ;;
        "living room") _govee_apply "$GOVEE_OL_1"      "H6008" "$action"
                      _govee_apply "$GOVEE_OL_2"      "H6008" "$action" ;;
        kitchen)       _govee_apply "$GOVEE_KITCHEN_1" "H6008" "$action"
                      _govee_apply "$GOVEE_KITCHEN_2" "H6008" "$action"
                      _govee_apply "$GOVEE_KITCHEN_3" "H6008" "$action" ;;
        hallway)       _govee_apply "$GOVEE_HALLWAY"   "H6008" "$action" ;;
        dreamview)     _govee_apply "$GOVEE_DREAMVIEW" "H6199" "$action" ;;
        all)           for pair in \
                         "$GOVEE_OFFICE:H6008" "$GOVEE_MAIN:H610A" \
                         "$GOVEE_OL_1:H6008"   "$GOVEE_OL_2:H6008" \
                         "$GOVEE_KITCHEN_1:H6008" "$GOVEE_KITCHEN_2:H6008" "$GOVEE_KITCHEN_3:H6008" \
                         "$GOVEE_HALLWAY:H6008" "$GOVEE_DREAMVIEW:H6199"; do
                         _govee_apply "${pair%%:*}" "${pair##*:}" "$action"
                         sleep 0.3
                       done ;;
      esac

      echo "💡 $room → $action"
    done
}
_govee_widget() {
  zle -I
  govee
  zle reset-prompt
}
zle -N _govee_widget # desc: create zle widget for govee menu
bindkey '^V' _govee_widget # desc: Ctrl+V to open Govee light control menu

_GOVEE_LAST_FLASH_GREEN=0
_GOVEE_LAST_FLASH_RED=0
_GOVEE_CMD_WAS_PUSH=0

_govee_flash() {
  local color="$1"
  local now; now=$(date +%s)
  local is_red=0
  [[ "$color" == *'"r":255,"g":0'* ]] && is_red=1
  if [[ $is_red -eq 1 ]]; then
    (( now - _GOVEE_LAST_FLASH_RED < 60 )) && return
    _GOVEE_LAST_FLASH_RED=$now
  else
    (( now - _GOVEE_LAST_FLASH_GREEN < 60 )) && return
    _GOVEE_LAST_FLASH_GREEN=$now
  fi
  {
    local -a devices=("$GOVEE_OFFICE" "$GOVEE_MAIN")
    local -a models=("H6008"          "H610A")
    local restore='{"name":"color","value":{"r":75,"g":0,"b":130}}'
    local i
    for (( i=1; i<=${#devices}; i++ )); do
      curl -sf -X PUT "http://localhost:8000/lights/${devices[$i]}/control?model=${models[$i]}" \
        -H "x-api-key: $GOVEE_SERVER_KEY" -H "Content-Type: application/json" \
        -d "$color" &>/dev/null &
    done
    sleep 2
    for (( i=1; i<=${#devices}; i++ )); do
      curl -sf -X PUT "http://localhost:8000/lights/${devices[$i]}/control?model=${models[$i]}" \
        -H "x-api-key: $GOVEE_SERVER_KEY" -H "Content-Type: application/json" \
        -d "$restore" &>/dev/null &
    done
    wait
  } &!
}

_govee_preexec() {
  _GOVEE_CMD_WAS_PUSH=0
  [[ "$1" == git\ push* || "$1" == gp* ]] && _GOVEE_CMD_WAS_PUSH=1
}

_govee_precmd() {
  local exit_code=$?
  if [[ $_GOVEE_CMD_WAS_PUSH -eq 1 ]]; then
    _GOVEE_CMD_WAS_PUSH=0
    if [[ $exit_code -eq 0 ]]; then
      _govee_flash '{"name":"color","value":{"r":0,"g":255,"b":0}}' >/dev/null &!
    else 
      _govee_flash '{"name":"color","value":{"r":255,"g":0,"b":0}}' >/dev/null &!
    fi 
  fi
}

add-zsh-hook preexec _govee_preexec
add-zsh-hook precmd _govee_precmd
# Shared curl helper — all weballtech API calls go through here
_weballtech_post() {
  local endpoint="$1" payload="$2"
  curl -sL --max-time 5 -X POST "https://weballtech-brandon-kellys-projects.vercel.app/${endpoint}" \
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
  
}
  
_shell_open() {
  [[ -f /tmp/workmode.lock ]] && return
  local prev=$(cat ~/.shell_count 2>/dev/null || echo 0)
  local count=$(( prev + 1))
  [[ $count -gt 1 ]] && count=1
  echo $count > ~/.shell_count
  echo "shell count: $count:"
  if [[ $prev -eq 0 ]]; then
    mkdir /tmp/boot_once_$(date +%Y%m%d) 2>/dev/null || return
    sleep 3
    online &!
    _push_shell_status &!
    local version=$(forged version 2>/dev/null | sed 's/forged-cli v//' || echo "unknown")
    local msg="● online | v$version | lights on | music up"
    [[ $(osascript -e 'tell application "Music" to get player state' 2>/dev/null) != "playing" ]] && \
      osascript -e 'open location "musics://music.apple.com/us/station/brandons-station/ra.u-40787829f08b63e81abb70ff757aa95f"' &!
    osascript -e "display notification \"$msg\" with title \"Shell opened\"" &!
    { workmode } &!
  fi
}  

_shell_current() {
  local state
  local hour=$(date +%H%M)
    if [[ $hour -ge 1800 || $hour -lt 600 ]]; then
      _govee_color "H610A" "$GOVEE_MAIN" 255 0 128 >/dev/null &!
    else
      _govee_color "H6008" "$GOVEE_OFFICE" 0 100 255 >/dev/null &!
    fi
  state=$(osascript -e 'tell application "Music" to get player state' 2>/dev/null)

  if [[ "$state" != "playing" ]]; then
    osascript -e 'display notification "Music is paused ⏸️" with title "Apple Music Status"'
    return
  fi

  local track artist
  track=$(osascript -e 'tell application "Music" to get name of current track' 2>/dev/null)
  artist=$(osascript -e 'tell application "Music" to get artist of current track' 2>/dev/null)

  if [[ -n "$track" && -n "$artist" ]]; then
    osascript -e "display notification \"$track by $artist ▶️\" with title \"Now Playing 🎵\""
  else
    osascript -e 'display notification "Station is playing 🎶" with title "Apple Music Status"'
  fi
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
alias music="open -a Music" # desc: Open Music app
alias mplay='osascript -e "tell application \"Music\" to playpause"; _shell_current' # desc: Toggle play/pause in Music app 
alias mnext='osascript -e "tell application \"Music\" to next track"; sleep 1; _shell_current' # desc: Skip to next track in Music app
alias mprev='osascript -e "tell application \"Music\" to previous track"; sleep 1; _shell_current' # desc: Skip to previous track in Music app
alias omens='osascript -e "open location \"musics://music.apple.com/us/station/bad-omens-similar-artists-station/ra.467610583\""; _shell_current' # desc: Bad Omens station
alias prevail='osascript -e "open location \"musics://music.apple.com/us/station/i-prevail-similar-artists-station/ra.948448824\""; _shell_current' # desc: I Prevail station
alias horizon='osascript -e "open location \"musics://music.apple.com/us/station/bring-me-the-horizon-similar-artists-station/ra.121043936\""; _shell_current' # desc: Bring me the Horizon station
alias mymusic='osascript -e "open location \"musics://music.apple.com/us/station/brandons-station/ra.u-40787829f08b63e81abb70ff757aa95f\""; _shell_current' #desc: My Music station
alias wat='open "https://www.weballtech.com"' # desc: Open WebAllTech website
alias apistat='open "https://www.weballtech.com/api/"' # desc: Open WebAllTech API status page
alias bk='open "https://www.github.com/bkness/"' # desc: Opens my github
alias chrome='open -a "Google Chrome"' # desc: Open Google Chrome
alias vsfont='open -a "Visual Studio Code" ~/Library/Application\ Support/Code/User/settings.json' # desc: Open VS Code settings for font editing
alias editstarship='open ~/.config/starship.toml' # desc: Edit Starship prompt configuration
alias c="clear" # desc: Clear terminal
alias ..="cd .." # desc: Up one directory
alias l="eza --icons --group-directories-first"
alias vima="vim ~/dev/dotfiles/zsh/aliases.zsh" 
alias vimz="vim ~/dev/dotfiles/zsh"
alias vimj="vim ~/dev/projects"
alias ll="eza -la --icons" # desc: List all files (detailed, icons)
alias ls="eza --icons" # desc: List files (icons)
alias cat="bat" # desc: View file with syntax highlight
alias safe="zsh -f" # desc: Start shell without config
alias ss="screencapture -i ~/Desktop/screenshot-$(date +%s).png" # desc: Interactive screenshot to Desktop
reload() {
  local count=$(( $(cat ~/.shell_count 2>/dev/null || echo 1) - 1 ))
  [[ $count -lt 0 ]] && count=0
  echo $count > ~/.shell_count
  exec zsh -l
}
alias sz="source ~/.zshrc" # desc: Reload zsh config
alias mkdir="mkdir -p"  # desc: Create directories (with parents)
alias grep="grep --color=auto" # desc: Colored grep output
alias cl="claude --resume" # desc: Resume last Claude Code session
alias sandbox="open ~/dev/tools/js-sandbox.html"
alias pixel='system_profiler SPDisplaysDataType | grep -E "Resolution|Position|Arrangement"'
alias monpos='system_profiler SPDisplaysDataType | grep -A 20 "Resolution"'
alias coord="cliclick p"

# Govee light controls via interactive menu
# Use: govee() to open fzf menu, pick room + action
# All quick aliases (mon, moff, kon, lpink, etc.) are covered by the menu

alias goveestat='curl -s http://localhost:8000/lights/ -H "x-api-key: $GOVEE_SERVER_KEY" | python3 -m json.tool'

pyserv() {
  (cd ~/dev/projects/govee-automation && source .venv/bin/activate && uvicorn app.main:app --reload) >/dev/null &!
  echo "🟢 govee server starting..."
}

killpy() { 
  kill -9 $(lsof -ti :8000) 2>/dev/null
  echo "🔴 govee server terminated..."
}

_minimize() {
  osascript -e "tell application \"System Events\" to set miniaturized of window 1 of process \"$1\" to true"
}

workmode() {
  local force=0
  [[ "$1" == "--force" || "$1" == "-f" ]] && force=1

  if [[ $force -eq 0 ]]; then
    [[ -f /tmp/workmode.lock ]] && echo "workmode already running" && return
  fi
  touch /tmp/workmode.lock

  # Alienware left - iTerm2
  # Run pyserv in current window
  osascript <<'ITERM'
tell application "iTerm2"
  activate
  tell current session of current window
    write text "pyserv"
  end tell
end tell
ITERM

   sleep 2

  # Lights on - server should be ready
  _govee_boot "H6008" "$GOVEE_OFFICE"
  _govee_boot "H610A" "$GOVEE_MAIN"


  # Position existing window
  osascript <<'ITERM2'
tell application "iTerm2"
  tell current window
    set bounds to {0, 0, 1282, 1440}
  end tell
end tell
ITERM2

  # Alienware right - VS Code
  open -a "Visual Studio Code"
  osascript <<'VSCODE'
tell application "Visual Studio Code" to activate
tell application "System Events"
  tell process "Code"
    set position of window 1 to {1277, 0}
    set size of window 1 to {1277, 1440}
  end tell
end tell
VSCODE

  # Launch Chrome, kill its auto-opened window, then place all 4 windows
  osascript <<'CHROME'
tell application "Google Chrome"
  activate
  delay 1
  close every window
  set w to make new window
  set bounds of w to {2561, 0, 3520, 1080}
  set URL of active tab of w to "https://github.com/bkness"
  set w to make new window
  set bounds of w to {3520, 0, 4480, 1080}
  set URL of active tab of w to "https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array"
  set w to make new window
  set bounds of w to {4485, 77, 5322, 1123}
  set URL of active tab of w to "https://docs.swmansion.com/react-native-reanimated/docs/fundamentals/getting-started"
  set w to make new window
  set bounds of w to {5322, 77, 6160, 1123}
  set URL of active tab of w to "https://www.youtube.com"
end tell
CHROME

 # Return focus to iTerm2
  osascript <<'FOCUS'
tell application "iTerm2"
  activate
  tell current window
    tell current session
      select
    end tell
  end tell
end tell
FOCUS

  rm /tmp/workmode.lock
  echo "Workspace ready. Go get em. 🚀"
} 

