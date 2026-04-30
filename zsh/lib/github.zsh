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

# Ensure standard labels exist on the repo — runs once then exits fast
_gh_ensure_labels() {
  local existing
  existing=$(gh label list --json name --jq '.[].name' 2>/dev/null)
  local -A labels=(
    [cleanup]="0075ca"
    [bug]="d73a4a"
    [feature]="a2eeef"
    [security]="e4e669"
    [backend]="0052cc"
    [frontend]="bfd4f2"
    [auth]="f9d0c4"
    [priority:high]="b60205"
    [priority:medium]="fbca04"
    [priority:low]="0e8a16"
  )
  for name color in "${(@kv)labels}"; do
    echo "$existing" | grep -qx "$name" || \
      gh label create "$name" --color "$color" --force >/dev/null 2>&1
  done
}

# ---------------------------------------
# GitHub Projects v2 — board integration
# ---------------------------------------

_FORGED_PROJECTS_CACHE="${XDG_CONFIG_HOME:-$HOME/.config}/forged/projects"

# Ensure the project scope is available — prompt once if not
_gh_ensure_project_scope() {
  gh api graphql -f query='{ viewer { projectsV2(first:1) { nodes { id } } } }' \
    --silent >/dev/null 2>&1
}

# Returns project node ID for current repo, auto-creating if needed
# Caches result in ~/.config/forged/projects as "owner/repo=PROJECT_ID"
_gh_get_or_create_project() {
  local repo
  repo=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null) || return 1
  local repo_name="${repo#*/}"

  mkdir -p "${_FORGED_PROJECTS_CACHE%/*}"
  touch "$_FORGED_PROJECTS_CACHE"

  # Return cached ID if present
  local cached
  cached=$(grep "^${repo}=" "$_FORGED_PROJECTS_CACHE" 2>/dev/null | cut -d= -f2)
  [[ -n "$cached" ]] && echo "$cached" && return 0

  _gh_ensure_project_scope || return 1

  local owner="${repo%/*}"

  # Check if a project already exists for this repo
  local existing_id
  existing_id=$(gh api graphql -f query="
    query {
      repositoryOwner(login: \"$owner\") {
        ... on User {
          projectsV2(first: 20) {
            nodes { id title }
          }
        }
        ... on Organization {
          projectsV2(first: 20) {
            nodes { id title }
          }
        }
      }
    }" --jq ".data.repositoryOwner.projectsV2.nodes[] | select(.title == \"$repo_name\") | .id" 2>/dev/null | head -1)

  if [[ -n "$existing_id" ]]; then
    echo "${repo}=${existing_id}" >> "$_FORGED_PROJECTS_CACHE"
    echo "$existing_id"
    return 0
  fi

  # Auto-create project named after the repo
  local owner_id
  owner_id=$(gh api graphql -f query="
    query { repositoryOwner(login: \"$owner\") { id } }" \
    --jq '.data.repositoryOwner.id' 2>/dev/null)
  [[ -z "$owner_id" ]] && return 1

  local new_id
  new_id=$(gh api graphql -f query="
    mutation {
      createProjectV2(input: { ownerId: \"$owner_id\", title: \"$repo_name\" }) {
        projectV2 { id }
      }
    }" --jq '.data.createProjectV2.projectV2.id' 2>/dev/null)
  [[ -z "$new_id" ]] && return 1

  echo "${repo}=${new_id}" >> "$_FORGED_PROJECTS_CACHE"
  echo "  ✅ Created project board \"$repo_name\"" >&2
  echo "$new_id"
}

# Add an issue to the project board and set its status field
# Usage: _gh_project_set_status <issue_number> <board_status>
# Status values: "Todo" | "In Progress" | "In Review" | "Done"
_gh_project_set_status() {
  local issue_number="$1"
  local board_status="$2"

  local project_id
  project_id=$(_gh_get_or_create_project 2>/dev/tty) || return 0  # silent fail — don't block workflow

  local repo
  repo=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null) || return 0

  # Get issue node ID
  local issue_node_id
  issue_node_id=$(gh api "repos/${repo}/issues/${issue_number}" --jq '.node_id' 2>/dev/null) || return 0

  # Add item to project (idempotent)
  local item_id
  item_id=$(gh api graphql -f query="
    mutation {
      addProjectV2ItemById(input: { projectId: \"$project_id\", contentId: \"$issue_node_id\" }) {
        item { id }
      }
    }" --jq '.data.addProjectV2ItemById.item.id' 2>/dev/null) || return 0

  # Find the Status field ID
  local field_id option_id
  local fields_json
  fields_json=$(gh api graphql -f query="
    query {
      node(id: \"$project_id\") {
        ... on ProjectV2 {
          fields(first: 20) {
            nodes {
              ... on ProjectV2SingleSelectField {
                id name options { id name }
              }
            }
          }
        }
      }
    }" 2>/dev/null)

  field_id=$(echo "$fields_json" | python3 -c "
import json,sys
data=json.load(sys.stdin)
for f in data['data']['node']['fields']['nodes']:
    if f.get('name') == 'Status':
        print(f['id']); break
" 2>/dev/null)

  option_id=$(echo "$fields_json" | python3 -c "
import json,sys
data=json.load(sys.stdin)
board_status='$board_status'
for f in data['data']['node']['fields']['nodes']:
    if f.get('name') == 'Status':
        for o in f.get('options',[]):
            if o['name'] == board_status:
                print(o['id']); break
" 2>/dev/null)

  [[ -z "$field_id" || -z "$option_id" ]] && return 0

  # Set the status
  gh api graphql -f query="
    mutation {
      updateProjectV2ItemFieldValue(input: {
        projectId: \"$project_id\"
        itemId: \"$item_id\"
        fieldId: \"$field_id\"
        value: { singleSelectOptionId: \"$option_id\" }
      }) { projectV2Item { id } }
    }" --silent >/dev/null 2>&1
}

# ---------------------------------------
# Main menu
# ---------------------------------------

# desc: Open GitHub dashboard with Ctrl+G
github_ui() {
  _gh_check || return

  local git_options=()
  local gh_options=()

  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git_options=(
      "  🌿  Branches"
      "  📦  Stage & Commit"
      "  📋  Log"
    )
  fi

  if _in_github_repo; then
    gh_options=(
      "  🔗  Open in Browser"
      "  🔀  Pull Requests"
      "  🐛  Issues"
      "  📬  Open PR"
      "  💬  Messages"
      "  📊  Repo Status"
      "  🔄  Sync Fork"
    )
  fi

  local header="  $(_gh_repo_label)"
  local choice
  choice=$(printf '%s\n' \
    "${git_options[@]}" \
    "${gh_options[@]}" \
    "  🗂   My Repos" \
    "  📥  Clone Repo" \
    "  🆕  Create Repo" \
    | fzf "${FZF_THEME[@]}" \
        --border=rounded \
        --border-label='  ◈  GITHUB  ' \
        --header="$header" \
        --header-first \
        --prompt='  ❯ ') || return

  case "${choice##  }" in
    "🌿  Branches")        github_ui_branches ;;
    "📦  Stage & Commit")  github_ui_staging ;;
    "📋  Log")             github_ui_log ;;
    "🔗  Open in Browser") gh repo view --web ;;
    "🔀  Pull Requests")   github_ui_prs ;;
    "🐛  Issues")          github_ui_issues ;;
    "📬  Open PR")         github_ui_open_pr ;;
    "💬  Messages")        github_ui_messages ;;
    "📊  Repo Status")     github_ui_status ;;
    "🔄  Sync Fork")       github_ui_sync_fork ;;
    "🗂   My Repos")        github_ui_repos ;;
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

  case "${action##  }" in
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

  case "${action##  }" in
    "🌿  Checkout")        gh pr checkout "$number" ;;
    "🔗  Open in browser") gh pr view "$number" --web ;;
    "👁   View")           gh pr view "$number" ;;
    "✅  Merge")           gh pr merge "$number" ;;
    "❌  Close")           gh pr close "$number" ;;
  esac
}

github_ui_issues() {
  local header_action
  header_action=$(printf '%s\n' \
    "  📋  List Issues" \
    "  🆕  Create Issue" \
    | fzf "${FZF_THEME[@]}" \
        --border=rounded \
        --border-label='  ◈  ISSUES  ' \
        --prompt='  ❯ ' \
        --height=25%) || return

  [[ "${header_action##  }" == "🆕  Create Issue" ]] && { _github_create_issue; return; }

  local selected
  selected=$(gh issue list --limit 30 \
    --json number,title,assignees,labels \
    --jq '.[] | "#" + (.number | tostring) + "  " + .title + "\t" + (if (.assignees | length) > 0 then .assignees[0].login else "unassigned" end) + "  " + (.labels | map(.name) | join(", "))' \
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
    "  🌿  Start Branch" \
    "  🔀  Open PR" \
    "  🏷   Label" \
    "  ✅  Close" \
    "  💬  Comment" \
    | fzf "${FZF_THEME[@]}" \
        --border=rounded \
        --border-label='  ◈  ACTION  ' \
        --prompt='  ❯ ' \
        --height=40%) || return

  case "${action##  }" in
    "🔗  Open in browser") gh issue view "$number" --web ;;
    "👁   View")           gh issue view "$number" ;;
    "🌿  Start Branch")
      local branch_type
      branch_type=$(printf '%s\n' "  fix" "  feature" "  chore" \
        | fzf "${FZF_THEME[@]}" \
            --border=rounded \
            --border-label='  ◈  BRANCH TYPE  ' \
            --prompt='  ❯ ' \
            --height=25%) || return
      branch_type="${branch_type##  }"
      local issue_title
      issue_title=$(gh issue view "$number" --json title --jq '.title' 2>/dev/null)
      local slug
      slug=$(echo "$issue_title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g; s/--*/-/g; s/^-//; s/-$//' | cut -c1-40)
      local branch="${branch_type}/${number}-${slug}"
      git switch -c "$branch" && echo "  ✅ Switched to $branch"
      _gh_project_set_status "$number" "In Progress" &!
      ;;
    "🔀  Open PR")         github_ui_open_pr ;;
    "🏷   Label")
      local label
      label=$(gh label list --json name --jq '.[].name' 2>/dev/null \
        | fzf "${FZF_THEME[@]}" \
            --border=rounded \
            --border-label='  ◈  LABEL  ' \
            --prompt='  ❯ ' \
            --height=40%) || return
      gh issue edit "$number" --add-label "$label" && echo "  ✅ Labeled #$number → $label"
      ;;
    "✅  Close")           gh issue close "$number" && echo "  ✅ Closed #$number" ;;
    "💬  Comment")
      local body
      read "body?Comment: "
      [[ -n "$body" ]] && gh issue comment "$number" --body "$body"
      ;;
  esac
}

github_ui_issues_create() { _github_create_issue }

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
  vis="${vis##  }"

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

# ── branches ─────────────────────────────────────────────────
github_ui_branches() {
  local action
  action=$(printf '%s\n' \
    "  🔀  Switch" \
    "  🌱  Create" \
    "  🗑   Delete" \
    | fzf "${FZF_THEME[@]}" \
        --border=rounded \
        --border-label='  ◈  BRANCHES  ' \
        --prompt='  ❯ ' \
        --height=30%) || return

  case "${action##  }" in
    "🔀  Switch")
      local branch
      branch=$(git branch --all --no-color \
        | grep -v 'HEAD' \
        | sed 's|remotes/origin/||; s|^[* ]*||' \
        | sort -u \
        | fzf "${FZF_THEME[@]}" \
            --ansi \
            --border=rounded \
            --border-label='  ◈  SWITCH  ' \
            --prompt='  ❯ ' \
            --preview='git log --oneline --graph --color=always {-1} 2>/dev/null | head -20' \
            --preview-window=right:55% \
            --preview-label='  Log  ') || return
      git switch "$branch" 2>/dev/null || git checkout "$branch"
      ;;
    "🌱  Create")
      local name
      echo -n "  Branch name: " >/dev/tty
      read -r name </dev/tty || return
      [[ -n "$name" ]] && git switch -c "$name" && echo "  ✅ Created and switched to $name"
      ;;
    "🗑   Delete")
      local branch
      branch=$(git branch --color=always \
        | grep -v '^\*' \
        | fzf "${FZF_THEME[@]}" \
            --ansi \
            --border=rounded \
            --border-label='  ◈  DELETE  ' \
            --prompt='  ❯ ' \
            --preview='git log --oneline --color=always {-1} | head -10' \
            --preview-window=right:55%) || return
      local clean="${branch//\* /}"
      echo -n "  Delete '$clean'? (y/n): " >/dev/tty
      read -r confirm </dev/tty || return
      [[ "$confirm" == "y" ]] && git branch -d "$clean" && echo "  ✅ Deleted $clean"
      ;;
  esac
}

# ── stage & commit ───────────────────────────────────────────
github_ui_staging() {
  local unstaged
  unstaged=$(git status --short 2>/dev/null)
  if [[ -z "$unstaged" ]]; then
    echo "  ✅ Nothing to stage — working tree clean"
    return
  fi

  local selected
  selected=$(echo "$unstaged" \
    | fzf "${FZF_THEME[@]}" \
        --border=rounded \
        --border-label='  ◈  STAGE  ' \
        --prompt='  ❯ ' \
        --multi \
        --bind='ctrl-a:select-all' \
        --header='<enter> stage  <ctrl-a> select all  <esc> cancel' \
        --preview='git diff --color=always -- $(echo {} | awk "{print \$NF}") 2>/dev/null ||
                   git diff --staged --color=always -- $(echo {} | awk "{print \$NF}")' \
        --preview-window=right:60% \
        --preview-label='  Diff  ') || return

  echo "$selected" | awk '{print $NF}' | while read -r file; do
    git add "$file" && echo "  ● Staged: $file"
  done

  echo -n "\n  Commit message (blank to skip): " >/dev/tty
  read -r msg </dev/tty || return
  [[ -n "$msg" ]] && git commit -m "$msg" && echo "  ✅ Committed: $msg"
}

# ── log ──────────────────────────────────────────────────────
github_ui_log() {
  local selected hash
  selected=$(git log --oneline --graph --color=always \
    | fzf "${FZF_THEME[@]}" \
        --ansi \
        --no-sort \
        --border=rounded \
        --border-label='  ◈  LOG  ' \
        --prompt='  ❯ ' \
        --preview='git show --color=always $(echo {} | grep -oE "[a-f0-9]{6,}" | head -1) 2>/dev/null' \
        --preview-window=right:60% \
        --preview-label='  Commit  ')
  hash=$(echo "$selected" | grep -oE '[a-f0-9]{6,}' | head -1)
  [[ -n "$hash" ]] && git show --color=always "$hash" | less -R
}

# ── messages ─────────────────────────────────────────────────
github_ui_messages() {
  _gh_check || return

  local action
  action=$(printf '%s\n' \
    "  🔔  Notifications" \
    "  💬  Discussions" \
    | fzf "${FZF_THEME[@]}" \
        --border=rounded \
        --border-label='  ◈  MESSAGES  ' \
        --prompt='  ❯ ' \
        --height=25%) || return

  case "${action## }" in
    "🔔  Notifications")
      local notifications
      notifications=$(gh api notifications \
        --jq '.[] | "\(.id)\t\(.subject.type)\t\(.repository.full_name)\t\(.subject.title)"' \
        2>/dev/null | column -t -s $'\t')
      if [[ -z "$notifications" ]]; then
        echo "  ✅ No unread notifications"
        return
      fi
      echo "$notifications" \
        | fzf "${FZF_THEME[@]}" \
            --border=rounded \
            --border-label='  ◈  NOTIFICATIONS  ' \
            --prompt='  ❯ ' \
            --preview='echo {}' \
            --preview-window=down:3:wrap
      ;;
    "💬  Discussions")
      local repo
      repo=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)
      if [[ -z "$repo" ]]; then
        echo "  ⚠️  No GitHub repo detected" >&2
        return 1
      fi
      local owner="${repo%/*}" rname="${repo#*/}"
      gh api graphql -f query="
        query {
          repository(owner: \"$owner\", name: \"$rname\") {
            discussions(first: 30, orderBy: {field: UPDATED_AT, direction: DESC}) {
              nodes { number title author { login } }
            }
          }
        }" \
        --jq '.data.repository.discussions.nodes[] | "#\(.number)  \(.author.login)  \(.title)"' \
        | fzf "${FZF_THEME[@]}" \
            --border=rounded \
            --border-label='  ◈  DISCUSSIONS  ' \
            --prompt='  ❯ ' \
            --preview-window=right:55%:wrap \
            --bind='enter:execute(gh browse {1} 2>/dev/null)'
      ;;
  esac
}

# ── issue creation with labels + optional branch ─────────────
_github_create_issue() {
  echo -n "  Title: " >/dev/tty; read -r title </dev/tty
  [[ -z "$title" ]] && return

  echo -n "  Body (blank to skip): " >/dev/tty; read -r body </dev/tty

  _gh_ensure_labels
  local label _label_list
  _label_list=$(gh label list --json name --jq '.[].name' 2>/dev/null)
  if [[ -n "$_label_list" ]]; then
    label=$(printf '%s\n' "${(f)_label_list}" \
      | fzf "${FZF_THEME[@]}" \
          --border=rounded \
          --border-label='  ◈  LABEL  ' \
          --prompt='  ❯ ' \
          --height=40% \
          --header='Select label (esc to skip)')
  fi

  local assignee
  local _repo _collabs _collab_list
  _repo=$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null)
  _collabs=$(gh api "repos/${_repo}/collaborators" --jq '.[].login' 2>/dev/null)
  _collab_list=$(printf '%s\n' "@me" ${(f)_collabs} | grep -v '^$' | sort -u)
  assignee=$(printf '%s\n' "${(f)_collab_list}" \
    | fzf "${FZF_THEME[@]}" \
        --border=rounded \
        --border-label='  ◈  ASSIGNEE  ' \
        --prompt='  ❯ ' \
        --height=30% \
        --header='Assign to (esc to skip)')

  local args=(--title "$title" --body "${body:-""}")
  [[ -n "$label" ]] && args+=(--label "$label")
  [[ -n "$assignee" ]] && args+=(--assignee "$assignee")

  local url
  url=$(gh issue create "${args[@]}" 2>&1) || { echo "  ❌ Failed to create issue"; return 1; }
  local number
  number=$(echo "$url" | grep -oE '[0-9]+$')
  echo "  ✅ Issue #$number created"
  _gh_project_set_status "$number" "Todo" &!

  # Offer to create a branch tied to the issue
  local branch_type
  branch_type=$(printf '%s\n' "  fix" "  feature" "  chore" \
    | fzf "${FZF_THEME[@]}" \
        --border=rounded \
        --border-label='  ◈  START BRANCH  ' \
        --prompt='  ❯ ' \
        --height=25% \
        --header="Create branch for #$number? (esc to skip)") || return 0

  branch_type="${branch_type##  }"
  local slug
  slug=$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g; s/--*/-/g; s/^-//; s/-$//' | cut -c1-40)
  local branch="${branch_type}/${number}-${slug}"
  git switch -c "$branch" && echo "  ✅ Switched to $branch"
  _gh_project_set_status "$number" "In Progress" &!
}

# ── open PR with auto Closes #NNN from branch name ───────────
github_ui_open_pr() {
  local branch
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  local number
  number=$(echo "$branch" | grep -oE '[0-9]+' | head -1)

  local body=""
  [[ -n "$number" ]] && body="Closes #${number}"

  echo -n "  PR title (blank = branch name): " >/dev/tty; read -r title </dev/tty
  [[ -z "$title" ]] && title="$branch"

  echo -n "  Additional body (blank to skip): " >/dev/tty; read -r extra </dev/tty
  [[ -n "$extra" ]] && body="${body}

${extra}"

  git push origin HEAD 2>/dev/null || git push --set-upstream origin HEAD
  gh pr create --title "$title" --body "$body" \
    && echo "  ✅ PR created${number:+ — will close #$number on merge}"
  [[ -n "$number" ]] && _gh_project_set_status "$number" "In Review" &!
}

# ── keybind — Ctrl+G ─────────────────────────────────────────
_github_ui_widget() {
  zle -I
  { github_ui } always { zle reset-prompt }
}
zle -N _github_ui_widget
bindkey '^G' _github_ui_widget
