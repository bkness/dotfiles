--preview='
  printf "\033[32mSelected:\033[0m %s\n" {}
  printf "\033[32m──────────────────────────────\033[0m\n\n"
  eza -la --icons -1 {}
'

edit_file_in_project() {
  local project="$1"
  local file=$(eza -1a "$project" | fzf --prompt="Edit file > ")
  [[ -n "$file" ]] && vim "$project/$file"
}

God tier readme editor with fuzzy
edit_file_in_project() {
  local project="$1"

  local file=$(
    fd . "$project" \
    | fzf --prompt="Edit > " \
          --preview 'bat --style=plain --color=always {}' \
          --preview-window=right:60%
  )

  [[ -n "$file" ]] && vim "$file"
}

