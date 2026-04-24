# ---------------------------------------
# Rust Boot Plugin
# ---------------------------------------
project_boot_rust() {
  echo "🦀 Rust plugin activated"

  if [[ ! -f Cargo.toml ]]; then
    echo "❌ No Cargo.toml found in $(pwd)"
    return 1
  fi

  command -v code >/dev/null && nohup code . >/dev/null 2>&1 &

  if command -v cargo-watch >/dev/null; then
    echo "👀 Starting cargo-watch..."
    cargo watch -x run
  else
    echo "💡 Tip: cargo install cargo-watch for hot-reloading"
    cargo run
  fi
}

register_plugin rust project_boot_rust 10

# Regenerate _rustup completions only when rustup has been updated
_rust_sync_completions() {
  local comp="$HOME/.zfunc/_rustup"
  local rustup_bin="${CARGO_HOME:-$HOME/.cargo}/bin/rustup"

  [[ ! -f "$rustup_bin" ]] && return
  [[ -f "$comp" && "$comp" -nt "$rustup_bin" ]] && return

  echo "🔧 Updating rustup completions..."
  rustup completions zsh > "$comp" && echo "✅ Done"
}
register_hook "on_enter/rust" "_rust_sync_completions"
