project_boot_rust() {
  echo "🦀 Rust plugin activated"
  command -v code >/dev/null && code .
  if command -v cargo-watch >/dev/null; then
    cargo watch -x run
  else
    cargo run
  fi
}

register_plugin rust project_boot_rust 10
