### ----------------------------------------
### Plugins managed by zinit
### ----------------------------------------
zinit light Aloxaf/fzf-tab

autoload -Uz compinit
compinit

zinit ice wait lucid

zstyle ':completion:*' completer _complete _ignored _approximate

# then UI stuff
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting




# ---------------------------------------
