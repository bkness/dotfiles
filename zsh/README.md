# ⚒ dotfiles-v2: Zsh Shell Environment

> A modular, hook-driven zsh config built for speed — no logic in `.zshrc`, every file has one job.

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

---

## What It Does

- **One command to open any project** — fuzzy-pick from your entire dev folder instantly
- **Auto-detect and boot** — walks into a Node, Python, Rust, or Go project and initializes it automatically
- **Smart navigation** — jump anywhere you've been with zoxide memory
- **Auto-switch Node versions** — detects `.nvmrc` and switches silently on `cd`
- **Auto-activate virtualenvs** — Python `.venv` loads the moment you enter the project
- **Plugin system** — language boot plugins register themselves; the hook dispatcher calls them
- **Beautiful prompt** — Starship with Nerd Font icons, lazy-loaded on first draw
- **Modular by design** — `.zshrc` is a pure loader, zero logic

---

## Prerequisites

- **zsh** (macOS default)
- **[zinit](https://github.com/zdharma-continuum/zinit)** — plugin manager
- **[fzf](https://github.com/junegunn/fzf)** — fuzzy finder
- **[fd](https://github.com/sharkdp/fd)** — fast file discovery
- **[zoxide](https://github.com/ajeetdsouza/zoxide)** — smart directory jumper
- **[eza](https://github.com/eza-community/eza)** — modern `ls`
- **[bat](https://github.com/sharkdp/bat)** — modern `cat`
- **[starship](https://starship.rs)** — cross-shell prompt
- **[gh](https://cli.github.com)** — GitHub CLI
- A **[Nerd Font](https://www.nerdfonts.com/)** set as your terminal font

Install everything at once (macOS):
```sh
brew install fzf fd zoxide eza bat starship gh
brew install --cask font-jetbrains-mono-nerd-font
```

---

## Quick Start

1. **Clone:**
```sh
git clone git@github.com:bkness/dotfiles-v2.git ~/dev/dotfiles
```

2. **Set your dev root and editor in `env.zsh`:**
```sh
export DEV_ROOT="$HOME/dev/projects"
export EDITOR="code"
```

3. **Add to `~/.zshrc`:**
```sh
source ~/dev/dotfiles/zsh/lib/plugin-registry.zsh
source ~/dev/dotfiles/zsh/hooks.zsh

for file in ~/dev/dotfiles/zsh/plugins/project/*.zsh(N); do source "$file"; done
for file in ~/dev/dotfiles/zsh/lib/*.zsh(N); do source "$file"; done

for module in env tools aliases dev starship; do
  source ~/dev/dotfiles/zsh/${module}.zsh
done
```

4. **Reload:**
```sh
source ~/.zshrc
```

---

## Architecture

`.zshrc` is a pure loader — no logic lives there. It sources, in order:

```
.zshrc
  ├── plugins.zsh               # zinit plugins (skipped with a hint if zinit is missing)
  ├── lib/plugin-registry.zsh   # PLUGIN_REGISTRY + PLUGIN_PRIORITY
  ├── hooks.zsh                 # hook dispatcher, chpwd, project_detect(), scan + stale-branch checks, git nags
  ├── plugins/project/*.zsh     # language boot plugins (node, python, rust, go)
  ├── lib/*.zsh                 # widgets and helpers (see below)
  ├── env.zsh → tools.zsh → aliases.zsh → dev.zsh → starship.zsh
  ├── plugins/theme/neon-cockpit.zsh
  └── personal.zsh              # only when ~/.secrets sets FORGED_PERSONAL=1
```

### Module Responsibilities

| File | Responsibility |
|------|---------------|
| `env.zsh` | Exports, setopts, `~/.secrets`, lazy NVM, `$EDITOR` (VS Code or vim), FZF theme |
| `tools.zsh` | History settings, fzf keybindings, `fcd`, project dashboard widget |
| `hooks.zsh` | `register_hook`/`fire_hook`, `chpwd`, `project_detect()`, auto venv/nvm, background `forged scan --changed`, stale-branch warning, git commit/push nags |
| `aliases.zsh` | Shell aliases, `reload`, `scan`, `gfix` / `gundo` / `gsync` |
| `dev.zsh` | `dev`, `newproj`, `cb`, `cm`, `gbr`, `j`, `p`, `pr`, `gcm`, `gcmpr`, `take`, `killport`, `ports`, `serve`, `envload` |
| `starship.zsh` | Lazy-loads starship on first prompt draw |
| `personal.zsh` | Personal mode: Govee lights + git flash, status pushes, shell count, `workmode` |
| `lib/palette.zsh` | Ctrl+P command palette |
| `lib/github.zsh` | Ctrl+G GitHub dashboard |
| `lib/finder.zsh` · `lib/explorer.zsh` · `lib/snippets.zsh` | Ctrl+F code finder · Ctrl+Q file explorer · Ctrl+S snippets |
| `lib/music.zsh` | Ctrl+] Apple Music, `mplay` / `mnext` / `mprev` |
| `lib/dash.zsh` | `dash`: open a service dashboard |
| `lib/cache.zsh` | `~/.dev-projects-cache` and `~/.dev-recent` |
| `lib/project.zsh` | Project templates, `project_ui` dashboard |
| `lib/detect.zsh` | `heredoc_lint` utility |

---

## Plugin System

Language boot plugins live in `plugins/project/<lang>.zsh`. Each one:
1. Defines a `project_boot_<lang>()` function
2. Registers itself: `register_plugin <lang> project_boot_<lang> <priority>`

`project_detect()` inspects marker files (`package.json`, `requirements.txt`, `Cargo.toml`, `go.mod`) and returns the project type. On `cd`, `_hook_chpwd` fires `on_dir_enter` and `on_enter/<type>` hooks. Boot plugins are invoked via `boot_project <type>`.

**Supported:** Node · Python · Rust · Go

---

## Key Commands

| Command | Description |
|---------|-------------|
| `dev` | Fuzzy-pick a project, cd in, boot it |
| `newproj` | Create a new project with git init + template |
| `p` | Fuzzy-pick any project folder |
| `pr` | Pick a project and open in VS Code |
| `j` | Jump anywhere you've been (zoxide) |
| `cb` | Create and switch to a new branch |
| `cm` | Switch to main or master and pull |
| `gbr` | Fuzzy-switch any branch |
| `ll` | `eza -la --icons` |
| `ls` | `eza --icons` |
| `cat` | `bat` |
| `c` | Clear terminal |
| `..` | `cd ..` |
| `safe` | Start zsh with no config loaded |
| `reload` | Restart the shell |
| `dash` | Open a service dashboard (Vercel, Resend, npm…) |
| Ctrl+P | Command palette |
| Ctrl+G | GitHub dashboard |
| Ctrl+F · Ctrl+Q · Ctrl+J · Ctrl+S | Code finder · file explorer · jump · snippets |
| Ctrl+R | Shell history (Atuin) |

---

## Cache Files

| Path | Purpose |
|------|---------|
| `~/.dev-projects-cache` | `fd`-generated list of dirs under `$DEV_ROOT` (depth 3) |
| `~/.dev-recent` | Append-log of visited dirs, deduped, capped at 50 |

`refresh-dev-cache` regenerates the project cache. Both `dev` and `newproj` call it after navigation.

---

## Roadmap

See [`future-ideas.md`](future-ideas.md). Planned: per-project `.zshenv` overrides, `edit_file_in_project` (fuzzy file picker with bat preview).

**Long-term:** this shell is what **[Forged CLI](https://github.com/bkness/forged-cli)** installs: `npm install -g forged-cli && forged init`.

---

## Contributing

Fork the repo, make changes on a branch, open a pull request.

Questions or collaboration: [DevBrandon@icloud.com](mailto:DevBrandon@icloud.com)
