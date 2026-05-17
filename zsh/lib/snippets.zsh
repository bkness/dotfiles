# ---------------------------------------
# Ctrl+S — Snippet Expander
# Pick a multi-line template and insert at cursor
# Add new snippets as files in zsh/snippets/
# ---------------------------------------

_snippet_widget() {
  zle -I
  local snippets_dir="$HOME/dev/dotfiles/zsh/snippets"
  local name
  name=$(print -l "$snippets_dir"/*(N:t) | fzf "${FZF_THEME[@]}" \
    --height=50% \
    --reverse \
    --border=rounded \
    --border-label="  ◈  Snippets  " \
    --prompt="  ❯ " \
    --preview="bat --style=plain --color=always --language=bash $snippets_dir/{} 2>/dev/null" \
    --preview-window=right:60%:wrap \
    --color='border:#00ff41,label:#00ff41'
  ) || { zle reset-prompt; return; }
  local content
  content=$(cat "$snippets_dir/$name")
  LBUFFER+="$content"
  zle reset-prompt
}

zle -N _snippet_widget
bindkey '^S' _snippet_widget
