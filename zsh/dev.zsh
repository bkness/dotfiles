
# Ensure DEV_ROOT is set
if [[ -z "$DEV_ROOT" ]]; then
  echo "❌ DEV_ROOT is not set. Please export DEV_ROOT to your projects directory."
  return 1
fi

# Engine

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
  
  cat <<EOF > README.md
# $name

Project created on $(date "+%Y-%m-%d").
EOF
  
  # Optional: create .gitignore
  cat <<EOF > .gitignore
node_modules
.env
dist
build
.DS_Store
EOF

  # Optionals: create .env.example
  cat <<EOF > .env.example
  # Environment variables
  # EXAMPLE_KEY=your_value_here
EOF  

  # GitHub CLI integration
  if command -v gh >/dev/null; then
    read "create_remote?Create GitHub repo? (y/n): "
    if [[ "$create_remote" == "y" ]]; then
      gh repo create "$name" --public --source=. --remote=origin --push
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

  # Node project
  if [[ -f package.json ]]; then
    echo "📦 Node project detected"

    if [[ ! -d node_modules ]]; then
      echo "Installing dependencies..."
      if ! npm install; then
        echo "❌ npm install failed. Check your npm logs."
        return 1
      fi
    fi

    command -v code >/dev/null && nohup code . >/dev/null 2>&1 &

    if command -v jq >/dev/null && jq -e '.scripts.dev' package.json >/dev/null 2>&1; then
      echo "▶︎ Starting dev server..."
      if ! npm run dev; then
        echo "❌ npm run dev failed."
        return 1
      fi
    fi
    
    return
  fi
    
  # Python project
  if [[ -f requirements.txt ]]; then
    echo "🐍 Python project detected"

    command -v code >/dev/null && nohup code . >/dev/null 2>&1 &

    if [[ ! -d .venv ]]; then
      echo "Creating virtual environment..."
      if ! python3 -m venv .venv; then
        echo "❌ Failed to create virtual environment."
        return 1
      fi
    fi
    
    source .venv/bin/activate
    if ! pip install -r requirements.txt >/dev/null 2>&1; then
      echo "❌ pip install failed. Check requirements.txt and your Python environment."
      return 1
    fi
    
    return
  fi

  # Rust project
  if [[ -f Cargo.toml ]]; then
    echo "🦀 Rust project detected"

    command -v code >/dev/null && nohup code . >/dev/null 2>&1 &
    
    if command -v cargo-watch >/dev/null; then
      if ! cargo watch -x run; then
        echo "❌ cargo watch failed."
        return 1
      fi
    else
      if ! cargo run; then
        echo "❌ cargo run failed."
        return 1
      fi
    fi
    return
  fi
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
    echo "❌ zoxide not found. Please install zoxide or use 'cd' manually."
  fi
}

# Open projects via fuzzy search
p() {
  local dir
  if ! command -v fzf >/dev/null; then
    echo "❌ fzf not found. Please install fzf."
    return 1
  fi

  if command -v fd >/dev/null; then
    local search_cmd="fd . \"$DEV_ROOT\" -td -d3"
  else
    echo "❌ fd not found. Falling back to find."
    local search_cmd="find \"$DEV_ROOT\" -type d -maxdepth 3"
  fi

  dir=$(eval "$search_cmd" | fzf --height 40% --reverse --border \
        --prompt="Project > " \
        --preview="$(project_preview_cmd)" \
        --preview-window=right:50%) || return

  cd "$dir"
}

# Open + Run workflow
pr() {
  p || return
  command -v code >/dev/null && nohup code . >/dev/null 2>&1 &
}

dashboard() {
  project_dashboard
}
