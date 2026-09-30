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

`.zshrc` is a pure loader — no logic lives there. Load order:

```
.zshrc
  → plugins.zsh                  # zinit plugins; skipped with a hint if zinit is missing
  → lib/plugin-registry.zsh      # PLUGIN_REGISTRY and PLUGIN_PRIORITY
  → hooks.zsh                    # dispatcher first: project plugins call register_hook
  → plugins/project/*.zsh        # per-language boot plugins
  → lib/*.zsh                    # widgets + helpers (palette, github, finder, music, dash…)
  → env → tools → aliases → dev → starship
  → plugins/theme/neon-cockpit.zsh
  → personal.zsh                 # only if ~/.secrets sets FORGED_PERSONAL=1
```

`personal.zsh` holds everything tied to Brandon's Mac (Govee MACs, the status API token, the ASUS + MacBook layout). Keep machine-specific code there so `forged init` installs stay portable. Claude Code's shells set `CLAUDECODE=1`; the shell open/close hooks skip them.

## Module Responsibilities

See the table in `README.md`.

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
- **`$DEV_ROOT`** (`~/dev/projects`) is the root for all project discovery; it may not exist on a fresh machine, so discovery functions must tolerate that.
- **Anything with nested quotes or several commands is a function, not an abbr.** `abbr add` rewrites `abbreviations` and has mangled quotes before (and once emptied it).
- **Govee allows ~10 requests a minute for the whole account.** Send light commands one at a time and space out tests.
- **`$FZF_THEME`** is defined in `env.zsh` and referenced by pickers in `lib/project.zsh`. Always pass it as `$FZF_THEME` rather than inlining colors.

## Known Issues / WIP Areas

- `future-ideas.md` contains snippet drafts (not active code).
