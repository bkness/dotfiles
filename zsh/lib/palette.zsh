# ---------------------------------------
# Ctrl+P Command Palette
# Reads live from PLUGIN_REGISTRY and _HOOKS
# ---------------------------------------

_palette_entries() {
  local icon="◆"

  _palette_row() {
    local cmd="$1"
    local category="$2"
    local desc="$3"
    printf "%s  %-24s │ %-7s │ %s\n" "$icon" "$cmd" "$category" "$desc"
  }

  # --- Workflow commands ---
  _palette_row "dev" "cmd" "Open project picker"
  _palette_row "p" "cmd" "Fuzzy pick any project"
  _palette_row "pr" "cmd" "Pick project + open in editor"
  _palette_row "newproj" "cmd" "Create a new project"
  _palette_row "quick_edit_readme" "cmd" "Edit README in current project"
  _palette_row "_explorer_widget" "cmd" "Browse files (Ctrl+E)"

  # --- Shell ---
  _palette_row "reload" "shell" "Restart shell (decrements counter)"
  _palette_row "sz" "shell" "Soft reload (source .zshrc, no restart)"
  _palette_row "safe" "shell" "Clean shell session (no config)"
  _palette_row "bye" "shell" "Clean exit + fires offline"

  # --- Status ---
  _palette_row "online" "status" "Manually set online"
  _palette_row "offline" "status" "Manually set offline"

  # --- Forged CLI ---
  _palette_row "forged gen pass" "forged" "Generate secure password"
  _palette_row "forged gen secret" "forged" "Generate 32-byte hex secret (JWT/API keys)"
  _palette_row "forged gen pin" "forged" "Generate 6-digit PIN"
  _palette_row "forged gen uuid" "forged" "Generate UUID v4"
  _palette_row "scan" "forged" "Scan deps + push cache to badge"
  _palette_row "scan-repos" "forged" "Batch scan multiple repos"
  _palette_row "forged readme" "forged" "Interactive README generator"
  _palette_row "forged init" "forged" "Bootstrap dev environment"

  # --- Git ---
  _palette_row "cb" "git" "Create and switch to new branch"
  _palette_row "cm" "git" "Switch to main or master"
  _palette_row "gbr" "git" "Fuzzy switch any branch"
  _palette_row "gs" "git" "git status"
  _palette_row "gp" "git" "git push"
  _palette_row "gpl" "git" "git pull"
  _palette_row "gl" "git" "git log (graph)"

  # --- GitHub ---
  _palette_row "ghui" "github" "GitHub dashboard"
  _palette_row "github_ui_prs" "github" "Pull requests"
  _palette_row "github_ui_issues" "github" "Issues"
  _palette_row "github_ui_repos" "github" "My repos"
  _palette_row "github_ui_clone" "github" "Clone a repo"
  _palette_row "github_ui_new" "github" "Create new repo"

  # --- Dev utilities ---
  _palette_row "killport" "util" "Kill process on a port"
  _palette_row "serve" "util" "Start local HTTP server"
  _palette_row "ports" "util" "Show all listening ports"
  _palette_row "envload" "util" "Load .env into current shell"
  _palette_row "take" "util" "mkdir + cd in one step"
  _palette_row "j" "util" "Jump anywhere (zoxide)"
  _palette_row "fcd" "util" "Fuzzy cd with file preview (fd + fzf)"
  _palette_row "refresh-dev-cache" "util" "Rebuild project cache"

  # --- Shell introspection ---
  _palette_row "vared PLUGIN_REGISTRY" "debug" "Inspect plugin registry"
  _palette_row "vared _HOOKS" "debug" "Inspect hook registry"
  _palette_row "zprof" "debug" "Profile shell startup"
  _palette_row "fmt_demo" "debug" "Show printf width/precision examples"
  _palette_row "fmt_palette_tune" "debug" "Preview real palette rows at custom widths"

  # --- Live: registered plugins ---
  for key in ${(k)PLUGIN_REGISTRY}; do
    local fn="${PLUGIN_REGISTRY[$key]}"
    _palette_row "$fn" "plugin" "Boot plugin: $key"
  done

  # --- Live: registered hooks ---
  for event in ${(k)_HOOKS}; do
    for fn in ${(z)_HOOKS[$event]}; do
      _palette_row "$fn" "hook" "on event: $event"
    done
  done
}

fmt_demo() {
  local width_cmd="${1:-24}"
  local width_cat="${2:-7}"
  local cmd_rule="$(printf '%*s' "$width_cmd" '' | tr ' ' '-')"
  local cat_rule="$(printf '%*s' "$width_cat" '' | tr ' ' '-')"

  printf "\n%s\n" "printf demo (cmd width=${width_cmd}, cat width=${width_cat})"
  printf "%-${width_cmd}s │ %-${width_cat}s │ %s\n" "Command" "Type" "Description"
  printf "%s-┼-%s-┼-%s\n" "$cmd_rule" "$cat_rule" "------------------------------"

  local cmd1="p"
  local cmd2="refresh-dev-cache"
  local cmd3="very-long-command-name-that-will-overflow"

  printf "%-${width_cmd}s │ %-${width_cat}s │ %s\n" "$cmd1" "cmd" "Short command"
  printf "%-${width_cmd}s │ %-${width_cat}s │ %s\n" "$cmd2" "util" "Fits well in most widths"
  printf "%-${width_cmd}s │ %-${width_cat}s │ %s\n" "$cmd3" "debug" "Minimum width only (no truncation)"

  printf "\n%s\n" "With truncation (stable columns):"
  printf "%-${width_cmd}.${width_cmd}s │ %-${width_cat}.${width_cat}s │ %s\n" "Command" "Type" "Description"
  printf "%-${width_cmd}.${width_cmd}s │ %-${width_cat}.${width_cat}s │ %s\n" "$cmd1" "cmd" "Short command"
  printf "%-${width_cmd}.${width_cmd}s │ %-${width_cat}.${width_cat}s │ %s\n" "$cmd2" "util" "Fits well in most widths"
  printf "%-${width_cmd}.${width_cmd}s │ %-${width_cat}.${width_cat}s │ %s\n" "$cmd3" "debug" "Clipped to width"

  printf "\n%s\n" "Try: fmt_demo 30 10"
}

fmt_palette_tune() {
  local width_cmd="${1:-24}"
  local width_cat="${2:-7}"
  local cmd_rule="$(printf '%*s' "$width_cmd" '' | tr ' ' '-')"
  local cat_rule="$(printf '%*s' "$width_cat" '' | tr ' ' '-')"

  printf "\n\033[32mfmt_palette_tune\033[0m — real palette rows at cmd=%-s cat=%-s\n\n" "$width_cmd" "$width_cat"
  printf "%-${width_cmd}.${width_cmd}s │ %-${width_cat}.${width_cat}s │ %s\n" "Command" "Category" "Description"
  printf "%s-┼-%s-┼-%s\n" "$cmd_rule" "$cat_rule" "------------------------------"

  # Print every static entry through the chosen widths
  local entries=(
    "dev:cmd:Open project picker"
    "p:cmd:Fuzzy pick any project"
    "pr:cmd:Pick project + open in editor"
    "newproj:cmd:Create a new project"
    "quick_edit_readme:cmd:Edit README in current project"
    "_explorer_widget:cmd:Browse files"
    "reload:shell:Restart shell"
    "sz:shell:Soft reload"
    "safe:shell:Clean shell session"
    "bye:shell:Clean exit"
    "online:status:Manually set online"
    "offline:status:Manually set offline"
    "forged gen pass:forged:Generate secure password"
    "forged gen secret:forged:Generate 32-byte hex secret"
    "forged gen pin:forged:Generate 6-digit PIN"
    "forged gen uuid:forged:Generate UUID v4"
    "scan:forged:Scan deps"
    "scan-repos:forged:Batch scan multiple repos"
    "forged readme:forged:Interactive README generator"
    "forged init:forged:Bootstrap dev environment"
    "cb:git:Create and switch to new branch"
    "cm:git:Switch to main or master"
    "gbr:git:Fuzzy switch any branch"
    "gs:git:git status"
    "gp:git:git push"
    "gpl:git:git pull"
    "gl:git:git log (graph)"
    "ghui:github:GitHub dashboard"
    "github_ui_prs:github:Pull requests"
    "github_ui_issues:github:Issues"
    "github_ui_repos:github:My repos"
    "github_ui_clone:github:Clone a repo"
    "github_ui_new:github:Create new repo"
    "killport:util:Kill process on a port"
    "serve:util:Start local HTTP server"
    "ports:util:Show all listening ports"
    "envload:util:Load .env into current shell"
    "take:util:mkdir + cd in one step"
    "j:util:Jump anywhere (zoxide)"
    "fcd:util:Fuzzy cd with file preview"
    "refresh-dev-cache:util:Rebuild project cache"
    "vared PLUGIN_REGISTRY:debug:Inspect plugin registry"
    "vared _HOOKS:debug:Inspect hook registry"
    "zprof:debug:Profile shell startup"
    "fmt_demo:debug:Show printf width examples"
    "fmt_palette_tune:debug:Preview real palette rows at custom widths"
  )

  for entry in "${entries[@]}"; do
    local cmd="${entry%%:*}"
    local rest="${entry#*:}"
    local cat="${rest%%:*}"
    local desc="${rest#*:}"
    printf "%-${width_cmd}.${width_cmd}s │ %-${width_cat}.${width_cat}s │ %s\n" "$cmd" "$cat" "$desc"
  done

  printf "\n\033[32mHappy with these widths?\033[0m Edit _palette_row in palette.zsh:\n"
  printf "  printf \"%%s  %%-${width_cmd}s │ %%-${width_cat}s │ %%s\\\\n\" \"\$icon\" \"\$cmd\" \"\$category\" \"\$desc\"\n"
  printf "\nTry: fmt_palette_tune 20 8\n"
}

_palette_preview() {
  local line="$1"
  local cmd=$(echo "$line" | awk -F'│' '{print $1}' | sed 's/^[[:space:]]*[^ ]* *//' | xargs)
  local category=$(echo "$line" | awk -F'│' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2}')
  local desc=$(echo "$line" | awk -F'│' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $3); print $3}')

  printf "\033[32mCommand:\033[0m  %s\n" "$cmd"
  printf "\033[32mCategory:\033[0m %s\n" "$category"
  printf "\033[32mInfo:\033[0m     %s\n\n" "$desc"

  # Show function source if it exists
  if typeset -f "$cmd" >/dev/null 2>&1; then
    printf "\033[32mSource:\033[0m\n"
    typeset -f "$cmd" | head -20
  fi
}

_palette_widget() {
  local selected
  selected=$(
    _palette_entries \
    | fzf "${FZF_THEME[@]}" \
        --border=rounded \
        --border-label='  ◈  COMMAND PALETTE  ' \
        --prompt='  ❯ ' \
        --header='  Ctrl+P — your entire ecosystem' \
        --header-first \
        --with-nth=1 \
        --delimiter='│' \
        --preview='
          cmd=$(echo {} | awk -F"│" "{print \$1}" | sed "s/^[[:space:]]*[^ ]* *//" | xargs)
          cat=$(echo {} | awk -F"│" "{print \$2}" | xargs)
          desc=$(echo {} | awk -F"│" "{print \$3}" | xargs)
          printf "\033[32mCommand:\033[0m  %s\n" "$cmd"
          printf "\033[32mCategory:\033[0m %s\n" "$cat"
          printf "\033[32mInfo:\033[0m     %s\n\n" "$desc"
          if typeset -f "$cmd" >/dev/null 2>&1; then
            printf "\033[32mSource:\033[0m\n"
            typeset -f "$cmd" 2>/dev/null | head -25
          fi
        ' \
        --preview-window=right:50%:wrap \
        --preview-label='  Info  '
  ) || return

  # Extract the command (first column, strip emoji + leading space)
  local cmd
  cmd=$(echo "$selected" | awk -F'│' '{print $1}' | sed 's/^[[:space:]]*[^ ]* *//' | xargs)

  [[ -z "$cmd" ]] && return

  # Put it in the buffer so user can confirm or edit before running
  BUFFER="$cmd"
  CURSOR=${#BUFFER}
  zle redisplay
}

zle -N _palette_widget
bindkey '^P' _palette_widget
