
# ---------------------------------------
# Project Templates
# ---------------------------------------

project_template_node() {
  mkdir -p src
  echo "console.log('Hello World');" > src/index.js
cat <<EOF > package.json
{
  "name": "app",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
     "dev": "node src/index.js"
  }
}
EOF
}

project_template_python() {
  echo "# Python project" > main.py
  echo "requests" > requirements.txt
}

project_template_rust() {
  cargo init --quiet
}

project_apply_template() {
  case "$1" in
    node)   project_template_node ;;
    python) project_template_python ;;
    rust)   project_template_rust ;;
    *)
      echo "Unknown template: $1"
      echo "Available: node | python | rust"
      return 1
      ;;
  esac
}

# ---------------------------------------
# Project Dashboard
# ---------------------------------------

project_ui() {
  local header="  $(pwd | sed "s|$HOME|~|")  ·  $(date +%H:%M)"

  local choice
  choice=$(printf '%s\n' \
    "  📁  Open Project" \
    "  🚀  Open + Start" \
    "  🆕  Create Project" \
    "  🕒  Recent Projects" \
    "  💼  List All Projects" \
    "  📝  Edit Readme" \
    "  🐙  GitHub" \
    "  🔄  Refresh Cache" \
    "  🧹  Clear Cache" \
    "  🧪  Detect Project Type" \
    "  🛠   Settings" \
    | fzf "${FZF_THEME[@]}" \
        --border=rounded \
        --border-label='  ◈  DEV  ' \
        --header="$header" \
        --header-first \
        --height=85% \
        --no-preview \
        --prompt='  ❯ ') || return

  case "${choice## }" in
    "📁  Open Project")      project_ui_open ;;
    "🚀  Open + Start")      project_ui_open_and_boot ;;
    "🆕  Create Project")    newproj ;;
    "🕒  Recent Projects")   project_ui_recent ;;
    "💼  List All Projects") project_ui_list ;;
    "📝  Edit Readme")       quick_edit_readme ;;
    "🐙  GitHub")            github_ui ;;
    "🔄  Refresh Cache")     refresh-dev-cache; echo "✅ Cache refreshed" ;;
    "🧹  Clear Cache")
      : > "$DEV_CACHE"
      echo "🧹 Cache cleared"
      refresh-dev-cache
      ;;
    "🧪  Detect Project Type") project_ui_detect ;;
    "🛠   Settings")           echo "⚙️  Coming soon" ;;
  esac
}

# ---------------------------------------
# Project pickers
# ---------------------------------------

_project_preview='
  if [[ -f {}/README.md ]]; then
    bat --style=plain --color=always {}/README.md 2>/dev/null
  else
    eza -la --icons -1 {} 2>/dev/null
  fi
'

project_ui_open() {
  command -v fzf >/dev/null || return

  local dir
  dir=$(cat "$DEV_CACHE" \
    | fzf "${FZF_THEME[@]}" \
          --border=rounded \
          --border-label='  ◈  OPEN PROJECT  ' \
          --prompt='  ❯ ' \
          --preview="$_project_preview" \
          --preview-window=right:55% \
          --preview-label='  Preview  ') || return

  cd "$dir" && add-recent && refresh-dev-cache
}

project_ui_open_and_boot() {
  command -v fzf >/dev/null || return

  local dir
  dir=$(cat "$DEV_CACHE" \
    | fzf "${FZF_THEME[@]}" \
          --border=rounded \
          --border-label='  ◈  OPEN + START  ' \
          --prompt='  ❯ ' \
          --preview="$_project_preview" \
          --preview-window=right:55% \
          --preview-label='  Preview  ') || return

  cd "$dir" && add-recent && refresh-dev-cache

  local type
  type=$(project_detect)
  if [[ "$type" == "unknown" ]]; then
    echo "⚠️  Could not detect project type — dropping into shell"
    return
  fi

  boot_project "$type"
}

project_ui_list() {
  local dir
  dir=$(cat "$DEV_CACHE" \
    | fzf "${FZF_THEME[@]}" \
          --border=rounded \
          --border-label='  ◈  ALL PROJECTS  ' \
          --prompt='  ❯ ' \
          --preview="$_project_preview" \
          --preview-window=right:55% \
          --preview-label='  Preview  ') || return
  cd "$dir" && add-recent
}

project_ui_recent() {
  [[ ! -s "$DEV_RECENT" ]] && { echo "No recent projects"; return; }

  local dir
  dir=$(cat "$DEV_RECENT" \
    | fzf "${FZF_THEME[@]}" \
          --border=rounded \
          --border-label='  ◈  RECENT  ' \
          --prompt='  ❯ ' \
          --preview="$_project_preview" \
          --preview-window=right:55% \
          --preview-label='  Preview  ') || return

  cd "$dir" && add-recent
}

project_ui_detect() {
  if [[ -f package.json && -f requirements.txt ]]; then
    echo "🔀 Fullstack project detected"
  elif [[ -f package.json ]]; then
    echo "📦 Node.js project detected"
  elif [[ -f requirements.txt ]]; then
    echo "🐍 Python project detected"
  elif [[ -f Cargo.toml ]]; then
    echo "🦀 Rust project detected"
  else
    echo "❓ Unknown project type"
  fi
}

quick_edit_readme() {
  local readme="${PWD}/README.md"
  [[ ! -f "$readme" ]] && echo "# $(basename "$PWD")" > "$readme"
  ${EDITOR:-vim} "$readme"
}
