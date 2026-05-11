# Forged Shell — Cheat Sheet

## Keybinds
| Key | Action |
|-----|--------|
| `Ctrl+P` | Command palette — search everything |
| `Ctrl+G` | GitHub dashboard |
| `Ctrl+E` | File explorer (Tab → enter, Shift+Tab → back) |
| `Ctrl+R` | Fuzzy history search |

## Project Workflow
| Command | Description |
|---------|-------------|
| `dev` | Open project picker / full dev start |
| `p` | Fuzzy pick any project |
| `pr` | Pick project + open in editor |
| `newproj` | Create a new project with git + GitHub |
| `j` | Jump anywhere you've been (zoxide) |
| `take <dir>` | mkdir + cd in one step |

## Branch Management
| Command | Description |
|---------|-------------|
| `chbr` | Create and switch to a new branch |
| `cm` | Switch to main or master |
| `gbr` | Fuzzy switch any branch |
| `gss` | Switch branches |
| `gco` | Switch branch or restore files |
| `gb` | List, create, or delete branches |

## Git Shortcuts
| Command | Description |
|---------|-------------|
| `gs` | git status |
| `gc` | git commit |
| `gca` | Stage all + commit with message |
| `gp` | git push |
| `gpl` | git pull |
| `gl` | Log — graph, oneline, decorated |
| `gr` | Restore working directory changes |
| `gst` | Stash changes |
| `gstp` | Pop most recent stash |

## GitHub (Ctrl+G menu)
| Option | Description |
|--------|-------------|
| Pull Requests | View and manage PRs |
| Issues | View and manage issues |
| My Repos | Browse your repos |
| Clone | Clone a repo interactively |
| New Repo | Create a new GitHub repo |
| Create Branch | Create branch + push to remote |
| Switch Branch | Fuzzy switch with remote branches |
| Stage + Commit + Push | Full commit workflow in one flow |
| Delete Branch | Delete branch locally + remote |

## Dev Utilities
| Command | Description |
|---------|-------------|
| `killport <port>` | Kill whatever is running on a port |
| `serve [port]` | Quick local HTTP server (default 8080) |
| `ports` | Show all listening ports |
| `envload [file]` | Load a .env file into current shell |
| `scan-repos <repo...>` | Run forged scanner on one or more repos |

## Shell
| Command | Description |
|---------|-------------|
| `sz` | Reload zsh config (source ~/.zshrc) |
| `reload` | Restart shell |
| `safe` | Start shell with no config (debug) |
| `c` | Clear terminal |
| `..` | Up one directory |
| `ll` | List all files (detailed, icons) |
| `ls` | List files (icons) |
| `cat <file>` | View file with syntax highlighting (bat) |
| `mkdir <dir>` | Create directory + parents automatically |
| `grep` | Grep with color |
| `ghui` | Open GitHub dashboard |

## Auto Hooks (fire on cd)
| Hook | Trigger |
|------|---------|
| `auto-venv` | Activates `.venv` if present in project root |
| `auto-nvm` | Switches Node version if `.nvmrc` is present |
| `project_boot_node` | Boot sequence for Node projects |
| `project_boot_python` | Boot sequence for Python projects |
| `project_boot_rust` | Boot sequence for Rust projects |
