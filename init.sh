#!/bin/bash

# Confirm with the user the server and path is correct
read -p "Is the server and path correct? (y/Y to confirm): " confirm_server
if [[ $confirm_server != [yY] ]]; then
    echo "Server and path not confirmed. Exiting."
    exit 1
fi

# Check if git is installed and install if not
if ! command -v git &> /dev/null; then
    echo "Git is not installed. Installing git..."
    sudo apt-get install git
fi

# Check if the git repo is up to date
git config --global init.defaultBranch main
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

# 1. Install zsh
if proceed_task "Install zsh"; then
    sudo apt-get install zsh
fi

# 2. Install oh my zsh
if proceed_task "Install oh my zsh"; then
    sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
fi

# 3. Install P10K
if proceed_task "Install P10K"; then
    sudo apt install fonts-firacode
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
fi

# 4. Install neovim v0.9.5
if proceed_task "Install neovim v0.9.5"; then
    wget https://github.com/neovim/neovim/releases/download/v0.9.5/nvim-linux64.tar.gz
    sudo tar -xzvf nvim-linux64.tar.gz -C ~/.local/bin/
    rm -rf nvim-linux64.tar.gz
fi

# 5. Copy .zshrc to home directory
if proceed_task "Copy .zshrc to home directory"; then
    cp ./configs/zshrc ~/.zshrc
fi

# 6. Install tmux
if proceed_task "Install tmux"; then
    if command -v apt-get &> /dev/null; then
        sudo apt-get install tmux
    elif command -v yum &> /dev/null; then
        sudo yum install tmux
    else
        echo "No suitable package manager found for tmux installation."
    fi
fi

# 7. Copy .tmux.conf to home directory
if proceed_task "Copy .tmux.conf to home directory"; then
    cp ./configs/tmux.conf ~/.tmux.conf
fi

# 8. Install cargo
if proceed_task "Install cargo"; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    source "$HOME/.cargo/env"
fi

# Install Lazygit before installing LunarVim
if proceed_task "Install Lazygit"; then
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin
fi

# 9. Install lunarvim
if proceed_task "Install lunarvim"; then
    LV_BRANCH='release-1.3/neovim-0.9' bash <(curl -s https://raw.githubusercontent.com/LunarVim/LunarVim/release-1.3/neovim-0.9/utils/installer/install.sh)
fi

# 10. Copy LVIMconfig.lua to ~/.config/lvim/ as 'config.lua'
if proceed_task "Copy LVIMconfig.lua to LunarVim config directory"; then
    mkdir -p ~/.config/lvim/
    cp ./LVIMconfig.lua ~/.config/lvim/config.lua
fi

# 11. Install zsh autosuggestions
if proceed_task "Install zsh autosuggestions"; then
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
  echo "Need to source zsh for plugin to take effect."
fi

# 12. install bat (replaces cat)
if proceed_task "Install bat (better cat)"; then
    if command -v apt-get &> /dev/null; then
        sudo apt-get install bat
    elif command -v yum &> /dev/null; then
        sudo yum install bat
    else
        echo "No suitable package manager found for tmux installation."
    fi
fi

# 12. install zoxide (replaces cd)
if proceed_task "Install zoxide (better cd)"; then
  curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
fi

# 12. install tpm (tmux plugin manager)
if proceed_task "Install tpm (tmux plugin manager)"; then
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  echo "Will need to run this outside of a tmux session: tmux source ~/path/to/tmux/conf"
fi

# Finally, source the zshrc file.
if proceed_task "Source zshrc"; then
  source ~/.zshrc
fi

echo "done."

