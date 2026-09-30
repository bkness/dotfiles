# Git — interactive shorthands live in zsh/abbreviations (zsh-abbr)
alias gbclean='git config --global alias.cleanup '"'"'!f() { branch=$(git rev-parse --abbrev-ref HEAD) || exit 1; case "$branch" in main|master) echo "Refusing to delete $branch. Checkout a feature branch first."; exit 1 ;; esac; if git show-ref --verify --quiet refs/heads/main; then base=main; elif git show-ref --verify --quiet refs/heads/master; then base=master; else echo "Could not find local main or master branch."; exit 1; fi; git checkout "$base" && git pull origin "$base" && git branch -d "$branch" && git push origin --delete "$branch"; }; f'"'"' # desc: Clean up current branch and delete remote'

# Clean shell exit
bye() { exit }

# Shell — interactive shorthands live in zsh/abbreviations (zsh-abbr)
alias ls="eza --icons" # desc: List files (icons)
alias ll="eza -la --icons" # desc: List all files (detailed, icons)
alias l="eza --icons --group-directories-first"
alias cat="bat" # desc: View file with syntax highlight
alias mkdir="mkdir -p" # desc: Create directories (with parents)
alias grep="grep --color=auto" # desc: Colored grep output
alias ss='screencapture -i ~/Desktop/screenshot-$(date +%s).png' # desc: Interactive screenshot to Desktop

# Reload the shell config
reload() { exec zsh -l }

# Dependency scan. personal.zsh wraps this to push the result to the Forged site.
scan() { forged scan "$@" }

gfix() {
  emulate -L zsh
  setopt pipefail

  echo "== status =="
  git status

  local gitdir
  gitdir="$(git rev-parse --absolute-git-dir 2>/dev/null)" || {
    echo "Not in a git repo"
    return 1
  }

  local conflicts
  conflicts="$(git diff --name-only --diff-filter=U)"

  if [[ -n "$conflicts" ]]; then
    echo
    echo "Unresolved conflicts:"
    echo "$conflicts"
    echo
    echo "Resolve + git add files, then run gfix again."
    return 1
  fi

  if [[ -d "$gitdir/rebase-merge" || -d "$gitdir/rebase-apply" ]]; then
    echo "Rebase in progress -> continuing..."
    git rebase --continue
    return $?
  fi

  if [[ -f "$gitdir/MERGE_HEAD" ]]; then
    echo "Merge in progress -> continuing..."
    git merge --continue
    return $?
  fi

  echo "No rebase/merge in progress and no unresolved conflicts."
  return 0
}

gundo() {
  emulate -L zsh
  setopt pipefail

  local gitdir
  gitdir="$(git rev-parse --absolute-git-dir 2>/dev/null)" || {
    echo "Not in a git repo"
    return 1
  }

  if [[ -d "$gitdir/rebase-merge" || -d "$gitdir/rebase-apply" ]]; then
    echo "Rebase in progress -> aborting..."
    git rebase --abort
    return $?
  fi

  if [[ -f "$gitdir/MERGE_HEAD" ]]; then
    echo "Merge in progress -> aborting..."
    git merge --abort
    return $?
  fi

  echo "No rebase/merge in progress to abort."
  return 0
}

gsync() {
  emulate -L zsh
  setopt pipefail

  echo "== pulling =="
  git pull || return $?

  local conflicts
  conflicts="$(git diff --name-only --diff-filter=U)"

  if [[ -n "$conflicts" ]]; then
    echo
    echo "Conflicts detected:"
    echo "$conflicts"
    echo
    echo "Resolve + git add files, then run gfix."
    return 1
  fi

  echo
  echo "== status =="
  git status
}