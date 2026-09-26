# ---------------------------------------
# Ctrl+F — Fuzzy Code Finder (ripgrep + fzf + bat)
#
# If PWD is inside a dev project → search from that project root.
# Otherwise → show project picker (recent first), then search inside pick.
# Picking ".claude" searches every Claude settings file (global + per-project).
#
# Enter → open in $EDITOR at line
# Ctrl+O → insert file:line into shell buffer instead of opening
# Ctrl+U → toggle preview pane
# ---------------------------------------

# Walk up from PWD to find a dev project root.
# Returns the project root, or empty if not inside one.
_finder_project_root() {
  local dir="$PWD"
  local dev_root="${DEV_ROOT:-$HOME/dev/projects}"
  while [[ "$dir" != "/" && "$dir" != "$HOME" ]]; do
    if [[ "$(dirname "$dir")" == "$dev_root" ]]; then
      echo "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  # Special case: dotfiles subtree
  case "$PWD" in
    "$HOME/dev/dotfiles"|"$HOME/dev/dotfiles"/*) echo "$HOME/dev/dotfiles"; return 0 ;;
  esac
  return 1
}

# Interactive picker for a dev project — recent projects sorted first.
_finder_pick_project() {
  local dev_root="${DEV_ROOT:-$HOME/dev/projects}"
  local extras=("$HOME/dev/dotfiles" "$HOME/.claude")
  local -A seen
  local list=()

  # Recent entries filtered to project roots
  if [[ -f "$HOME/.dev-recent" ]]; then
    while IFS= read -r line; do
      local parent="$(dirname "$line")"
      local is_extra=0
      for e in "${extras[@]}"; do
        [[ "$line" == "$e" ]] && { is_extra=1; break; }
      done
      if [[ "$parent" == "$dev_root" || "$is_extra" -eq 1 ]]; then
        [[ -z "${seen[$line]}" && -d "$line" ]] && { list+=("$line"); seen[$line]=1; }
      fi
    done < "$HOME/.dev-recent"
  fi

  # Fill remaining projects alphabetically
  for d in "$dev_root"/*/ "${extras[@]}"; do
    d="${d%/}"
    [[ -d "$d" && -z "${seen[$d]}" ]] && { list+=("$d"); seen[$d]=1; }
  done

  printf '%s\n' "${list[@]}" | fzf "${FZF_THEME[@]}" \
    --border=rounded \
    --border-label="  ◈  Pick a project  " \
    --border-label-pos=2 \
    --prompt='  📁  ' \
    --header='  Recent projects up top — Enter to grep inside' \
    --header-first \
    --with-nth=-1 \
    --delimiter=/ \
    --color='border:#00ff41,label:#00ff41,header:italic' \
    --preview='eza -la --icons --color=always -1 {} 2>/dev/null || ls -la {}' \
    --preview-window='right:40%:wrap' \
    --preview-label='  ◈  Contents  '
}

# desc: Ctrl+F fuzzy code search (smart-scoped to project)
_finder_widget() {
  zle -I

  # ─── Step 1: Determine search root ───
  local root
  root=$(_finder_project_root)
  if [[ -z "$root" ]]; then
    root=$(_finder_pick_project) || { zle reset-prompt; return; }
  fi
  [[ -z "$root" ]] && { zle reset-prompt; return; }

  # ─── Step 2: Fuzzy grep within root ───
  # ripgrep flags:
  #   --column --line-number → parseable path:line:col:text output
  #   --no-heading           → one line per match, no file grouping
  #   --color=always         → colored matches even inside fzf pipe
  #   --smart-case           → case-insensitive unless query has uppercase
  #   --hidden --glob=!.git  → include dotfiles but skip .git noise
  #   --max-count=100        → per-file cap so one big file can't drown results
  local RG="rg --column --line-number --no-heading --color=always --smart-case --hidden --glob=!.git --max-count=100"
  local PREVIEW='bat --color=always --style=numbers --paging=never --highlight-line {2} --line-range=$(({2}<15?1:{2}-15)): {1}'
  local project_name="${root:t}"
  local result

  # Claude settings mode: search only settings*.json files, from $HOME so the
  # relative paths rg prints still resolve. --no-ignore because .claude/ is
  # usually gitignored and rg would skip it.
  local targets=""
  if [[ "$root" == "$HOME/.claude" ]]; then
    local -a files=(
      "$HOME"/.claude/settings*.json(N)
      "$HOME"/dev/*/.claude/settings*.json(N)
      "$HOME"/dev/*/*/.claude/settings*.json(N)
    )
    files=("${files[@]#$HOME/}")
    targets=" ${(j: :)${(q)files[@]}}"
    RG+=" --no-ignore"
    root="$HOME"
    project_name="claude settings"
  fi

  result=$(
    cd "$root" && : | fzf "${FZF_THEME[@]}" \
      --ansi \
      --disabled \
      --border=rounded \
      --border-label="  ◈  Find in $project_name  " \
      --border-label-pos=2 \
      --prompt='  🔍  ' \
      --header=$'  \e[38;2;0;173;216mType\e[0m search   \e[38;2;0;173;216mEnter\e[0m open   \e[38;2;0;173;216m^O\e[0m insert   \e[38;2;0;173;216m^U\e[0m toggle preview' \
      --header-first \
      --delimiter=: \
      --query='' \
      --bind "change:reload:sleep 0.1; $RG -- {q}$targets || true" \
      --bind "ctrl-u:toggle-preview" \
      --color='border:#00ff41,label:#00ff41,header:italic' \
      --preview="$PREVIEW" \
      --preview-window='right:60%:wrap:+{2}+3/3' \
      --preview-label='  ◈  Preview  ' \
      --expect='enter,ctrl-o'
  )

  [[ -z "$result" ]] && { zle reset-prompt; return; }

  local key match file line
  key=$(head -1 <<< "$result")
  match=$(awk 'NR==2' <<< "$result")
  [[ -z "$match" ]] && { zle reset-prompt; return; }

  # rg output is relative to $root (we cd'd), make it absolute
  file="$root/$(cut -d: -f1 <<< "$match")"
  line=$(cut -d: -f2 <<< "$match")

  case "$key" in
    ctrl-o)
      LBUFFER+="$file:$line"
      zle redisplay
      ;;
    *)
      BUFFER="${EDITOR:-nvim} +$line $(printf %q "$file")"
      CURSOR=${#BUFFER}
      zle accept-line
      ;;
  esac
}

zle -N _finder_widget
bindkey '^F' _finder_widget
