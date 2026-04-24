# ---------------------------------------
# Ctrl+P Command Palette
# Reads live from PLUGIN_REGISTRY and _HOOKS
# ---------------------------------------

_palette_entries() {
  # --- Workflow commands ---
  print -r "⚡  dev               │ cmd    │ Open project picker"
  print -r "📁  p                 │ cmd    │ Fuzzy pick any project"
  print -r "🚀  pr                │ cmd    │ Pick project + open in editor"
  print -r "🆕  newproj           │ cmd    │ Create a new project"
  print -r "🔄  reload            │ cmd    │ Restart shell"
  print -r "📝  quick_edit_readme  │ cmd    │ Edit README in current project"

  # --- Git ---
  print -r "🌿  chbr              │ git    │ Create and switch to new branch"
  print -r "🏠  cmst              │ git    │ Switch to main or master"
  print -r "🔀  gbr               │ git    │ Fuzzy switch any branch"
  print -r "📊  gs                │ git    │ git status"
  print -r "📤  gp                │ git    │ git push"
  print -r "📥  gpl               │ git    │ git pull"
  print -r "📋  gl                │ git    │ git log (graph)"

  # --- GitHub ---
  print -r "🐙  ghui              │ github │ GitHub dashboard"
  print -r "🔀  github_ui_prs     │ github │ Pull requests"
  print -r "🐛  github_ui_issues  │ github │ Issues"
  print -r "📋  github_ui_repos   │ github │ My repos"
  print -r "📥  github_ui_clone   │ github │ Clone a repo"
  print -r "🆕  github_ui_new     │ github │ Create new repo"

  # --- Dev utilities ---
  print -r "🔌  killport          │ util   │ Kill process on a port"
  print -r "🌐  serve             │ util   │ Start local HTTP server"
  print -r "🔍  ports             │ util   │ Show all listening ports"
  print -r "📦  envload           │ util   │ Load .env into current shell"
  print -r "📂  take              │ util   │ mkdir + cd in one step"
  print -r "🔭  j                 │ util   │ Jump anywhere (zoxide)"

  # --- Shell introspection ---
  print -r "🔬  vared PLUGIN_REGISTRY │ debug │ Inspect plugin registry"
  print -r "🔬  vared _HOOKS          │ debug │ Inspect hook registry"
  print -r "⚙️   zprof                │ debug │ Profile shell startup"

  # --- Live: registered plugins ---
  for key in ${(k)PLUGIN_REGISTRY}; do
    local fn="${PLUGIN_REGISTRY[$key]}"
    print -r "🔌  $fn  │ plugin │ Boot plugin: $key"
  done

  # --- Live: registered hooks ---
  for event in ${(k)_HOOKS}; do
    for fn in ${(z)_HOOKS[$event]}; do
      print -r "🪝  $fn  │ hook   │ on event: $event"
    done
  done
}

_palette_preview() {
  local line="$1"
  local cmd=$(echo "$line" | awk -F'│' '{gsub(/^[[:space:][:alnum:][:punct:]]*[[:space:]]/, "", $1); print $1}' | xargs)
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

export -f _palette_preview 2>/dev/null || true

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
