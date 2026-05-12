
 application's main() function instead of opened.
      -n, --new             Open a new instance of the application even if on#!/usr/bin/env zsh

# 1. Python server — fires immediately, gets full 45s warmup
(cd /Users/ghost/dev/projects/govee-automation && source .venv/bin/activate && uvicorn main:app --reload) &!

# 2. Wait for DisplayLink + server warmup
sleep 45

# 3. Source env so vars are available outside zsh
source /Users/ghost/dev/dotfiles/zsh/env.zsh

# 4. Everything else — server ready, displays stable
online &!
_push_shell_status &!
_govee_boot "H6008" "$GOVEE_OFFICE" &!
_govee_boot "H610A" "$GOVEE_MAIN" &!
[[ $(osascript -e 'tell application "Music" to get player state' 2>/dev/null) != "playing" ]] && \
  osascript -e 'open location "musics://music.apple.com/us/station/brandons-station/ra.u-40787829f08b63e81abb70ff757aa95f"' &!
osascript -e 'display notification "● online | lights on | music up" with title "Boot complete"' &!
~
~
~
