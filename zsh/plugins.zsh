### ----------------------------------------
### Plugins managed by zinit
### ----------------------------------------

# zsh-abbr — fish-style interactive abbreviations (must be set before plugin loads)
ABBR_USER_ABBREVIATIONS_FILE="$HOME/dev/dotfiles/zsh/abbreviations"
zinit light olets/zsh-abbr

# Fuzzy tab completion
zinit light Aloxaf/fzf-tab

zstyle ':completion:*' completer _complete _ignored _approximate

zinit ice wait lucid
zinit light zsh-users/zsh-autosuggestions

# Syntax must always be last  
zinit ice wait lucid
zinit light zsh-users/zsh-syntax-highlighting


# ---------------------------------------