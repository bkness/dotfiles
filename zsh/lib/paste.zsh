# ---------------------------------------
# Paste wrap — long one-line pastes get readable line breaks
# ---------------------------------------
# A pasted one-liner longer than PASTE_WRAP_MIN characters is split before
# `&&`, `||`, `|` and long `--flags`, with `\` continuations:
#
#   vercel env add KEY production \
#     --value "$v" --yes --force \
#     && vercel env pull
#
# A backslash-newline outside quotes is removed before the command runs, so
# this never changes what the command does. It only breaks outside quotes,
# $( ), ( ) and backticks, and leaves alone anything it can't be sure about:
# multi-line pastes, heredocs, comments. Ctrl+_ (undo) restores the paste as
# it came in. Set PASTE_WRAP=0 to turn it off.

: ${PASTE_WRAP:=1}
: ${PASTE_WRAP_MIN:=100}

# _paste_wrap_format TEXT → prints the reformatted text (or TEXT unchanged)
_paste_wrap_format() {
  emulate -L zsh; setopt extended_glob
  local s=$1
  if [[ $s == *$'\n'* || ${#s} -lt $PASTE_WRAP_MIN || $s == *'<<'* ]]; then
    print -rn -- "$s"; return
  fi
  local out="" line="" c next i=1 n=${#s} sq=0 dq=0 bt=0 depth=0
  local brk=$' \\\n  '
  while (( i <= n )); do
    c=${s[i]} next=${s[i+1]}
    if (( sq )); then
      [[ $c == "'" ]] && sq=0
    elif [[ $c == '\' ]]; then
      line+=$c$next; (( i += 2 )); continue
    elif (( dq )); then
      [[ $c == '"' ]] && dq=0
      [[ $c == '$' && $next == '(' ]] && (( depth++ ))
      [[ $c == ')' ]] && (( depth > 0 )) && (( depth-- ))
    elif (( bt )); then
      [[ $c == '`' ]] && bt=0
    else
      case $c in
        "'") sq=1 ;;
        '"') dq=1 ;;
        '`') bt=1 ;;
        '(') (( depth++ )) ;;
        ')') (( depth > 0 )) && (( depth-- )) ;;
        '#') [[ -z $line || ${line[-1]} == ' ' ]] && { print -rn -- "$s"; return } ;;
      esac
      if (( depth == 0 && ! sq && ! dq && ! bt )) && [[ -n ${line// } ]]; then
        local two=$c$next
        if [[ $two == '&&' || $two == '||' ]]; then
          # keep the two-character operator together: never split || into | |
          out+=${line%% #}$brk; line=$two; (( i += 2 )); continue
        elif [[ $c == '|' ]]; then
          out+=${line%% #}$brk; line=""
        elif [[ $c == '-' && $next == '-' && ${s[i-1]} == ' ' && ${#line} -gt 50 ]]; then
          out+=${line%% #}$brk; line=""
        fi
      fi
    fi
    line+=$c; (( i++ ))
  done
  # unbalanced quotes: something we don't understand, leave it alone
  if (( sq || dq || bt )); then print -rn -- "$s"; return; fi
  print -rn -- "$out$line"
}

_paste_wrap() {
  local pasted
  zle .bracketed-paste pasted
  if [[ $PASTE_WRAP == 1 ]]; then
    LBUFFER+=$pasted                    # plain paste first, so Ctrl+_ can undo the wrap
    zle split-undo
    LBUFFER=${LBUFFER%$pasted}$(_paste_wrap_format "$pasted")
  else
    LBUFFER+=$pasted
  fi
}
zle -N bracketed-paste _paste_wrap
