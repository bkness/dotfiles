# ---------------------------------------
# Project Cache System
# ---------------------------------------

DEV_CACHE="$HOME/.dev-projects-cache"

refresh-dev-cache() {
  fd . "$DEV_ROOT" -td -d3 > "$DEV_CACHE"
}

# Auto-refresh cache if missing or empty
[[ ! -s "$DEV_CACHE" ]] && refresh-dev-cache

# Recent projects list
DEV_RECENT="$HOME/.dev-recent"

add-recent() {
  echo "$PWD" >> "$DEV_RECENT"
  awk '!seen[$0]++' "$DEV_RECENT" > "$DEV_RECENT.tmp" && mv "$DEV_RECENT.tmp" "$DEV_RECENT"
}