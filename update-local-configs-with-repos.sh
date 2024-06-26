#!/bin/bash

# Define the $today variable
today=$(date +%Y-%m-%d)

# Check if the git repo is up to date
git fetch origin
HEADHASH=$(git rev-parse HEAD)
UPSTREAMHASH=$(git rev-parse main@{upstream})

if [ "$HEADHASH" != "$UPSTREAMHASH" ]; then
    read -p "Your git repo is not up to date. Do you want to update? (y/Y to confirm): " update_repo
    if [[ $update_repo == [yY] ]]; then
        git pull
        echo "Repository updated."
    else
        echo "Repository not updated."
    fi
else
    echo "Git repository is up to date."
fi

# Function to ask permission before proceeding with each task
proceed_task() {
    read -p "Do you want to proceed with: $1? (y/Y to confirm): " proceed
    if [[ $proceed != [yY] ]]; then
        echo "Skipping: $1"
        return 1
    fi
    return 0
}

# TODO: Implement this
delete_previous_backups(){
  read -p "Do you want to delete previous backups for the configs? (y/Y to confirm): " delete_backups
    if [[ $delete_backups != [yY] ]]; then
        echo "Keeping Backups"
        return 1
    fi
    return 0
}

# Copy .zshrc to home directory
if proceed_task "Copy .zshrc to home directory"; then
    echo "Creating backup and overwriting .zshrc"
   # Back up config
    cp ~/.zshrc ~/.zshrc.backup-$today
    cp ./configs/zshrc ~/.zshrc
fi

# Copy .tmux.conf to home directory
if proceed_task "Copy .tmux.conf to home directory"; then
    echo "Creating backup and overwriting .tmux.conf"
   # Back up config
    cp ~/.tmux.conf ~/.tmux.conf.backup-$today
    cp ./configs/tmux.conf ~/.tmux.conf
fi

 if proceed_task "Copy LVIMconfig.lua to LunarVim config directory"; then
    echo "Creating backup and overwriting config.luna"
    mkdir -p ~/.config/lvim/
   # Back up config
    cp ~/.config/lvim/config.lua ~/.config/lvim/config.lua.backup-$today
   # Copy LVIMconfig.lua to ~/.config/lvim/ as 'config.lua'
    cp ./configs/LVIMconfig.lua ~/.config/lvim/config.lua
fi
