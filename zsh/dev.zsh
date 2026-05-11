
# Fixed boot_project — guard runs BEFORE the call, not after
boot_project() {
  local type="$1"
  local fn="${PLUGIN_REGISTRY[$type]}"
  if ! typeset -f "$fn" >/dev/null 2>&1; then
    echo "❌ Plugin function $fn is registered but not loaded"
    return 1
  fi

  echo "Detected type: $type"
  echo "Using plugin: $fn"
  "$fn" || return
}

# desc: Create a new project
newproj() {
  local name dir

  # Ask for project name if not passed
  if [[ -z "$1" ]]; then
    read "name?Project name: "
  else
    name="$1"
  fi
  
  # Validate
  if [[ -z "$name" ]]; then
    echo "❌ Project name required"
    return 1
  fi
  
  dir="$DEV_ROOT/$name"
  
  # Prevent overwrite
  if [[ -d "$dir" ]]; then
    echo "⚠️ Project already exists: $dir"
    cd "$dir" || return
    return
  fi
  
  # Create project
  mkdir -p "$dir" && cd "$dir" || return

  echo "📂 Created $dir"
  
    # Ask for template 
  local template
  read "template?Template (node/python/rust/none): "
  
  [[ -z "$template" ]] && template="none"

  if [[ "$template" != "none" ]]; then
    project_apply_template "$template" || return
    echo "⚙️ Template: $template"
  fi  

  # Init git
  git init -q
  
cat <<EOF >README.md
# $name

Project created on $(date "+%Y-%m-%d").
EOF
  
  # Optional: create .gitignore
cat <<EOF >.gitignore
node_modules
.env
dist
build
.DS_Store
EOF

  # Optionals: create .env.example
cat <<EOF >.env.example
# Environment variables
# EXAMPLE_KEY=your_value_here
EOF

  # GitHub CLI integration
  if ! command -v gh >/dev/null; then
    echo "⚠️ GitHub CLI (gh) not found. Skipping GitHub repo creation."
  else
    read "create_remote?Create GitHub repo? (y/n): "
    if [[ "$create_remote" == "y" ]]; then
      gh repo create "$name" --private --source=. --remote=origin --push
      echo "🚀 GitHub repo created"
    fi
  fi

  # Open editor
  command -v code >/dev/null && nohup code . >/dev/null 2>&1 &

  echo "✅ Project ready"
  refresh-dev-cache
  add-recent
}

# desc: Full "Project Open + Dev Start" command
dev() {
  local dir

  if [[ -z "$1" ]]; then
    project_ui
    return
  fi

  # Direct open or fallback
  if [[ -d "$DEV_ROOT/$1" ]]; then
    dir="$DEV_ROOT/$1"
  else
    echo "⚠️ Not found, opening picker..."
    [[ ! -f ~/.dev-projects-cache ]] && refresh-dev-cache
    dir=$(fzf < ~/.dev-projects-cache) || return
  fi

  cd "$dir" || return
  add-recent
  refresh-dev-cache

  # Project detection and boot
  type=$(project_detect)

  if [[ "$type" == "unknown" ]]; then
    echo "⚠️ Could not detect project type, skipping boot"
    return 1
  fi

  echo "🚀 Detected project type: $type"

  boot_project "$type"
}

# desc: Change branch
cb() {
  local branch
  read "branch? New branch name: "
  [[ -z "$branch" ]] && { echo "❌ Branch name required"; return 1; }
  git switch -c "$branch" || return
  refresh-dev-cache
  add-recent
}

# desc: Change to main or master branch
cm() {
  if git show-ref --verify --quiet refs/heads/main; then
    git switch main
  elif git show-ref --verify --quiet refs/heads/master; then
    git switch master
  else
    echo "No main or master branch found"
  fi
  refresh-dev-cache
  add-recent
}

# desc: Fuzzy branch switching  
gbr() {
  local branch
  branch=$(git branch --all | sed 's/^[* ]*//' | fzf) || return
  git switch "${branch#remotes/origin/}"
  refresh-dev-cache
  add-recent
}

# desc: Opens fuzzy, jumps instantly anywhere you've been
j() {
  if command -v zoxide >/dev/null; then
    cd "$(zoxide query -i)"
  else
    echo "❌ zoxide not found. Please install zoxide or use cd manually."
  fi
  add-recent
  refresh-dev-cache
}

#--------------------------------------
# Fuzzy project picker — lists recent + cached projects, opens in one step
#--------------------------------------

# desc: Recent + cached projects picker
p() {
  command -v fzf >/dev/null || return 1
  command -v fd >/dev/null || return 1
    
  cd "$(
    fd -t d -d 1 . "$DEV_ROOT" \
    | fzf --height 40% --reverse --border \
          --prompt="Projects > " \
          --preview 'printf "Selected: %s\n\n" {} && eza -la --icons -1 {}' \
          --preview-window=right:50%
  )"  
  add-recent
  refresh-dev-cache
}

# desc: Open + Run workflow
pr() {
  p || return
  command -v code >/dev/null && nohup code . >/dev/null 2>&1 &
  add-recent
  refresh-dev-cache
}

# Ensure DEV_ROOT is set
if [[ -z "$DEV_ROOT" ]]; then
  echo "❌ DEV_ROOT is not set. Please export DEV_ROOT to your projects directory."
  return 1
fi

# ---------------------------------------
# Dev utilities
# ---------------------------------------

# #desc: mkdir + cd in one step
take() {
  mkdir -p "$1" && cd "$1"
}

# desc: Kill whatever is running on a port
killport() {
  local port="${1:?Usage: killport <port>}"
  local pid
  pid=$(lsof -ti tcp:"$port") || { echo "Nothing on port $port"; return; }
  echo "Killing PID $pid on port $port"
  kill -9 $pid
}

# desc: Show all listening ports
ports() {
  lsof -iTCP -sTCP:LISTEN -n -P | awk 'NR==1 || /LISTEN/'
}

# desc: Quick local HTTP server
serve() {
  local port="${1:-8080}"
  echo "Serving $(pwd) on http://localhost:$port"
  if command -v python3 >/dev/null; then
    python3 -m http.server "$port"
  elif command -v npx >/dev/null; then
    npx serve -l "$port"
  else
    echo "❌ Needs python3 or npx"
  fi
}

# desc: Load a .env file into the current shell
envload() {
  local file="${1:-.env}"
  [[ ! -f "$file" ]] && { echo "❌ $file not found"; return 1; }
  set -a
  source "$file"
  set +a
  echo "✅ Loaded $file"
}

