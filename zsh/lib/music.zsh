# ---------------------------------------
# Apple Music Widget — ♫
# Ctrl+] to open | catalog search via Apple Music API + playback controls + stations
# Keybinding note: Alt/Option keybinds don't work on macOS terminals — they produce
# special characters (˙∆˚¬µ etc) instead of escape sequences. Stick to Ctrl+<key>.
# ^M = Enter (reserved), ^A = beginning-of-line (reserved). ^] is free and safe.
# Requires: APPLE_MUSIC_KEY_ID, APPLE_MUSIC_TEAM_ID, APPLE_MUSIC_KEY_PATH in ~/.secrets
# ---------------------------------------

_MUSIC_TOKEN_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/forged/music-token"

_music_gen_token() {
  [[ -z "$APPLE_MUSIC_KEY_ID" || -z "$APPLE_MUSIC_TEAM_ID" || -z "$APPLE_MUSIC_KEY_PATH" ]] && {
    echo "  ❌ APPLE_MUSIC_KEY_ID, APPLE_MUSIC_TEAM_ID, APPLE_MUSIC_KEY_PATH not set in ~/.secrets" >&2
    return 1
  }
  [[ -f "$APPLE_MUSIC_KEY_PATH" ]] || { echo "  ❌ Key file not found: $APPLE_MUSIC_KEY_PATH" >&2; return 1; }

  python3 - "$APPLE_MUSIC_KEY_PATH" "$APPLE_MUSIC_KEY_ID" "$APPLE_MUSIC_TEAM_ID" <<'PYSCRIPT'
import sys, time, base64, json
try:
    from cryptography.hazmat.primitives import hashes, serialization
    from cryptography.hazmat.primitives.asymmetric import ec
    from cryptography.hazmat.primitives.asymmetric.utils import decode_dss_signature
except ImportError:
    print("Missing dep — run: pip3 install cryptography", file=sys.stderr)
    sys.exit(1)

key_path, key_id, team_id = sys.argv[1:4]
with open(key_path, 'rb') as f:
    private_key = serialization.load_pem_private_key(f.read(), password=None)

now = int(time.time())

def b64url(data):
    if isinstance(data, str): data = data.encode()
    return base64.urlsafe_b64encode(data).rstrip(b'=').decode()

header  = b64url(json.dumps({"alg": "ES256", "kid": key_id}, separators=(',', ':')))
payload = b64url(json.dumps({"iss": team_id, "iat": now, "exp": now + 15552000}, separators=(',', ':')))

sig_der  = private_key.sign(f"{header}.{payload}".encode(), ec.ECDSA(hashes.SHA256()))
r, s     = decode_dss_signature(sig_der)
print(f"{header}.{payload}.{b64url(r.to_bytes(32, 'big') + s.to_bytes(32, 'big'))}")
PYSCRIPT
}

_music_token() {
  if [[ -f "$_MUSIC_TOKEN_CACHE" ]]; then
    local token payload exp now
    token=$(cat "$_MUSIC_TOKEN_CACHE")
    payload="${token#*.}"; payload="${payload%%.*}"
    local pad=$(( (4 - ${#payload} % 4) % 4 ))
    exp=$(printf '%s%*s' "$payload" "$pad" '' | tr ' ' '=' \
      | base64 -d 2>/dev/null \
      | python3 -c "import sys,json; print(json.load(sys.stdin).get('exp',0))" 2>/dev/null)
    now=$(date +%s)
    (( exp - now > 86400 )) && { echo "$token"; return 0; }
  fi
  local token
  token=$(_music_gen_token) || return 1
  mkdir -p "${_MUSIC_TOKEN_CACHE%/*}"
  echo "$token" > "$_MUSIC_TOKEN_CACHE"
  echo "$token"
}

_music_now_playing() {
  local state name artist
  state=$(osascript -e 'tell application "Music" to get player state' 2>/dev/null)
  case "$state" in
    playing)
      name=$(osascript -e 'tell application "Music" to get name of current track' 2>/dev/null)
      artist=$(osascript -e 'tell application "Music" to get artist of current track' 2>/dev/null)
      echo "▶  $name — $artist"
      ;;
    paused)
      name=$(osascript -e 'tell application "Music" to get name of current track' 2>/dev/null)
      artist=$(osascript -e 'tell application "Music" to get artist of current track' 2>/dev/null)
      echo "⏸  $name — $artist"
      ;;
    *) echo "■  Not playing" ;;
  esac
}

music_ui() {
  # One combined call — state + loved status (nested try so loved failure won't wipe name/artist)
  local raw_state
  raw_state=$(osascript \
    -e 'tell application "Music"' \
    -e '  set s to player state as string' \
    -e '  try' \
    -e '    set n to name of current track' \
    -e '    set ar to artist of current track' \
    -e '    set lv to "false"' \
    -e '    try' \
    -e '      set lv to loved of current track as string' \
    -e '    end try' \
    -e '    return s & "|" & n & "|" & ar & "|" & lv' \
    -e '  on error' \
    -e '    return s & "|||false"' \
    -e '  end try' \
    -e 'end tell' 2>/dev/null)

  local parts=("${(@s:|:)raw_state}")
  local state="${parts[1]}" track_name="${parts[2]}" track_artist="${parts[3]}" loved="${parts[4]}"

  local now_playing="■  Not playing"
  local love_option="  ♥  Love Track"
  if [[ "$state" == "playing" || "$state" == "paused" ]]; then
    local icon="▶"; [[ "$state" == "paused" ]] && icon="⏸"
    now_playing="$icon  $track_name — $track_artist"
    [[ "$loved" == "true" ]] && love_option="  ♡  Unlove Track" || love_option="  ♥  Love Track"
  fi

  local _preview_script
  _preview_script=$(mktemp /tmp/.music-preview-XXXX.sh)
  cat > "$_preview_script" <<'PREVIEW'
#!/bin/zsh
raw=$(osascript \
  -e 'tell application "Music"' \
  -e '  set s to player state as string' \
  -e '  try' \
  -e '    set n to name of current track' \
  -e '    set ar to artist of current track' \
  -e '    set al to album of current track' \
  -e '    set d to duration of current track as integer' \
  -e '    set p to player position as integer' \
  -e '    set lv to "false"' \
  -e '    try' \
  -e '      set lv to loved of current track as string' \
  -e '    end try' \
  -e '    return s & "|" & n & "|" & ar & "|" & al & "|" & d & "|" & p & "|" & lv' \
  -e '  on error' \
  -e '    return s' \
  -e '  end try' \
  -e 'end tell' 2>/dev/null)

parts=("${(@s:|:)raw}")
state="${parts[1]}"

[[ -z "$state" || "$state" == "stopped" ]] && { printf "\n  ■  Nothing playing\n"; exit 0; }

name="${parts[2]}"
artist="${parts[3]}"
album="${parts[4]}"
dur="${parts[5]:-0}"
pos="${parts[6]:-0}"
loved="${parts[7]}"

icon="▶"; [[ "$state" == "paused" ]] && icon="⏸"
heart="♡"; [[ "$loved" == "true" ]] && heart="♥"

dmin=$(( dur / 60 )); dsec=$(( dur % 60 ))
pmin=$(( pos / 60 )); psec=$(( pos % 60 ))

printf "\n  %s  %s\n\n  Artist   %s\n  Album    %s\n  Time     %d:%02d / %d:%02d\n  Loved    %s\n" \
  "$icon" "$name" "$artist" "$album" "$pmin" "$psec" "$dmin" "$dsec" "$heart"
PREVIEW
  chmod +x "$_preview_script"

  local choice
  choice=$(printf '%s\n' \
    "  ▶/⏸  Play/Pause" \
    "  ⏭   Next Track" \
    "  ⏮   Previous Track" \
    "$love_option" \
    "  🔍  Search Catalog" \
    "  🎵  Stations" \
    | fzf "${FZF_THEME[@]}" \
        --border=rounded \
        --border-label='  ♫  MUSIC  ' \
        --color=label:#00ff00 \
        --prompt='  ❯ ' \
        --header="  $now_playing" \
        --header-first \
        --no-sort \
        --height=60% \
        --preview="zsh '$_preview_script'" \
        --preview-window=right:40%:wrap \
        --preview-label='  Now Playing  ') || { rm -f "$_preview_script"; return; }

  rm -f "$_preview_script"

  case "${choice##  }" in
    "▶/⏸  Play/Pause")
      osascript -e 'tell application "Music" to playpause'
      sleep 0.3
      _MUSIC_MSG="  ♫  $(_music_now_playing)"
      ;;
    "⏭   Next Track")
      osascript -e 'tell application "Music" to next track'
      sleep 0.8
      _MUSIC_MSG="  ⏭  $(_music_now_playing)"
      ;;
    "⏮   Previous Track")
      osascript -e 'tell application "Music" to previous track'
      sleep 0.8
      _MUSIC_MSG="  ⏮  $(_music_now_playing)"
      ;;
    "♥  Love Track")
      osascript -e 'tell application "Music" to set loved of current track to true'
      _MUSIC_MSG="  ♥  Loved: $track_name"
      ;;
    "♡  Unlove Track")
      osascript -e 'tell application "Music" to set loved of current track to false'
      _MUSIC_MSG="  ♡  Unloved: $track_name"
      ;;
    "🔍  Search Catalog") music_ui_search ;;
    "🎵  Stations")        music_ui_stations ;;
  esac
}

music_ui_search() {
  # fzf as input box — stays in fzf, no terminal drop
  local fzf_out fzf_exit
  fzf_out=$(: | fzf "${FZF_THEME[@]}" \
    --print-query \
    --border=rounded \
    --border-label='  ♫  SEARCH  ' \
    --color=label:#00ff00 \
    --prompt='  ❯ ' \
    --header='  Type to search · Enter to search · Esc to cancel' \
    --header-first \
    --height=20%)
  fzf_exit=$?
  local query
  query=$(echo "$fzf_out" | head -1 | xargs 2>/dev/null)
  [[ $fzf_exit -eq 130 || -z "$query" ]] && return

  local token
  token=$(_music_token) || { _MUSIC_MSG="  ❌ Token error — check APPLE_MUSIC_* in ~/.secrets"; return 1; }

  local encoded_query
  encoded_query=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$query" 2>/dev/null)

  local raw results
  raw=$(curl -sf \
    -H "Authorization: Bearer $token" \
    "https://api.music.apple.com/v1/catalog/us/search?term=${encoded_query}&types=songs&limit=25" 2>/dev/null)

  results=$(echo "$raw" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for s in data.get('results', {}).get('songs', {}).get('data', []):
    a = s.get('attributes', {})
    name   = a.get('name', '').replace('\t', ' ')
    artist = a.get('artistName', '').replace('\t', ' ')
    album  = a.get('albumName', '').replace('\t', ' ')
    url    = a.get('url', '')
    print(f'{name}\t{artist}\t{album}\t{url}')
" 2>/dev/null)

  [[ -z "$results" ]] && { _MUSIC_MSG="  ♫  No results for: $query"; return; }

  local selected
  selected=$(echo "$results" \
    | awk -F'\t' '{printf "  %-38s  %-22s  %s\t%s\n", $1, $2, $3, $4}' \
    | fzf "${FZF_THEME[@]}" \
        --border=rounded \
        --border-label='  ♫  SEARCH RESULTS  ' \
        --color=label:#00ff00 \
        --prompt='  ❯ ' \
        --header="  Results for: $query" \
        --header-first \
        --delimiter=$'\t' \
        --with-nth=1) || return

  local url
  url=$(echo "$selected" | cut -f2)
  [[ -z "$url" ]] && return

  osascript -e "open location \"${url/https:\/\/music.apple.com/musics://music.apple.com}\""
  sleep 1
  _MUSIC_MSG="  ♫  $(_music_now_playing)"
}

music_ui_stations() {
  local choice
  choice=$(printf '%s\n' \
    "  🎸  Brandon's Station" \
    "  💀  Bad Omens" \
    "  🤘  I Prevail" \
    "  🌑  Bring Me the Horizon" \
    | fzf "${FZF_THEME[@]}" \
        --border=rounded \
        --border-label='  ♫  STATIONS  ' \
        --color=label:#00ff00 \
        --prompt='  ❯ ' \
        --no-sort \
        --height=30%) || return

  local url
  case "${choice##  }" in
    "🎸  Brandon's Station")    url='musics://music.apple.com/us/station/brandons-station/ra.u-40787829f08b63e81abb70ff757aa95f' ;;
    "💀  Bad Omens")            url='musics://music.apple.com/us/station/bad-omens-similar-artists-station/ra.467610583' ;;
    "🤘  I Prevail")            url='musics://music.apple.com/us/station/i-prevail-similar-artists-station/ra.948448824' ;;
    "🌑  Bring Me the Horizon") url='musics://music.apple.com/us/station/bring-me-the-horizon-similar-artists-station/ra.121043936' ;;
  esac
  [[ -n "$url" ]] && osascript -e "open location \"$url\""
  sleep 0.8
  _MUSIC_MSG="  ♫  $(_music_now_playing)"
}

_music_widget() {
  zle -I
  _MUSIC_MSG=""
  { music_ui } always {
    zle reset-prompt
    zle -R
    [[ -n "$_MUSIC_MSG" ]] && zle -M "$_MUSIC_MSG"
  }
}
zle -N _music_widget
bindkey '^]' _music_widget
