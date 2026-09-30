# ---------------------------------------
# secret — keep secrets in the macOS Keychain, never in history
# ---------------------------------------
# secret set NAME     save the clipboard as NAME, then clear the clipboard
# secret get NAME     print NAME, for use inside a command: $(secret get NAME)
# secret copy NAME    put NAME on the clipboard
# secret ls           list stored names (never values)
# secret rm NAME      delete NAME
# vsecret NAME        push NAME from the Keychain to this folder's Vercel
#                     project (production), then read it back to prove it saved
#
# Items live in your login Keychain under service "forged", account NAME.
# Values only ever travel through the clipboard or a pipe, so nothing secret
# is typed, shown, or saved to shell history.

_SECRET_SVC=forged

# desc: Keychain secrets: secret set|get|copy|ls|rm NAME
secret() {
  [[ $OSTYPE == darwin* ]] || { echo "  secret: needs the macOS Keychain"; return 1; }
  local cmd=$1 name=$2 val
  case $cmd in
    set)
      [[ -n $name ]] || { echo "  usage: secret set NAME   (copy the value first)"; return 1; }
      val=$(pbpaste | tr -d '\r\n')
      (( ${#val} >= 8 )) || { echo "  ✗ clipboard is empty or too short. Copy the secret first."; return 1; }
      security add-generic-password -U -s $_SECRET_SVC -a "$name" -w "$val" \
        || { echo "  ✗ Keychain didn't save it"; return 1; }
      print -n "" | pbcopy
      echo "  🔐 $name saved to Keychain (…${val[-4,-1]}); clipboard cleared"
      ;;
    get)
      security find-generic-password -s $_SECRET_SVC -a "$name" -w 2>/dev/null \
        || { echo "  ✗ no secret named $name" >&2; return 1; }
      ;;
    copy)
      val=$(secret get "$name") || return 1
      print -rn -- "$val" | pbcopy
      echo "  📋 $name copied (…${val[-4,-1]})"
      ;;
    ls)
      security dump-keychain 2>/dev/null | awk -v svc="\"$_SECRET_SVC\"" '
        /^keychain:/ { acct=""; mine=0 }
        /"acct"<blob>=/ { sub(/.*"acct"<blob>=/, ""); acct=$0 }
        /"svce"<blob>=/ { sub(/.*"svce"<blob>=/, ""); mine=($0==svc) }
        mine && acct!="" { gsub(/"/, "", acct); print "  " acct; acct=""; mine=0 }' | sort -u
      ;;
    rm)
      security delete-generic-password -s $_SECRET_SVC -a "$name" >/dev/null 2>&1 \
        && echo "  🗑  $name removed" || { echo "  ✗ no secret named $name"; return 1; }
      ;;
    *)
      echo "  usage: secret set|get|copy|ls|rm NAME"; return 1 ;;
  esac
}

# desc: Push a Keychain secret to this folder's Vercel project (production), verified
vsecret() {
  local name=$1 val got tmp
  [[ -n $name ]] || { echo "  usage: vsecret NAME   (run inside a Vercel-linked project)"; return 1; }
  [[ -f .vercel/project.json ]] || { echo "  ✗ this folder isn't linked to Vercel (run: vercel link)"; return 1; }
  val=$(secret get "$name") || return 1
  # The value goes in as an argument inside this function, never on a typed
  # command line. --no-sensitive lets us read it back: the CLI can silently save ""
  vercel env add "$name" production --value "$val" --yes --no-sensitive --force >/dev/null 2>&1
  tmp=$(mktemp)
  vercel env pull --environment=production --yes "$tmp" >/dev/null 2>&1
  got=$(grep "^$name=" "$tmp" | cut -d= -f2- | tr -d '"')
  rm -f "$tmp"
  if [[ "$got" == "$val" ]]; then
    echo "  ✓ $name set on Vercel and verified (…${val[-4,-1]}). Redeploy to use it."
  else
    echo "  ✗ $name did NOT save on Vercel (it has ${#got} characters). Set it in the dashboard."
    return 1
  fi
}
