# ---------------------------------------
# Ctrl+E — File Explorer
# Tab → enter folder  |  Shift+Tab → up  |  Enter → cd or insert path
# ---------------------------------------

# desc: Ctrl+E file explorer with preview
_explorer_widget() {
  zle -I
  local current="$PWD"

  while true; do
    local crumb="${current/#$HOME/~}"

    local result
    result=$(
      {
        # Parent dir entry
        [[ "$current" != "/" ]] && printf "%s\t 󰁞  ..\n" "$(dirname "$current")"

        # eza for display — icons + color. Strip ANSI to get plain name for path.
        eza -1 --icons --color=always --group-directories-first "$current" 2>/dev/null \
          | while IFS= read -r display; do
              local plain
              plain=$(printf '%s' "$display" | sed $'s/\x1b\\[[0-9;]*[mK]//g' | sed 's/^[[:space:]]*//' | xargs)
              [[ -z "$plain" ]] && continue
              printf "%s/%s\t%s\n" "$current" "$plain" "$display"
            done
      } | fzf "${FZF_THEME[@]}" \
          --border=rounded \
          --border-label="  ◈  $crumb  " \
          --border-label-pos=2 \
          --prompt='  ❯ ' \
          --header=$'  \e[38;2;0;173;216mTab\e[0m enter   \e[38;2;0;173;216m↑Tab\e[0m back   \e[38;2;0;173;216mEnter\e[0m cd' \
          --header-first \
          --ansi \
          --delimiter=$'\t' \
          --with-nth=2 \
          --expect='tab,btab' \
          --color='border:#00ff41,label:#00ff41,header:italic' \
          --preview='
            p={1}
            if [[ -d "$p" ]]; then
              eza -la --icons --color=always -1 "$p" 2>/dev/null || ls -la "$p"
            elif [[ -f "$p" ]]; then
              bat --style=plain --color=always --paging=never "$p" 2>/dev/null || cat "$p"
            fi
          ' \
          --preview-window=right:50%:wrap \
          --preview-label='  ◈  Preview  '
    )

    [[ $? -ne 0 ]] && { zle reset-prompt; return; }

    local key item full_path
    key=$(head -1 <<< "$result")
    item=$(awk 'NR==2' <<< "$result")
    [[ -z "$item" ]] && { zle reset-prompt; return; }

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
bindkey '^Q' _explorer_widget
