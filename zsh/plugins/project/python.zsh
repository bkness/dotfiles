project_boot_python() {
  echo "🐍 Python plugin activated"

  # Guard: ensure python3 is available
  if ! command -v python3 >/dev/null; then
    echo "❌ python3 not found"
    return 1
  fi

  # Create venv if missing
  if [[ ! -d .venv ]]; then
    local reply
    read "reply?🔧 Create virtual environment? (y/n): "
    if [[ "$reply" == "y" ]]; then
      python3 -m venv .venv || { echo "❌ Failed to create venv"; return 1; }
    else
      echo "⏭ Skipping venv setup"
      return 0
    fi
  fi

  # Activate FIRST, then install
  source .venv/bin/activate || { echo "❌ Failed to activate venv"; return 1; }
  echo "✅ Virtual environment activated"

  # Install requirements if the file exists
  if [[ -f requirements.txt ]]; then
    local reply
    read "reply?📥 Install requirements? (y/n): "
    if [[ "$reply" == "y" ]]; then
      pip install -r requirements.txt || { echo "❌ pip install failed"; return 1; }
    else
      echo "⏭ Skipping pip install"
    fi
  else
    echo "⚠️  No requirements.txt found — skipping install"
  fi

  # Open editor in background
  if command -v code >/dev/null; then
    if ! nohup code . >/dev/null 2>&1 &; then
      echo "⚠️  Failed to launch VS Code"
    fi
  else
    echo "⚠️  VS Code ('code') not found — skipping editor launch"
  fi

  # Run main entry point if it exists
  if [[ -f main.py ]]; then
    python3 main.py
  else
    echo "⚠️  No main.py found — dropping into shell"
  fi
}

register_plugin python project_boot_python 10
