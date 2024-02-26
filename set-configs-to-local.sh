#!/bin/bash

# Define the $today variable
today=$(date +%Y-%m-%d)

# Function to ask permission
ask_permission() {
    read -p "$1 (y/Y to confirm): " response
    if [[ $response == [yY] ]]; then
        return 0
    else
        return 1
    fi
}

# Replace .zshrc
if ask_permission "Do you want to replace .zshrc in the repo with the one from your home directory?"; then
    cp ~/.zshrc ./configs/zshrc
    echo ".zshrc has been replaced."
fi

# Replace .tmux.conf
if ask_permission "Do you want to replace .tmux.conf in the repo with the one from your home directory?"; then
    cp ~/.tmux.conf ./configs/tmux.conf
    echo ".tmux.conf has been replaced."
fi

# Copy config.lua from ~/.config/lvim/ to the repo as LVIMconfig.lua
if ask_permission "Do you want to replace LVIMconfig.lua in the repo with the one from ~/.config/lvim/config.lua?"; then
    cp ~/.config/lvim/config.lua ./configs/LVIMconfig.lua
    echo "LVIMconfig.lua has been replaced."
fi

# Git operations
if ask_permission "Would you like to commit and push these changes to main?"; then
  git remote-seturl
    git remote set-url git@github.com:KobyW/koby-linux-conf.git
    git add .
    git commit -m "Updated configuration files $today"
    # Ensure you're on the main branch and it's up to date
    git checkout main
    git pull origin main
    git push origin main
    echo "Changes have been pushed to main."
else
    echo "Changes have not been pushed."
fi
