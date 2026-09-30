--preview='
  printf "\033[32mSelected:\033[0m %s\n" {}
  printf "\033[32m──────────────────────────────\033[0m\n\n"
  eza -la --icons -1 {}
'

edit_file_in_project() {
  local project="$1"
  local file=$(eza -1a "$project" | fzf --prompt="Edit file > ")
  [[ -n "$file" ]] && vim "$project/$file"
}

God tier readme editor with fuzzy
edit_file_in_project() {
  local project="$1"

  local file=$(
    fd . "$project" \
    | fzf --prompt="Edit > " \
          --preview 'bat --style=plain --color=always {}' \
          --preview-window=right:60%
  )

  [[ -n "$file" ]] && vim "$file"
}


## Stale branch detector
On `chpwd` into a git repo, async-check `git log HEAD..origin/main --oneline`.
If main has commits the current branch doesn't, fire a `zle -M` warning:
"⚠️  main has N commits not yet on this branch. Pull from main?"
Keep it async (&!) so it doesn't block prompt draw.

## Self-cleaning house 🧽 (roadmap, 2026-09-30)
The cockpit, extended to appliances: load everything, ship code, the house
does the rest.

1. Load the washer, dryer and dishwasher, and arm "remote start" on each
   (the machines require it, so nothing runs by accident)
2. `house go` (a command, not `git push`: we push way too often) → victory
   flash → the cycles start through their APIs
3. Each appliance flashes its own color when it finishes, plus a nag-style
   notification ("Dishes are clean. Go unload them.")
   - dishwasher → blue, washer → cyan, dryer → orange (pick later)
4. `house` command: status of every appliance (running / done / time left)

APIs to check when buying: Home Connect (Bosch, Siemens, Thermador,
Gaggenau), Samsung SmartThings, LG ThinQ. A robot vacuum with an API
(e.g. Roborock) could join as `clean`.

Constraint: Govee is ~10 requests/min for the whole account, so appliance
flashes go through the same `flash` cooldown.
