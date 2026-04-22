# Zsh Custom Commands, Aliases, and Shortcuts

| Command / Shortcut | Description |
|--------------------|-------------|
| `dev`              | Open and boot a project (auto-detects type) |
| `newproj`          | Create a new project with template and git init |
| `cb`               | Create/switch to a new git branch |
| `cm`               | Switch to main or master branch |
| `gb`               | Fuzzy switch between git branches |
| `j`                | Jump to directory using zoxide |
| `p`                | Fuzzy open a project directory |
| `pr`               | Fuzzy open project and launch VS Code |
| `dashboard`        | Open the project dashboard |
| `g`                | (alias) Open VS Code, install npm deps, run dev |
| `c`                | (alias) Clear terminal |
| `..`               | (alias) cd .. |
| `ll`               | (alias) eza -la --icons |
| `ls`               | (alias) eza --icons |
| `cat`              | (alias) bat |
| `safe`             | (alias) Start zsh with no config |
| Ctrl+R             | Fuzzy search shell history |
| Ctrl+G             | Open project dashboard |

## Example Prompts

- `dev myproject` — Open and boot the "myproject" directory
- `newproj myproject` — Create a new project named "myproject"
- `cb feature-x` — Create/switch to branch "feature-x"
- `j` — Fuzzy jump to a directory
- `pr` — Fuzzy open a project and launch VS Code

Add more as you create new commands!
