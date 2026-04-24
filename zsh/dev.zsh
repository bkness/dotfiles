
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
  refresh-dev-cache
  add-recent
}

# Full "Project Open + Dev Start" command
dev() {
  local dir

  if [[ -z "$1" ]]; then
    ui "🚀 Open project: "
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
chbr() {
  echo "$fg[magenta]New branch name?$reset_color"
  read "branch?prompt"

  if [[ -n "$branch" ]]; then
    git switch -c "$branch"
  else
    echo "❌ $fg[red]Branch name required$reset_color"
  fi
  refresh-dev-cache
  add-recent
}

# Change to main or master branch
cmst() {
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

# Fuzzy branch switching
gbr() {
  local branch
  branch=$(git branch --all | sed 's/^[* ]*//' | fzf) || return
  git switch "${branch#remotes/origin/}"
  refresh-dev-cache
  add-recent
}

# Opens fuzzy, jumps instantly anywhere you've been
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
#
#--------------------------------------
p() {
  command -v fzf >/dev/null || return 1
  command -v fd >/dev/null || return 1
    
  cd "$(
    fd -t d -d 3 . "$DEV_ROOT" \
    | fzf --height 40% --reverse --border \
          --prompt="Projects > " \
          --preview 'printf "Selected: %s\n\n" {} && eza -la --icons -1 {}' \
          --preview-window=right:50%
  )"
  add-recent
  refresh-dev-cache
}

# Open + Run workflow
pr() {
  p || return
  command -v code >/dev/null && nohup code . >/dev/null 2>&1 &
  add-recent
  refresh-dev-cache
}

  dashboard_ui() {
  echo "📁 List All Projects"
  }

# Ensure DEV_ROOT is set
if [[ -z "$DEV_ROOT" ]]; then
  echo "❌ DEV_ROOT is not set. Please export DEV_ROOT to your projects directory."
  return 1
fi

# Execute in terminal is just "dev" for now, but this is where we would add options for different dashboards or project lists or whatever other cool features we want to add in the future. perfect typical usage would be "dev" to open the project picker, "dev myproject" to open a specific project, and eventually we could add "dev --recent" or "dev --favorites" or "dev --dashboard" or whatever other cool features we want to add in the future. For now, just "dev" and "dev <project>" are supported but this is where we would expand from in the future as we build out more features and dashboards and stuff like that. perfect typical usage would be "dev" to open the project picker, "dev myproject" to open a specific project, and eventually we could add "dev --recent" or "dev --favorites" or "dev --dashboard" or whatever other cool features we want to add in the futur
