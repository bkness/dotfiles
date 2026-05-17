# dotfiles

Modular zsh config powering the [devforge](https://weballtech.com/manual) developer environment. Ships as part of [forged-cli](https://npmjs.com/package/forged-cli).

## Prerequisites

| Tool | Purpose |
|------|---------|
| `zsh` | Shell (macOS default) |
| `gh` | GitHub CLI — issues, PRs, repos |
| `fzf` | Fuzzy finder — all pickers |
| `eza` | Modern `ls` replacement |
| `bat` | Syntax-highlighted `cat` |
| `fd` | Fast `find` replacement |
| `zoxide` | Smart `cd` with memory |
| `starship` | Prompt |

```zsh
brew install gh fzf eza bat fd zoxide starship
```

## Install

```zsh
npm install -g forged-cli
forged init
exec zsh
```

`forged init` clones this repo to `~/dev/dotfiles` and adds a source hook to `~/.zshrc`. Your existing config is never overwritten.

## One-time GitHub setup

```zsh
gh auth login                  # authenticate with GitHub
gh auth refresh -s project     # grant Projects v2 scope (for board auto-creation)
```

The `project` scope is required for the issue → PR workflow to auto-create and update project boards.

## Widgets

All widgets are accessible via `Ctrl+P` (command palette) or their direct keybind.

| Keybind | Widget | Description |
|---------|--------|-------------|
| `Ctrl+P` | Command palette | Browse and run any command, alias, or widget. `Ctrl+F` cycles category filter. |
| `Ctrl+G` | GitHub dashboard | Full GitHub TUI — issues, PRs, branches, repos, notifications |
| `Ctrl+E` | File explorer | Navigate directories with Tab/Shift+Tab, cd or insert path on Enter |
| `Ctrl+V` | Govee lights | Room + action picker for smart light control |
| `Ctrl+R` | History search | fzf-powered shell history |

## GitHub Workflow (Ctrl+G)

The centerpiece of this config. From any git repo:

**Create an issue** — `Ctrl+G` → Issues → Create Issue
```
Title → Body ($EDITOR) → Labels (Tab multi-select) → Assignee → Branch type
```
- Auto-creates a branch: `fix/42-my-issue-title`
- Auto-creates a GitHub Projects v2 board named after the repo
- Auto-links the repo to the board
- Sets issue status to **In Progress**

**Stage, commit, open PR** — `Ctrl+G` → Stage & Commit
```
Select files → Commit message → Open PR (optional)
```
- PR body opens in `$EDITOR` pre-filled with `Closes #42` (detected from branch name)
- Sets issue status to **In Review**

**Result:** merge the PR → issue closes automatically, status → Done.

## Module Overview

| File | Responsibility |
|------|---------------|
| `env.zsh` | Exports, setopts, lazy NVM, FZF theme |
| `tools.zsh` | fzf config, fzf-tab, Ctrl+R widget, zoxide |
| `hooks.zsh` | Hook dispatcher, `chpwd`, `project_detect()`, auto-venv, auto-nvm |
| `aliases.zsh` | Git shortcuts, shell aliases, Govee widget + flash-on-push |
| `dev.zsh` | `dev`, `newproj`, `p`, `pr`, `j`, `cb`, `cm`, `gbr` |
| `starship.zsh` | Lazy-loads starship on first prompt draw |
| `lib/cache.zsh` | `~/.dev-projects-cache` and `~/.dev-recent` |
| `lib/github.zsh` | Full GitHub TUI — issues, PRs, repos, project board sync |
| `lib/palette.zsh` | Ctrl+P command palette with live alias/plugin/hook discovery |
| `lib/explorer.zsh` | Ctrl+E file explorer with bat/eza preview |
| `lib/project.zsh` | Project templates, `project_ui` dashboard |
| `lib/plugin-registry.zsh` | `register_plugin` / `plugin_exists` — boot plugin registry |
| `lib/detect.zsh` | `heredoc_lint` utility |

## Key Commands

```zsh
dev [name]      # open project + auto-boot
newproj [name]  # scaffold new project
p               # fuzzy project picker
j               # jump anywhere (zoxide)
sz              # reload shell config
scan            # dep scan + push badge cache
```

Full reference: [weballtech.com/manual](https://weballtech.com/manual)
