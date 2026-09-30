# ---------------------------------------
# dash — open a service dashboard in the browser
# ---------------------------------------
# dash            fzf picker of every dashboard
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
  open "$url"
}

_dash() { _values 'dashboard' ${(k)DASH_LINKS} }
(( $+functions[compdef] )) && compdef _dash dash
