# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Testing Changes

There is no build step — changes take effect by reloading the shell. Use these patterns:

```zsh
# Reload a single module without restarting the shell
source ~/dev/dotfiles/zsh/<module>.zsh

# Full reload (restart shell)
exec zsh

# Validate syntax before sourcing
zsh -n ~/dev/dotfiles/zsh/<file>.zsh

# Safe shell (no config loaded) to test in isolation
zsh -f
```

To test a function in isolation, source only its file and call it directly.

## Architecture

`.zshrc` is a pure loader — no logic lives there. It sources modules in this order:

```
.zshrc
  → plugins.zsh          # zinit external plugins (fzf-tab, autosuggestions, syntax-highlighting)
  → lib/plugin-registry.zsh  # PLUGIN_REGISTRY and PLUGIN_PRIORITY assoc arrays
  → plugins/project/*.zsh    # per-language boot plugins (auto-loaded)
  → lib/*.zsh                # cache, detect, project (lib utilities)
  → ZSH_MODULES loop:        # env → tools → hooks → aliases → lib/cache → dev → starship
```

## Module Responsibilities

| File | Responsibility |
|------|---------------|
| `env.zsh` | Exports, setopts, lazy NVM, FZF color theme |
| `tools.zsh` | fzf config, fzf-tab zstyles, custom Ctrl-R widget, zoxide lazy-load |
| `hooks.zsh` | Hook dispatcher (`register_hook`/`fire_hook`), `chpwd` integration, `project_detect()` |
| `aliases.zsh` | Git shortcuts and shell aliases |
| `dev.zsh` | `dev`, `newproj`, `chbr`, `cmst`, `gbr`, `j`, `p`, `pr` workflow commands |
| `starship.zsh` | Lazy-loads starship on first prompt draw |
| `lib/cache.zsh` | `~/.dev-projects-cache` and `~/.dev-recent` via `refresh-dev-cache`/`add-recent` |
| `lib/plugin-registry.zsh` | `register_plugin` / `plugin_exists` — registry for boot plugins |
| `lib/project.zsh` | Project templates (node/python/rust), `project_ui` dashboard |
| `lib/detect.zsh` | `heredoc_lint` utility |

## Plugin System

Plugins live in `plugins/project/<lang>.zsh`. Each file must:
1. Define a `project_boot_<lang>()` function
2. Call `register_plugin <lang> project_boot_<lang> <priority>`

`project_detect()` in `hooks.zsh` inspects marker files (`package.json`, `requirements.txt`, `Cargo.toml`) and returns the type string. On `chpwd`, `_hook_chpwd` fires `on_dir_enter` and `on_enter/<type>` hooks. Boot plugins are invoked via `boot_project <type>` which looks up the function from `PLUGIN_REGISTRY`.

## Cache Files

| Path | Purpose |
|------|---------|
| `~/.dev-projects-cache` | `fd`-generated list of dirs under `$DEV_ROOT` (depth 3) |
| `~/.dev-recent` | Append-log of visited dirs, deduped, capped at 50 |

`refresh-dev-cache` regenerates the project cache. Both `dev` and `newproj` call it after navigation.

## Key Design Rules

- **No logic in `.zshrc`** — it only sources files.
- **Lazy-load expensive tools** — NVM, zoxide, and starship all use deferred init patterns.
- **`$DEV_ROOT`** (`~/dev/projects`) is the root for all project discovery; always check it is set before running cache/discovery functions.
- **`$FZF_THEME`** is defined in `env.zsh` and referenced by pickers in `lib/project.zsh`. Always pass it as `$FZF_THEME` rather than inlining colors.

## Known Issues / WIP Areas

- `tools.zsh` has malformed `zstyle` blocks (unclosed multi-line strings, stray shell words outside functions). These are work-in-progress and will cause parse errors if syntax-checked as a whole.
- `lib/project.zsh`'s `project_ui` and `project_ui_open` have broken `cut | fzf` pipelines — the `fzf` call is outside the pipeline and the preview references `${file}` instead of `{}`.
- `hooks.zsh` line 43 (`Auto-activate Python virtualenv`) is missing a `#` comment marker — that text is a bare word that will cause a syntax error.
- `future-ideas.md` contains snippet drafts (not active code).
