### ----------------------------------------
### Plugins managed by zinit
### ----------------------------------------

# Fuzzy tab completion
zinit light Aloxaf/fzf-tab

zstyle ':completion:*' completer _complete _ignored _approximate

zinit ice wait lucid
zinit light zsh-users/zsh-autosuggestions

# Syntax must always be last  
zinit ice wait lucid
zinit light zsh-users/zsh-syntax-highlighting


# ---------------------------------------