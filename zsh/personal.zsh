# ---------------------------------------
# Personal machine setup — Brandon's Mac only
# ---------------------------------------
# Govee lights, the Forged site status pushes, the shell open/close lifecycle
# and `workmode` all assume this one machine: its light MAC addresses, the
# local govee server, the 3-monitor layout, and tokens in ~/.secrets.
# .zshrc loads this file only when ~/.secrets sets FORGED_PERSONAL=1, so a
# fresh `forged init` install on someone else's Mac skips it.
# Govee globals
GOVEE_OFFICE="6F:1C:60:74:F4:5B:55:F0"
GOVEE_MAIN="72:50:C6:35:33:33:59:46"
GOVEE_OL_1="10:CE:60:74:F4:5E:18:26"
GOVEE_OL_2="6E:3D:60:74:F4:55:DB:44"
GOVEE_LIVING_RIGHT="$GOVEE_OL_2"  # right as seen from the desk; confirmed by blinking it
GOVEE_KITCHEN_1="38:BF:60:74:F4:5E:91:20"
GOVEE_KITCHEN_2="36:5E:60:74:F4:48:8A:4A"
GOVEE_KITCHEN_3="74:F3:60:74:F4:5B:66:7A"
GOVEE_KITCHEN_MIDDLE="$GOVEE_KITCHEN_3"  # confirmed by blinking it, 2026-09-30
GOVEE_HALLWAY="18:C5:60:74:F4:40:62:10"
GOVEE_DREAMVIEW="3B:03:CF:36:39:34:24:3C"

# Govee light boot up function
_govee_boot() {
  local model="${1:-H6008}"
  shift
  local lights=("$@")

  for light in "${lights[@]}"; do
    curl -s -m 3 -X PUT "http://localhost:8000/lights/${light}/control?model=${model}" -H "x-api-key: $GOVEE_SERVER_KEY" -H "Content-Type: application/json" -d '{"name": "turn", "value": "on"}' >/dev/null &!
  done 
} 

_govee_color() {
  local model="$1"
  local device="$2"
  local r="$3" g="$4" b="$5"
  curl -s -m 3 -X PUT "http://localhost:8000/lights/${device}/control?model=${model}" \
    -H "x-api-key: $GOVEE_SERVER_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"name\": \"color\", \"value\": {\"r\": $r, \"g\": $g, \"b\": $b}}" >/dev/null &!
}

_govee_apply() {
  local device="$1" model="$2" action="$3"
  case "$action" in
    on|off)
      curl -s -m 3 -X PUT "http://localhost:8000/lights/${device}/control?model=${model}" \
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
      fzf "${FZF_THEME[@]}" --prompt="💡 room > " --height=50% --border=rounded --no-sort)
    [[ -z "$room" || "$room" == "— exit —" ]] && return

    action=$(printf "on\noff\npink\nblue\nred\nwhite\ngreen\npurple\n← back" | \
      fzf "${FZF_THEME[@]}" --prompt="⚡ action > " --height=50% --border=rounded --no-sort)
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

      _GOVEE_MSG="  💡 $room → $action"
    done
}
_govee_widget() {
  zle -I
  _GOVEE_MSG=""
  { govee } always {
    zle reset-prompt
    [[ -n "$_GOVEE_MSG" ]] && zle -M "$_GOVEE_MSG"
  }
}
zle -N _govee_widget # desc: create zle widget for govee menu
bindkey '^V' _govee_widget # desc: Ctrl+V to open Govee light control menu

# Git status flashes on the office light, the middle kitchen bulb and the
# right living room bulb (the lightbars came off the wall). Each light goes
# back to its own look afterwards: office purple, the bulbs 5400K white.
# Govee allows ~10 requests a minute for the whole account, so a flash is
# 6 requests (3 colors + 3 restores) and flashes share one cooldown.
#   green  = push went through
#   yellow = committed, not pushed yet (same as the yellow nag)
#   red    = push or commit failed
zmodload zsh/datetime  # $EPOCHSECONDS for the cooldown
typeset -A _GOVEE_FLASH_RGB=(
  green  '{"r":0,"g":255,"b":0}'
  yellow '{"r":255,"g":180,"b":0}'
  red    '{"r":255,"g":0,"b":0}'
)
_GOVEE_LAST_FLASH=0
_GOVEE_CMD_KIND=""

# "device model restore-command" per light
_govee_flash_lights() {
  print -r -- "$GOVEE_OFFICE H6008 "'{"name":"color","value":{"r":75,"g":0,"b":130}}'
  print -r -- "$GOVEE_KITCHEN_MIDDLE H6008 "'{"name":"colorTem","value":5400}'
  print -r -- "$GOVEE_LIVING_RIGHT H6008 "'{"name":"colorTem","value":5400}'
}

_govee_send() {  # device model json
  curl -sf -m 3 -X PUT "http://localhost:8000/lights/$1/control?model=$2" \
    -H "x-api-key: $GOVEE_SERVER_KEY" -H "Content-Type: application/json" \
    -d "$3" &>/dev/null
}

# _govee_flash green|yellow|red — one request at a time. A restore that gets
# rate-limited waits a minute and tries again, so a light is never left
# stuck on the flash color
_govee_flash() {
  local rgb="${_GOVEE_FLASH_RGB[$1]}"
  [[ -n "$rgb" ]] || { echo "usage: _govee_flash green|yellow|red" >&2; return 1; }
  {
    local line device model restore
    local -a lights=("${(@f)$(_govee_flash_lights)}")
    for line in "${lights[@]}"; do
      read -r device model restore <<<"$line"
      _govee_send "$device" "$model" "{\"name\":\"color\",\"value\":$rgb}"
    done
    sleep 2
    local -a missed=()
    for line in "${lights[@]}"; do
      read -r device model restore <<<"$line"
      _govee_send "$device" "$model" "$restore" || missed+=("$line")
    done
    if (( ${#missed} )); then
      sleep 60
      for line in "${missed[@]}"; do
        read -r device model restore <<<"$line"
        _govee_send "$device" "$model" "$restore"
      done
    fi
  } &!
}

_govee_preexec() {
  _GOVEE_CMD_KIND=""
  if [[ "$1" == git\ push* || "$1" == gp ]]; then
    if ! git rev-parse @{u} &>/dev/null; then
      _GOVEE_CMD_KIND=push
    else
      local ahead
      ahead=$(git rev-list @{u}..HEAD 2>/dev/null | wc -l)
      (( ahead > 0 )) && _GOVEE_CMD_KIND=push
    fi
  elif [[ "$1" == git\ commit* ]]; then
    _GOVEE_CMD_KIND=commit
  fi
}

_govee_precmd() {
  local exit_code=$?
  [[ -n "$_GOVEE_CMD_KIND" ]] || return
  local kind=$_GOVEE_CMD_KIND color
  _GOVEE_CMD_KIND=""
  if (( exit_code != 0 )); then
    color=red
  elif [[ $kind == push ]]; then
    color=green
  else
    color=yellow
  fi
  flash $color --quiet
}

# flash green|yellow|red — by hand (abbrs flashg/flashy/flashr) or from the
# git hooks. One flash a minute, whatever the color, so neither a
# commit-then-push nor mashing the abbr can hit Govee's rate limit.
flash() {
  local wait=$(( 60 - (EPOCHSECONDS - _GOVEE_LAST_FLASH) ))
  if (( wait > 0 )); then
    [[ "$2" == --quiet ]] || echo "  💡 cooling down, try again in ${wait}s"
    return
  fi
  _GOVEE_LAST_FLASH=$EPOCHSECONDS
  _govee_flash "$1"
}

add-zsh-hook preexec _govee_preexec
add-zsh-hook precmd _govee_precmd
# Shared curl helper — all weballtech API calls go through here
_weballtech_post() {
  local endpoint="${1#/}" payload="$2"   # strip leading / — "//api" 308-redirects
  # --fail: return non-zero on HTTP errors (401 etc.) instead of looking fine
  curl -sfL --max-time 5 -X POST "https://weballtech-brandon-kellys-projects.vercel.app/${endpoint}" \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $WEBALLTECH_TOKEN" \
    -d "$payload" > /dev/null
}

# Online / offline status (updates the Forged site's /api/status)
online()  { _weballtech_post "/api/status" '{"online":true}'  && echo "● online"  || echo "⚠ couldn't reach status API" }
offline() { _weballtech_post "/api/status" '{"online":false}' && echo "○ offline" || echo "⚠ couldn't reach status API" }

# Push shell metadata — skips curl if version/plugins/hooks unchanged
_push_shell_status() {
  local version=$(forged version 2>/dev/null | sed 's/forged-cli v//' || echo "unknown")
  local plugins=${#PLUGIN_REGISTRY[@]}
  local hooks=${#_HOOKS[@]}
  local meta="$version-$plugins-$hooks"
  [[ "$meta" == "$(cat ~/.shell_meta_cache 2>/dev/null)" ]] && return
  # Only cache after a successful push, so a failed push retries next shell
  _weballtech_post "/api/forged-status" "{\"type\":\"shell\",\"data\":{\"version\":\"$version\",\"plugins\":$plugins,\"hooks\":$hooks}}" \
    && echo "$meta" > ~/.shell_meta_cache
}
  
# Open terminals are counted by process: each shell leaves a marker named
# after its PID in ~/.cache/forged/shells, and the count is how many of those
# PIDs are still alive. A crashed or force-quit tab can't leave the count
# stuck (the old ~/.shell_count file drifted, and capping it at 1 meant
# closing any tab went offline). Claude Code's shells (CLAUDECODE=1) never
# register, trigger workmode, or change the online badge.
_SHELLS_DIR=~/.cache/forged/shells

_shell_count() {  # live shells other than this one; prunes dead markers
  local f n=0
  for f in $_SHELLS_DIR/<->(N); do
    [[ ${f:t} == $$ ]] && continue
    if kill -0 ${f:t} 2>/dev/null; then (( n++ )); else rm -f $f; fi
  done
  echo $n
}

_shell_open() {
  [[ -n "$CLAUDECODE" ]] && return
  [[ -f /tmp/workmode.lock ]] && return
  mkdir -p $_SHELLS_DIR
  local prev=$(_shell_count)
  : > $_SHELLS_DIR/$$
  echo "shell count: $(( prev + 1 ))"
  # The boot: first shell alive, once a day
  (( prev == 0 )) || return
  mkdir /tmp/boot_once_$(date +%Y%m%d) 2>/dev/null || return
  sleep 3
  { workmode } &!   # in the background, so the first prompt isn't held up
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
  [[ -n "$CLAUDECODE" ]] && return
  rm -f $_SHELLS_DIR/$$
  (( $(_shell_count) == 0 )) || return   # other terminals still open
  offline
  rm -f ~/.cache/forged/workmode-state
}

register_hook "on_exit" "_shell_close"

# Forged scan wrapper — runs scan then pushes cache to weballtech
scan() {
  forged scan "$@"
  local cache="$HOME/.forged-scan-cache.json"
  [[ -f "$cache" ]] && _weballtech_post "/api/forged-status" "{\"type\":\"scanner\",\"data\":$(cat $cache)}" &!
}


# Govee light controls via interactive menu
# Use: govee() to open fzf menu, pick room + action
# All quick aliases (mon, moff, kon, lpink, etc.) are covered by the menu

alias goveestat='curl -s http://localhost:8000/lights/ -H "x-api-key: $GOVEE_SERVER_KEY" | python3 -m json.tool'

pyserv() {
  local log="/tmp/govee-server.log"
  (cd ~/dev/projects/govee-automation && source .venv/bin/activate && uvicorn app.main:app --reload) > "$log" 2>&1 &!
  echo "🟢 govee server starting..."
  sleep 1.5
  grep -m1 "Uvicorn running" "$log" 2>/dev/null | sed 's/^INFO:     //' || echo "   http://localhost:8000"
}

killpy() { 
  kill -9 $(lsof -ti :8000) 2>/dev/null
  echo "🔴 govee server terminated..."
}

_minimize() {
  osascript -e "tell application \"System Events\" to set miniaturized of window 1 of process \"$1\" to true"
}

# workmode — ASUS (1920x1080, main, left) + MacBook (1440x900, right).
# The Alienware is gone, so iTerm and VS Code split the ASUS and one Chrome
# window with tabs fills the MacBook. Existing Chrome windows are left alone.
WORKMODE_TABS=(
  "https://github.com/bkness"
  "https://vercel.com/dashboard"
  "https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array"
  "https://www.youtube.com"
)

# desc: Start the cockpit: online badge, Music, Govee server, lights, windows
# Runs by itself on the first terminal of the day; type `workmode` any time.
workmode() {
  local force=0
  [[ "$1" == "--force" || "$1" == "-f" ]] && force=1

  if [[ $force -eq 0 ]]; then
    [[ -f /tmp/workmode.lock ]] && echo "workmode already running" && return
  fi
  touch /tmp/workmode.lock

  # Online badge, Music station (unless something's playing), notification
  online &!
  _push_shell_status &!
  local version=$(forged version 2>/dev/null | sed 's/forged-cli v//' || echo "unknown")
  [[ $(osascript -e 'tell application "Music" to get player state' 2>/dev/null) != "playing" ]] && \
    osascript -e 'open location "musics://music.apple.com/us/station/brandons-station/ra.u-40787829f08b63e81abb70ff757aa95f"' &!
  osascript -e "display notification \"● online | v$version | lights on | music up\" with title \"Workmode\"" &!

  # Govee server, then the same 3 lights the git flash uses
  if ! lsof -ti :8000 >/dev/null 2>&1; then
    pyserv
  fi
  _govee_boot "H6008" "$GOVEE_OFFICE"
  _govee_boot "H6008" "$GOVEE_KITCHEN_MIDDLE"
  _govee_boot "H6008" "$GOVEE_LIVING_RIGHT"

  # ASUS left half: iTerm
  osascript <<'ITERM2'
tell application "iTerm2"
  tell current window
    set bounds to {0, 25, 960, 1080}
  end tell
end tell
ITERM2

  # ASUS right half: VS Code
  open -a "Visual Studio Code"
  osascript <<'VSCODE'
tell application "Visual Studio Code" to activate
delay 1
tell application "System Events"
  tell process "Code"
    set position of window 1 to {960, 25}
    set size of window 1 to {960, 1055}
  end tell
end tell
VSCODE

  # MacBook: one new Chrome window with the workmode tabs. The MacBook is
  # shorter and bottom-aligned with the ASUS, so its top edge is y=180.
  local tabs=("${WORKMODE_TABS[@]}")
  osascript - "${tabs[@]}" <<'CHROME'
on run urls
  tell application "Google Chrome"
    activate
    set w to make new window
    set bounds of w to {1920, 205, 3360, 1080}
    set URL of active tab of w to item 1 of urls
    repeat with i from 2 to count of urls
      tell w to make new tab with properties {URL:item i of urls}
    end repeat
    set active tab index of w to 1
  end tell
end run
CHROME

  # Focus back on iTerm
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
  mkdir -p ~/.cache/forged
  echo "active" > ~/.cache/forged/workmode-state
  echo "Workspace ready. Go get em. 🚀"
}

# dash (lib/dash.zsh): my npm packages page instead of the npm home page
(( ${+DASH_LINKS} )) && DASH_LINKS[npm]=https://www.npmjs.com/~bkness
