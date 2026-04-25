_python_boot_pref_file="$HOME/.config/forged/python-boot-pref"

_python_get_pref() {
  [[ -f "$_python_boot_pref_file" ]] && cat "$_python_boot_pref_file"
}

_python_save_pref() {
  mkdir -p "$(dirname "$_python_boot_pref_file")"
  echo "$1" > "$_python_boot_pref_file"
}

project_boot_python() {
  local pref
  pref=$(_python_get_pref)

  # First time ever — ask how they want it to behave
  if [[ -z "$pref" ]]; then
    echo ""
    echo "  🐍 Python project detected"
    echo ""
    echo "  How should Forged handle Python projects?"
    echo "    1.  Always auto-boot (activate venv + install)"
    echo "    2.  Always ask me first"
    echo "    3.  Skip for now"
    echo ""
    local reply
    read "reply?  Choice (1/2/3): "
    case "$reply" in
      1) pref="always"; _python_save_pref "always" ;;
      2) pref="ask";    _python_save_pref "ask" ;;
      *) echo "  ⏭  Skipping — you can change this in ~/.config/forged/python-boot-pref"; return 0 ;;
    esac
    echo "  ✅ Saved — you can change this anytime by editing ~/.config/forged/python-boot-pref"
    echo ""
  fi

  # If ask mode, prompt each time
  if [[ "$pref" == "ask" ]]; then
    local reply
    read "reply?  🐍 Boot Python env here? (y/n): "
    [[ "$reply" != "y" ]] && return 0
  fi

  if ! command -v python3 >/dev/null; then
    echo "❌ python3 not found"
    return 1
  fi

  # Create venv if missing
  if [[ ! -d .venv ]]; then
    echo "  🔧 Creating virtual environment..."
    python3 -m venv .venv || { echo "❌ Failed to create venv"; return 1; }
  fi

  source .venv/bin/activate || { echo "❌ Failed to activate venv"; return 1; }
  echo "  ✅ venv activated"

  # Install requirements if present
  if [[ -f requirements.txt ]]; then
    local reply
    read "reply?  📥 Install requirements.txt? (y/n): "
    if [[ "$reply" == "y" ]]; then
      pip install -r requirements.txt -q && echo "  ✅ Dependencies installed"
    fi
  fi
}

register_plugin python project_boot_python 10
