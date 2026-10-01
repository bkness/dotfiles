### ----------------------------------------
### Plugins managed by zinit
### ----------------------------------------

# zsh-abbr — fish-style interactive abbreviations (must be set before plugin loads)
ABBR_USER_ABBREVIATIONS_FILE="$HOME/dev/dotfiles/zsh/abbreviations"
zinit light olets/zsh-abbr

# Extra completion definitions (hundreds of commands). Not deferred: it has to
# be on fpath before compinit runs in .zshrc
zinit light zsh-users/zsh-completions

# Fuzzy tab completion
zinit light Aloxaf/fzf-tab

zstyle ':completion:*' completer _complete _ignored _approximate

zinit ice wait lucid
zinit light zsh-users/zsh-autosuggestions

# Syntax must always be last
zinit ice wait lucid
zinit light zdharma-continuum/fast-syntax-highlighting


# ---------------------------------------