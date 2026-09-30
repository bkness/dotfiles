# ---------------------------------------
# Project Cache System
# ---------------------------------------

DEV_CACHE="$HOME/.dev-projects-cache"

refresh-dev-cache() {
  # A fresh machine may not have $DEV_ROOT yet; an empty cache beats fd errors
  [[ -d "$DEV_ROOT" ]] || { : > "$DEV_CACHE"; return 0 }
  fd . "$DEV_ROOT" -td -d3 > "$DEV_CACHE"
}

# Auto-refresh cache if missing or empty
[[ ! -s "$DEV_CACHE" ]] && refresh-dev-cache &!

# Recent projects list
DEV_RECENT="$HOME/.dev-recent"

add-recent() {
  echo "$PWD" >> "$DEV_RECENT"
  awk '!seen[$0]++' "$DEV_RECENT" | tail -50 > "$DEV_RECENT.tmp" && mv "$DEV_RECENT.tmp" "$DEV_RECENT"
}
