# ---------------------------------------
# Ctrl+E — File Explorer
# Tab → enter folder  |  Shift+Tab → up  |  Enter → cd or insert path
# ---------------------------------------

_explorer_widget() {
  local current="$PWD"

  while true; do
    local crumb="${current/#$HOME/~}"

    local result
    result=$(
      {
        [[ "$current" != "/" ]] && printf "%s\t📁  ..\n" "$(dirname "$current")"
        command ls -1p "$current" 2>/dev/null | grep '/$' | sed 's|/$||' | while IFS= read -r d; do
          printf "%s/%s\t📁  %s\n" "$current" "$d" "$d"
        done
        command ls -1p "$current" 2>/dev/null | grep -v '/$' | while IFS= read -r f; do
          printf "%s/%s\t    %s\n" "$current" "$f" "$f"
        done
      } | fzf "${FZF_THEME[@]}" \
          --border=rounded \
          --border-label="  ◈  $crumb  " \
          --prompt='  ❯ ' \
          --header='  Tab → enter   Shift+Tab → up   Enter → open   Ctrl+P → palette' \
          --header-first \
          --delimiter=$'\t' \
          --with-nth=2 \
          --expect='tab,btab' \
          --preview='
            p={1}
            if [[ -d "$p" ]]; then
              eza -la --icons -1 "$p" 2>/dev/null || ls -la "$p"
            elif [[ -f "$p" ]]; then
              bat --style=plain --color=always --paging=never "$p" 2>/dev/null || cat "$p"
            fi
          ' \
          --preview-window=right:50%:wrap \
          --preview-label='  Preview  '
    )

    [[ $? -ne 0 ]] && return

    local key item full_path
    key=$(head -1 <<< "$result")
    item=$(awk 'NR==2' <<< "$result")
    [[ -z "$item" ]] && return

    full_path=$(cut -f1 <<< "$item")

    case "$key" in
      tab)
        [[ -d "$full_path" ]] && current="$full_path"
        ;;
      btab)
        current=$(dirname "$current")
        ;;
      *)
        if [[ -d "$full_path" ]]; then
          BUFFER="cd $(printf %q "$full_path")"
          CURSOR=${#BUFFER}
          zle accept-line
        else
          LBUFFER+="$full_path"
          zle redisplay
        fi
        return
        ;;
    esac
  done
}

zle -N _explorer_widget
bindkey '^E' _explorer_widget
