#!/usr/bin/env zsh
exec > /tmp/boot.log 2>&1
set -x

# 1. Python server — direct venv path, no source needed for launchd
(/Users/ghost/dev/projects/govee-automation/.venv/bin/uvicorn main:app --reload --app-dir /Users/ghost/dev/projects/govee-automation) &!

# 2. Wait for server + DisplayLink warmup
sleep 60

# 3. Load env vars
source /Users/ghost/dev/dotfiles/zsh/env.zsh

# 4. Govee lights — inline curl, no function dependency
curl -s -X PUT "http://localhost:8000/lights/${GOVEE_OFFICE}/control?model=H6008" \
  -H "x-api-key: $GOVEE_SERVER_KEY" -H "Content-Type: application/json" \
  -d '{"name":"turn","value":"on"}' &!

curl -s -X PUT "http://localhost:8000/lights/${GOVEE_MAIN}/control?model=H610A" \
  -H "x-api-key: $GOVEE_SERVER_KEY" -H "Content-Type: application/json" \
  -d '{"name":"turn","value":"on"}' &!

# 5. Music
[[ $(osascript -e 'tell application "Music" to get player state' 2>/dev/null) != "playing" ]] && \
  osascript -e 'open location "musics://music.apple.com/us/station/brandons-station/ra.u-40787829f08b63e81abb70ff757aa95f"' &!

# 6. Wait for iTerm2 to open from Login Items
sleep 10

# 7. Notification
osascript -e 'display notification "● lights on | music up | workspace ready" with title "Boot complete"' &!
