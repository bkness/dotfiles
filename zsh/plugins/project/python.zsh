project_boot_python() {
  echo "🐍 Python plugin activated"
  command -v code >/dev/null && code .
  [[ -d .venv ]] || python3 -m venv .venv
  source .venv/bin/activate
  pip install -r requirements.txt
}

register_plugin python project_boot_python 10
