project_boot_go() {
  if [[ ! -f go.mod ]]; then
    echo "⚠️  No go.mod found"
    return 1
  fi

  local module
  module=$(grep '^module' go.mod | awk '{print $2}')
  echo "🐹 Go module: $module"

  if [[ -f Makefile ]]; then
    echo "📋 Makefile targets:"
    grep -E '^[a-zA-Z][a-zA-Z0-9_-]*:([^=]|$)' Makefile | head -5 | awk -F: '{print "   make " $1}'
  fi

  local reply
  read "reply?🔧 Run go mod tidy? (y/n): "
  [[ "$reply" == "y" ]] && go mod tidy
}

register_plugin go project_boot_go 10
