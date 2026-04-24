# ---------------------------------------
# GitHub CLI Dashboard
# ---------------------------------------

# Background-sync gh tab completions — zero startup cost
_gh_sync_completions() {
  local comp="$HOME/.zfunc/_gh"
  local gh_bin
  gh_bin=$(command -v gh 2>/dev/null) || return
  [[ -f "$comp" && "$comp" -nt "$gh_bin" ]] && return
  mkdir -p "$HOME/.zfunc"
  gh completion -s zsh > "$comp" 2>/dev/null
}
_gh_sync_completions &!

# ---------------------------------------
# Helpers
# ---------------------------------------

_gh_check() {
  command -v gh >/dev/null && return 0
  echo "❌ gh CLI not found. Install: brew install gh" >&2
  return 1
}

_in_github_repo() {
  git remote get-url origin 2>/dev/null | grep -q 'github\.com'
}

_gh_repo_label() {
  git remote get-url origin 2>/dev/null \
    | sed 's|.*github\.com[/:]||; s/\.git$//' \
    || echo "Global"
}

# ---------------------------------------
# Main menu
# ---------------------------------------

github_ui() {
  _gh_check || return

  local repo_options=()
  if _in_github_repo; then
    repo_options=(
      "  🔗  Open in Browser"
      "  🔀  Pull Requests"
      "  🐛  Issues"
      "  🌿  Switch Branch"
      "  📊  Repo Status"
      "  🔄  Sync Fork"
      "  ──────────────────"
    )
  fi

  local header="  $(_gh_repo_label)"
  local choice
  choice=$(printf '%s\n' \
    "${repo_options[@]}" \
    "  📋  My Repos" \
    "  📥  Clone Repo" \
    "  🆕  Create Repo" \
    | grep -v '^\s*─\+\s*$' \
    | fzf "${FZF_THEME[@]}" \
        --border=rounded \
        --border-label='  ◈  GITHUB  ' \
        --header="$header" \
        --header-first \
        --prompt='  ❯ ') || return

  case "${choice## }" in
    "🔗  Open in Browser") gh repo view --web ;;
    "🔀  Pull Requests")   github_ui_prs ;;
    "🐛  Issues")          github_ui_issues ;;
    "🌿  Switch Branch")   gbr ;;
    "📊  Repo Status")     github_ui_status ;;
    "🔄  Sync Fork")       github_ui_sync_fork ;;
    "📋  My Repos")        github_ui_repos ;;
    "📥  Clone Repo")      github_ui_clone ;;
    "🆕  Create Repo")     github_ui_new ;;
  esac
}

# ---------------------------------------
# Submenus
# ---------------------------------------

github_ui_repos() {
  local selected
  selected=$(gh repo list --limit 30 \
    --json name,isPrivate,description \
    --jq '.[] | (if .isPrivate then "🔒" else "🌐" end) + "  " + .name + "  \t" + (.description // "")' \
    | column -t -s $'\t' \
    | fzf "${FZF_THEME[@]}" \
          --border=rounded \
          --border-label='  ◈  MY REPOS  ' \
          --prompt='  ❯ ' \
          --preview='gh repo view $(echo {} | awk "{print \$2}") 2>/dev/null' \
          --preview-window=right:55% \
          --preview-label='  Info  ') || return

  local name
  name=$(echo "$selected" | awk '{print $2}')

  local action
  action=$(printf '%s\n' \
    "  🔗  Open in browser" \
    "  📥  Clone" \
    "  👁   View" \
    | fzf "${FZF_THEME[@]}" \
        --border=rounded \
        --border-label='  ◈  ACTION  ' \
        --prompt='  ❯ ' \
        --height=30%) || return

  case "${action## }" in
    "🔗  Open in browser") gh repo view "$name" --web ;;
    "📥  Clone")
      local dest="$DEV_ROOT/$(basename $name)"
      gh repo clone "$name" "$dest" \
        && cd "$dest" && add-recent && refresh-dev-cache
      ;;
    "👁   View") gh repo view "$name" ;;
  esac
}

github_ui_prs() {
  local selected
  selected=$(gh pr list --limit 30 \
    --json number,title,author,headRefName \
    --jq '.[] | "#" + (.number | tostring) + "  " + .title + "\t" + .author.login + " → " + .headRefName' \
    | column -t -s $'\t' \
    | fzf "${FZF_THEME[@]}" \
          --border=rounded \
          --border-label='  ◈  PULL REQUESTS  ' \
          --prompt='  ❯ ' \
          --preview='gh pr view $(echo {} | grep -o "^#[0-9]*" | tr -d "#") 2>/dev/null' \
          --preview-window=right:55% \
          --preview-label='  PR Details  ') || return

  local number
  number=$(echo "$selected" | grep -o '^#[0-9]*' | tr -d '#')

  local action
  action=$(printf '%s\n' \
    "  🌿  Checkout" \
    "  🔗  Open in browser" \
    "  👁   View" \
    "  ✅  Merge" \
    "  ❌  Close" \
    | fzf "${FZF_THEME[@]}" \
        --border=rounded \
        --border-label='  ◈  ACTION  ' \
        --prompt='  ❯ ' \
        --height=30%) || return

  case "${action## }" in
    "🌿  Checkout")        gh pr checkout "$number" ;;
    "🔗  Open in browser") gh pr view "$number" --web ;;
    "👁   View")           gh pr view "$number" ;;
    "✅  Merge")           gh pr merge "$number" ;;
    "❌  Close")           gh pr close "$number" ;;
  esac
}

github_ui_issues() {
  local selected
  selected=$(gh issue list --limit 30 \
    --json number,title,assignees \
    --jq '.[] | "#" + (.number | tostring) + "  " + .title + "\t" + (if (.assignees | length) > 0 then .assignees[0].login else "unassigned" end)' \
    | column -t -s $'\t' \
    | fzf "${FZF_THEME[@]}" \
          --border=rounded \
          --border-label='  ◈  ISSUES  ' \
          --prompt='  ❯ ' \
          --preview='gh issue view $(echo {} | grep -o "^#[0-9]*" | tr -d "#") 2>/dev/null' \
          --preview-window=right:55% \
          --preview-label='  Issue Details  ') || return

  local number
  number=$(echo "$selected" | grep -o '^#[0-9]*' | tr -d '#')

  local action
  action=$(printf '%s\n' \
    "  🔗  Open in browser" \
    "  👁   View" \
    "  ✅  Close" \
    "  💬  Comment" \
    | fzf "${FZF_THEME[@]}" \
        --border=rounded \
        --border-label='  ◈  ACTION  ' \
        --prompt='  ❯ ' \
        --height=30%) || return

  case "${action## }" in
    "🔗  Open in browser") gh issue view "$number" --web ;;
    "👁   View")           gh issue view "$number" ;;
    "✅  Close")           gh issue close "$number" ;;
    "💬  Comment")
      local body
      read "body?Comment: "
      [[ -n "$body" ]] && gh issue comment "$number" --body "$body"
      ;;
  esac
}

github_ui_new() {
  local name
  read "name?Repo name: "
  [[ -z "$name" ]] && return 1

  local vis
  vis=$(printf '%s\n' "  private" "  public" \
    | fzf "${FZF_THEME[@]}" \
        --border=rounded \
        --border-label='  ◈  VISIBILITY  ' \
        --prompt='  ❯ ' \
        --height=25%) || return
  vis="${vis## }"

  if _in_github_repo; then
    local reply
    read "reply?Use current directory as source? (y/n): "
    if [[ "$reply" == "y" ]]; then
      gh repo create "$name" "--$vis" --source=. --remote=origin --push \
        && echo "✅ Created and pushed: $name ($vis)"
      return
    fi
  fi

  gh repo create "$name" "--$vis" && echo "✅ Created: $name ($vis)"
}

github_ui_clone() {
  local selected
  selected=$(gh repo list --limit 30 \
    --json name,description \
    --jq '.[] | .name + "\t" + (.description // "")' \
    | column -t -s $'\t' \
    | fzf "${FZF_THEME[@]}" \
          --border=rounded \
          --border-label='  ◈  CLONE  ' \
          --prompt='  ❯ ' \
          --preview='gh repo view $(echo {} | awk "{print \$1}") 2>/dev/null' \
          --preview-window=right:50% \
          --preview-label='  Info  ') || return

  local name dest
  name=$(echo "$selected" | awk '{print $1}')
  dest="$DEV_ROOT/$(basename $name)"

  gh repo clone "$name" "$dest" \
    && cd "$dest" && add-recent && refresh-dev-cache \
    && echo "✅ Cloned to $dest"
}

github_ui_sync_fork() {
  if ! gh repo view --json isFork --jq '.isFork' 2>/dev/null | grep -q true; then
    echo "⚠️  Not a fork"
    return 1
  fi
  gh repo sync && echo "✅ Fork synced"
}

github_ui_status() {
  echo "\033[32m=== Repo ===\033[0m" && gh repo view
  echo "\n\033[32m=== Open PRs ===\033[0m" && gh pr list --limit 5 || echo "None"
  echo "\n\033[32m=== Open Issues ===\033[0m" && gh issue list --limit 5 || echo "None"
}
