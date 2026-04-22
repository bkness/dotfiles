project_boot_node() {
  echo "📦 Node plugin activated"

  [[ -d node_modules ]] || npm install
  command -v code >/dev/null && code .

  npm run dev
}

register_plugin node project_boot_node 10
