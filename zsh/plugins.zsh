### ----------------------------------------
### Plugins managed by zinit
### ----------------------------------------

# Fuzzy tab completion
zinit light Aloxaf/fzf-tab

# Fuzzy history search
zinit ice wait lucid

# desc: Fuzzy history search
zstyle ':completion:*' completer _complete _ignored _approximate

# then UI stuff
zinit ice wait lucid
zinit light zsh-users/zsh-autosuggestions

# Syntax must always be last  
zinit ice wait lucid
zinit light zsh-users/zsh-syntax-highlighting


# ---------------------------------------