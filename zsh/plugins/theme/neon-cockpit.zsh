# ╔══════════════════════════════════════════════════════════╗
# ║  DEVFORGE // FZF + FZF-TAB + EZA + BAT THEME            ║
# ╚══════════════════════════════════════════════════════════╝

# ─────────────────────────────────────────────────────────────
# PALETTE
# ─────────────────────────────────────────────────────────────
THEME_BG="#030a06"
THEME_GREEN="#00ff41"
THEME_GREEN2="#00cc33"
THEME_MUTED="#4a7a55"
THEME_BORDER="#1a3a22"
THEME_GO="#00ADD8"
THEME_RUST="#FF4500"
THEME_PYTHON="#FFD43B"
THEME_WHITE="#c8ffd4"
THEME_DIM="#2a4a32"

# ─────────────────────────────────────────────────────────────
# FZF
# ─────────────────────────────────────────────────────────────
export FZF_DEFAULT_OPTS="
  --color=bg+:#0d1f12,bg:#030a06,spinner:#00ff41,hl:#00ADD8
  --color=fg:#00ADD8,header:#4a7a55,info:#FFD43B,pointer:#00ff41
  --color=marker:#FF4500,fg+:#00ff41,prompt:#00ff41,hl+:#00ADD8
  --color=border:#1a3a22,label:#00ff41,query:#00ADD8
  --color=preview-bg:#000d04,preview-border:#1a3a22,preview-label:#4a7a55
  --border=rounded
  --border-label=' devforge '
  --border-label-pos=3
  --prompt='❯ '
  --pointer='▶'
  --marker='●'
  --separator='─'
  --scrollbar='│'
  --info=right
  --layout=reverse
  --height=60%
  --preview-window=right:55%:rounded:border-left
  --bind='ctrl-/:toggle-preview'
  --bind='ctrl-u:preview-half-page-up'
  --bind='ctrl-d:preview-half-page-down'
  --bind='ctrl-a:select-all'
  --bind='ctrl-y:execute-silent(echo {+} | pbcopy)'
"

export FZF_CTRL_T_OPTS="
  --preview 'bat --color=always --style=numbers,changes --line-range=:200 {}'
  --preview-window=right:60%:rounded
"

export FZF_ALT_C_OPTS="
  --preview 'eza --tree --color=always --icons --level=2 {}'
  --preview-window=right:50%:rounded
"

# Ctrl-R handled by custom widget in tools.zsh — preview kept minimal
export FZF_CTRL_R_OPTS="
  --preview-window=down:3:hidden:wrap
  --bind='?:toggle-preview'
"

# ─────────────────────────────────────────────────────────────
# FZF-TAB
# ─────────────────────────────────────────────────────────────
zstyle ':fzf-tab:*' fzf-command fzf

zstyle ':fzf-tab:*' fzf-flags \
  --color="bg+:#0d1f12,bg:#030a06,fg:#00ADD8,fg+:#00ff41" \
  --color="hl:#00ADD8,hl+:#00ADD8,pointer:#00ff41,marker:#FF4500" \
  --color="border:#1a3a22,prompt:#00ff41,info:#FFD43B" \
  --pointer='▶' \
  --marker='●' \
  --border=rounded \
  --layout=reverse \
  --height=50%

zstyle ':fzf-tab:*' prefix '▶ '
zstyle ':fzf-tab:*' show-group full
zstyle ':fzf-tab:*' switch-group ',' '.'

# Don't show zsh's built-in menu
zstyle ':completion:*' menu no

# Directory → eza tree
zstyle ':fzf-tab:complete:cd:*' fzf-preview \
  'eza --tree --color=always --icons --level=2 $realpath'

# Files → bat, fallback to eza
zstyle ':fzf-tab:complete:*:*' fzf-preview \
  '([[ -d $realpath ]] && eza --tree --color=always --icons --level=2 $realpath) \
   || bat --color=always --style=numbers --line-range=:100 $realpath 2>/dev/null \
   || echo $realpath'

# kill/ps → process info
zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-preview \
  '[[ $group == "[process ID]" ]] && ps -p $word -o pid,user,%cpu,%mem,cmd --no-headers'
zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-flags \
  --preview-window=down:3:rounded

# git previews
zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview \
  'git diff --color=always -- $word'
zstyle ':fzf-tab:complete:git-checkout:*' fzf-preview \
  'git log --oneline --graph --color=always $word 2>/dev/null || git show --color=always $word'
zstyle ':fzf-tab:complete:git-log:*' fzf-preview \
  'git log --oneline --graph --color=always'

# ─────────────────────────────────────────────────────────────
# EZA
# ─────────────────────────────────────────────────────────────
export EZA_COLORS="\
di=38;2;0;255;65:\
ex=38;2;255;69;0:\
fi=38;2;200;255;212:\
ln=38;2;0;173;216:\
pi=38;2;255;212;59:\
so=38;2;255;69;0:\
bd=38;2;74;122;85:\
cd=38;2;74;122;85:\
or=38;2;255;69;0;4:\
ur=38;2;0;255;65:\
uw=38;2;255;69;0:\
ux=38;2;255;212;59:\
ue=38;2;255;212;59:\
gr=38;2;0;173;216:\
gw=38;2;255;69;0:\
gx=38;2;255;212;59:\
tr=38;2;74;122;85:\
tw=38;2;74;122;85:\
tx=38;2;74;122;85:\
sn=38;2;0;255;65:\
sb=38;2;0;204;51:\
nb=38;2;74;122;85:\
nk=38;2;0;255;65:\
nm=38;2;0;173;216:\
ng=38;2;255;212;59:\
nt=38;2;255;69;0:\
da=38;2;74;122;85:\
"

alias ls='eza --icons --color=always --group-directories-first'
alias ll='eza -lah --icons --color=always --group-directories-first --git'
alias lt='eza --tree --icons --color=always --level=2'
alias la='eza -a --icons --color=always'

# ─────────────────────────────────────────────────────────────
# BAT
# ─────────────────────────────────────────────────────────────
export BAT_THEME="Monokai Extended Origin"
export MANPAGER="sh -c 'col -bx | bat -l man --style=plain --color=always'"
export MANROFFOPT="-c"

# ─────────────────────────────────────────────────────────────
# LS_COLORS (fallback for non-eza contexts)
# ─────────────────────────────────────────────────────────────
export LS_COLORS="\
di=38;2;0;255;65:\
ln=38;2;0;173;216:\
ex=38;2;255;69;0:\
fi=38;2;200;255;212:\
pi=38;2;255;212;59:\
so=38;2;255;69;0:\
bd=38;2;74;122;85:\
cd=38;2;74;122;85:\
or=38;2;255;69;0;4:\
*.toml=38;2;0;173;216:\
*.json=38;2;0;173;216:\
*.yaml=38;2;0;173;216:\
*.yml=38;2;0;173;216:\
*.md=38;2;255;212;59:\
*.rs=38;2;255;69;0:\
*.go=38;2;0;173;216:\
*.py=38;2;255;212;59:\
*.js=38;2;0;255;65:\
*.ts=38;2;0;255;65:\
*.sh=38;2;0;255;65:\
*.zsh=38;2;0;255;65:\
*.log=38;2;74;122;85:\
*.lock=38;2;42;74;50:\
"
