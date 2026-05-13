#!/usr/bin/env zsh
exec > /tmp/boot.log 2>&1
set -x

# 1. Wait for server + DisplayLink warmup
sleep 60

# 2. Load env vars
source /Users/ghost/dev/dotfiles/zsh/env.zsh

# 3. Music
[[ $(osascript -e 'tell application "Music" to get player state' 2>/dev/null) != "playing" ]] && \
  osascript -e 'open location "musics://music.apple.com/us/station/brandons-station/ra.u-40787829f08b63e81abb70ff757aa95f"' &!

# 4. Wait for iTerm2 to open from Login Items
sleep 10

# 5. Notification
osascript -e 'display notification "● lights on | music up | workspace ready" with title "Boot complete"' &!
