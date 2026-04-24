project_boot_node() {
  echo "📦 Node plugin activated"

  if [[ ! -f package.json ]]; then
    echo "❌ No package.json found in $(pwd)"
    return 1
  fi

  # Install deps if node_modules is missing OR package.json is newer
  if [[ ! -d node_modules ]] || [[ package.json -nt node_modules ]]; then
    local reply
    read "reply?📥 Install npm dependencies? (y/n): "
    [[ "$reply" != "y" ]] && echo "⏭ Skipping install" && return 0
    npm install || { echo "❌ npm install failed"; return 1; }
  fi

  # Open editor in background, then start dev server
  command -v code >/dev/null && nohup code . >/dev/null 2>&1 &

  # Use the dev script if it exists, otherwise fall back gracefully
  if node -e "const p=require('./package.json'); process.exit(p.scripts?.dev ? 0 : 1)" 2>/dev/null; then
    npm run dev
  else
    echo "⚠️  No 'dev' script in package.json — dropping into shell"
  fi
}

register_plugin node project_boot_node 10