project_detect() {
    local type="unknown"
   
    [[ -f package.json ]] && echo "node" && return
    [[ -f requirements.txt ]] && echo "python" && return
    [[ -f Cargo.toml ]] && echo "rust" && return
   
    echo "unknown"
}

# Detect broken or malformed heredocs in shell scripts
heredoc_lint() {
  local file="$1"

  if [[ ! -f "$file" ]]; then
    echo "❌ File not found: $file"
    return 1
  fi

  echo "🔍 Checking heredocs in: $file"

  # 1. Find all heredoc starts
  local starts
  starts=$(grep -nE '<<[-]?([A-Za-z_][A-Za-z0-9_]*)' "$file" | sed -E 's/.*<<(.*)/\1/')

  if [[ -z "$starts" ]]; then
    echo "✔ No heredocs found"
    return 0
  fi

  echo "$starts" | while IFS=: read -r line tag; do
    local delimiter="${tag##*<<}"
    delimiter="${delimiter// /}"   # strip spaces

    # 2. Check if closing delimiter exists exactly
    if ! grep -qx "$delimiter" "$file"; then
      echo "❌ Missing or malformed EOF at line $line (expected: $delimiter)"
    fi
  done

  echo "✔ Done"
}
