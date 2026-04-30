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

## GitHub Workflow (Ctrl+G)

The centerpiece of this config. From any git repo:

**Create an issue** — `Ctrl+G` → Issues → Create Issue
```
Title → Body → Labels (Tab multi-select) → Assignee → Branch type
```
- Auto-creates a branch: `fix/42-my-issue-title`
- Auto-creates a GitHub Projects v2 board named after the repo
- Auto-links the repo to the board
- Sets issue status to **In Progress**

**Stage, commit, open PR** — `Ctrl+G` → Stage & Commit
```
Select files → Commit message → Open PR (optional)
```
- PR body is pre-filled with `Closes #42` (detected from branch name)
- Sets issue status to **In Review**

**Result:** merge the PR → issue closes automatically, status → Done.

## Module Overview

| File | Responsibility |
|------|---------------|
| `env.zsh` | Exports, setopts, lazy NVM, FZF theme |
| `tools.zsh` | fzf config, fzf-tab, Ctrl+R widget, zoxide |
| `hooks.zsh` | Hook dispatcher, `chpwd`, `project_detect()` |
| `aliases.zsh` | Git shortcuts and shell aliases |
| `dev.zsh` | `dev`, `newproj`, `p`, `pr`, `j`, `cb`, `cm`, `gbr` |
| `starship.zsh` | Lazy-loads starship on first prompt draw |
| `lib/cache.zsh` | `~/.dev-projects-cache` and `~/.dev-recent` |
| `lib/github.zsh` | Full GitHub TUI — issues, PRs, repos, workflow |
| `lib/project.zsh` | Project templates, `project_ui` dashboard |
| `lib/detect.zsh` | `heredoc_lint` utility |

## Key Commands

```zsh
dev [name]      # open project + auto-boot
newproj [name]  # scaffold new project
p               # fuzzy project picker
j               # jump anywhere (zoxide)
ghui            # GitHub dashboard
sz              # reload shell config
```

Full reference: [weballtech.com/manual](https://weballtech.com/manual)
