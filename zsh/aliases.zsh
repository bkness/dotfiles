# Aliases

# Git — core muscle-memory shortcuts
alias gs="git status" # desc: Check the status of the working directory 
alias gc="git commit" # desc: Commit changes using 'git commit'
alias gca="git commit -a -m" # desc: Stage all changes and commit with a message 
alias gp="git push" # desc: Push changes to the remote repository
alias gpl="git pull" # desc: Pull changes from the remote repository 
alias gl="git log --oneline --graph --decorate" # desc: Show a concise and visually appealing commit history 
alias gr="git restore" # desc: Restore changes in the working directory 
alias gss="git switch" # desc: Switch branches
alias gst="git stash" # desc: Save changes to a new stash using 'git stash'
alias gstp="git stash pop" # desc: Apply the most recent stash and remove it from the stash list using 'git stash pop'
alias gb="git branch" # desc: List, create, or delete branches using 'git branch'
alias gco="git checkout" # desc: Switch branch or restore files

# GitHub dashboard
alias ghui="github_ui" # desc: Open GitHub dashboard

# Shell
alias c="clear" # desc: Clear terminal
alias ..="cd .." # desc: Up one directory
alias ll="eza -la --icons" # desc: List all files (detailed, icons)
alias ls="eza --icons" # desc: List files (icons)
alias cat="bat" # desc: View file with syntax highlight
alias safe="zsh -f" # desc: Start shell without config
alias reload="exec zsh -l" # desc: Reload shell config
alias sz="source ~/.zshrc" # desc: Reload zsh config
alias mkdir="mkdir -p"  # desc: Create directories (with parents)
alias grep="grep --color=auto" # desc: Colored grep output

