#!/usr/bin/env bash

###                                                                    ###
#                                                                        #
# CAPTURE LIVE MACHINE CONFIGS BACK INTO THIS REPO                       #
#                                                                        #
# For each config: if the home path is a symlink (deploy.yml's normal    #
# state) edits already land in the repo, so it is skipped. Real files    #
# are copied into the repo after confirmation.                           #
#                                                                        #
###                                                                    ###

set -eo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

ask() {
    read -r -p "$1 (y/Y to confirm): " response
    [[ "$response" == [yY] ]]
}

captured=()

# capture <home path> <repo-relative dest>
capture() {
    local src="$1"
    local dest="$2"

    if [ -L "$src" ]; then
        echo -e "${GREEN}skip${NC}  $src is a symlink ($(readlink "$src")) - edits already land in the repo"
        return 0
    fi
    if [ ! -e "$src" ]; then
        echo -e "${YELLOW}skip${NC}  $src not found on this machine"
        return 0
    fi
    if ask "Copy $src -> $dest?"; then
        if [ -d "$src" ]; then
            cp -R "$src/." "$REPO_DIR/$dest/"
        else
            cp "$src" "$REPO_DIR/$dest"
        fi
        captured+=("$dest")
        echo -e "${CYAN}copied${NC} $src -> $dest"
    fi
}

capture "$HOME/.zshrc"        "configs/zshrc"
capture "$HOME/.tmux.conf"    "configs/tmux.conf"
capture "$HOME/.p10k.zsh"     "configs/p10k.zsh"
capture "$HOME/.config/nvim"  "configs/nvim"

if [ ${#captured[@]} -eq 0 ]; then
    echo -e "${GREEN}Nothing captured - repo unchanged.${NC}"
    exit 0
fi

echo ""
echo -e "${CYAN}Repo changes:${NC}"
git status --short -- "${captured[@]}"
git --no-pager diff --stat -- "${captured[@]}"
echo ""

if ! ask "Stage and commit these changes on branch '$(git branch --show-current)'?"; then
    echo "Left uncommitted. Review with: git diff"
    exit 0
fi

git add -- "${captured[@]}"
default_msg="chore(configs): capture local configs $(date +%Y-%m-%d)"
read -r -p "Commit message [$default_msg]: " msg
git commit -m "${msg:-$default_msg}"

if ask "Push to origin/$(git branch --show-current)?"; then
    git push origin "$(git branch --show-current)"
    echo -e "${GREEN}Pushed.${NC}"
else
    echo "Committed locally, not pushed."
fi
