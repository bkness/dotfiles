# ---------------------------------------
# dash — open a service dashboard in the browser
# ---------------------------------------
# dash            fzf picker of every dashboard (or Ctrl+X Ctrl+D)
# dash vercel     open one directly (Tab completes the names)
# Add or override links in personal.zsh: DASH_LINKS[name]=url

typeset -gA DASH_LINKS=(
  vercel    https://vercel.com/dashboard
  resend    https://resend.com/emails
  npm       https://www.npmjs.com
  render    https://dashboard.render.com
  netlify   https://app.netlify.com
  supabase  https://supabase.com/dashboard/projects
  neon      https://console.neon.tech
  stripe    https://dashboard.stripe.com
  expo      https://expo.dev
  github    https://github.com
)

# desc: Open a service dashboard (Vercel, Resend, npm, Render…)
dash() {
  local name="$1"
  if [[ -z "$name" ]]; then
    name=$(for k in ${(ko)DASH_LINKS}; do printf '%-10s %s\n' "$k" "${DASH_LINKS[$k]}"; done \
      | fzf "${FZF_THEME[@]}" --height=50% --reverse --border=rounded \
          --border-label="  ◈  Dashboards  " --prompt="  ❯ " \
      | awk '{print $1}') || return
    [[ -n "$name" ]] || return
  fi
  local url="${DASH_LINKS[$name]}"
  [[ -n "$url" ]] || { echo "  ❌ no dashboard named '$name'. Try: ${(ko)DASH_LINKS}"; return 1; }
  _dash_open "$url"
}

# Chrome: if a tab for the same site is already open, switch to it instead of
# piling up duplicates. Otherwise (or in another browser) open it normally.
_dash_open() {
  local url=$1 host=${${1#*://}%%/*}
  if pgrep -xq "Google Chrome"; then
    osascript - "$host" >/dev/null 2>&1 <<'AS' && return
on run {theHost}
  tell application "Google Chrome"
    repeat with w in windows
      set i to 0
      repeat with t in tabs of w
        set i to i + 1
        if URL of t contains theHost then
          set active tab index of w to i
          set index of w to 1
          activate
          return
        end if
      end repeat
    end repeat
  end tell
  error "no tab open for " & theHost
end run
AS
  fi
  open "$url"
}

_dash() { _values 'dashboard' ${(k)DASH_LINKS} }
(( $+functions[compdef] )) && compdef _dash dash

# desc: Ctrl+X Ctrl+D — dashboard picker (a chord, so no single Ctrl key is used up)
_dash_widget() {
  zle -I
  dash
  zle reset-prompt
}
zle -N _dash_widget
bindkey '^X^D' _dash_widget
