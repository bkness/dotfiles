# DEV_DEBUG=${DEV_DEBUG:-0}

boot_project() {
  local type="$1"

  if plugin_exists "$type"; then
     debug "Detected type: $type"
     debug "Using plugin: ${PLUGIN_REGISTRY[$type]}"
     local fn="${PLUGIN_REGISTRY[$type]}"
     "$fn"
  if ! typeset -f "$fn" >/dev/null; then
     echo "❌ Plugin function $fn not found"
     return 1
  fi
fi
}

# Create a new project
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

}

# Full "Project Open + Dev Start" command
dev() {
  local dir

  if [[ -z "$1" ]]; then
    dashboard
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

# Change branch
cb() {
  echo "$fg[magenta]New branch name?$reset_color"
  read -r branch

  if [[ -n "$branch" ]]; then
    git switch -c "$branch"
  else
    echo "❌ $fg[red]Branch name required$reset_color"
  fi

}

# Change to main or master branch
cm() {
  if git show-ref --verify --quiet refs/heads/main; then
    git switch main
  elif git show-ref --verify --quiet refs/heads/master; then
    git switch master
  else
    echo "No main or master branch found"
  fi

}

# Fuzzy branch switching
gb() {
  local branch
  branch=$(git branch --all | sed 's/^[* ]*//' | fzf) || return
  git switch "${branch#remotes/origin/}"

}

# Opens fuzzy, jumps instantly anywhere you've been
j() {
  if command -v zoxide >/dev/null; then
    cd "$(zoxide query -i)"
  else
    echo "❌ zoxide not found. Please install zoxide or use cd manually."
  fi

}

# Open projects via fuzzy search
p() {
  command -v fzf >/dev/null || return 1
  command -v fd >/dev/null || return 1
    
  cd "$(
    fd -t d -d 3 . "$DEV_ROOT" \
    | fzf --height 40% --reverse --border \
          --prompt="Projects > " \
          --preview "$(project_visuals_cmd)" \
          --preview-window=right:50%
  )"
}

# Open + Run workflow
pr() {
  p || return
  command -v code >/dev/null && nohup code . >/dev/null 2>&1 &
}

dashboard() {
  project_dashboard

}
# Ensure DEV_ROOT is set
if [[ -z "$DEV_ROOT" ]]; then
  echo "❌ DEV_ROOT is not set. Please export DEV_ROOT to your projects directory."
  return 1
fi

