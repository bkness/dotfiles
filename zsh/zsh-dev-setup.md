# Architecture Overview

Zsh Core (.zshrc)
   ↓
Modular Loader
   ↓
────────────────────────────
env.zsh       → environment variables
tools.zsh     → CLI tool integrations
hooks.zsh     → event-driven shell behavior
aliases.zsh   → shortcuts
dev.zsh       → project workflow engine
starship.zsh  → prompt UI
────────────────────────────

# Directory Structure

~/dev/dotfiles/zsh/
  ├── init.zsh
  ├── env.zsh
  ├── tools.zsh
  ├── hooks.zsh
  ├── aliases.zsh
  ├── dev.zsh
  ├── starship.zsh
  
  # Installation
  
  mkdir -p ~/dev/dotfiles/zsh

# Minimal Loader
  
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME=""
plugins=(git)

source $ZSH/oh-my-zsh.sh

for file in ~/dev/dotfiles/zsh/*.zsh; do
  source "$file"
done

# System Enviroment

export DEV_ROOT="$HOME/dev/projects"

export EDITOR="code"
export VISUAL="code"

HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_ALL_DUPS
setopt SHARE_HISTORY

# Tools

## fzf
if [[ -f ~/.fzf.zsh ]]; then
  source ~/.fzf.zsh
fi

## zoxide
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

## fd exclusions (optional global config reference)
export FD_EXCLUDES="node_modules|.git|dist|build|.next"

# Hooks

autoload -U add-zsh-hook

load-nvmrc() {
  if [[ -f .nvmrc ]]; then
    nvm use --silent
  fi
}

add-zsh-hook chpwd load-nvmrc

# Workflow Engine

refresh-dev-cache() {
  fd . "$DEV_ROOT" --type d --max-depth 2 > ~/.dev-projects-cache
}

dev() {
  local dir

  [[ ! -f ~/.dev-projects-cache ]] && refresh-dev-cache

  dir=$(cat ~/.dev-projects-cache | fzf)

  [[ -z "$dir" ]] && return

  cd "$dir" || return

  refresh-dev-cache

  [[ -f package.json ]] && [[ ! -d node_modules ]] && npm install

  command -v code >/dev/null && code .

  if grep -q '"dev"' package.json 2>/dev/null; then
    npm run dev
  fi
}

# Shortcuts

alias c="clear"
alias ll="eza -la --icons"
alias ls="eza --icons"
alias cat="bat"

# Prompt UI

eval "$(starship init zsh)"

# Workflow Usage

## Launch project Picker

```
</> Bash

dev
```

## Jump Anywhere You've Been

```
</> Bash

zoxide query -i
```

## Navigate Faster

- Modular over monolithic
No logic in .zshrc

- Speration of concerns
Each file has a single responsibility

- Tool driven workflow
* fzf -> selection
* fd -> discovery
* zoxide -> memory navigation
* starship -> UI

- Stateless shell core
.zshrc only loads modules


