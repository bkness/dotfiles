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
      echo "Available templates: node | python | rust" 
      return 1
      ;;
    esac
}

# ---------------------------------------
# Project Dashboard
# ---------------------------------------

project_dashboard() {
  local choice

  choice=$(printf "%s\n" \
    "📁 Open Project" \
    "🆕 Create Project" \
    "🕒 Recent Projects" \
    "🔄 Refresh Project Cache" \
    "🗂 List All Projects" \
    "🧹 Clear Cache" \
    "🧪 Detect Project Type" \
    "⚙️ Settings (coming soon)" \
    | fzf --height 50% --reverse --border \
          --prompt="Dashboard > " \
          --preview 'echo {}' \
          --preview-window=down:3:wrap) || return

  case "$choice" in
    "📁 Open Project") project_dashboard_open ;;
    "🆕 Create Project") newproj ;;
    "🔄 Refresh Project Cache") refresh-dev-cache; echo "Cache refreshed" ;;
    "🕒 Recent Projects") project_dashboard_recent ;;
    "🗂 List All Projects") project_dashboard_list ;;
    "🧹 Clear Cache") 
     : > "$DEV_CACHE"
     echo "Cache cleared"
     refresh-dev-cache 
     ;;
    "🧪 Detect Project Type") project_dashboard_detect ;;
    *) echo "Not implemented yet" ;;
  esac
}

project_dashboard_open() {
    local dir
    command -v fzf >/dev/null || return 

    dir=$(cat "$DEV_CACHE" \
    | fzf --height 40% --reverse --border \
          --prompt="Open > " \
          --preview 'project_preview_cmd {}' \
          --preview-window=right:50%) || return
        
    cd "$dir"
}

project_dashboard_list() {
    cat "$DEV_CACHE" \
    | fzf --height 40% --reverse --border \
          --prompt="Projects > " \
          --preview 'eza -la --icons {}' \
          --preview-window=right:50%
}

project_dashboard_detect() {
    if [[ -f package.json ]]; then
      echo "📦 Node.js project detected"
    elif [[ -f requirements.txt ]]; then
      echo "🐍 Python project detected"
    elif [[ -f Cargo.toml ]]; then
      echo "🦀 Rust project detected"
    else
      echo "❓ Unknown project type"
    fi    
}

project_dashboard_recent() {
  [[ ! -s "$DEV_RECENT" ]] && { echo "No recent projects";return; }

  local dir
  dir=$(tac "$DEV_RECENT" \
  | fzf --height 40% --reverse --border \
        --prompt="Recent > " \
        --preview 'project_preview_cmd {}' \
        --preview-window=right:50%) || return

  cd "$dir" && add-recent
}