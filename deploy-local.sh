#!/bin/bash

# Deploy script for localhost installation
# This script runs the ansible playbook against localhost without requiring
# inventory files or vault credentials

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo ""
echo -e "${BOLD}${YELLOW}██╗  ██╗ ██████╗ ██████╗ ██╗   ██╗${NC}"
echo -e "${BOLD}${YELLOW}██║ ██╔╝██╔═══██╗██╔══██╗╚██╗ ██╔╝${NC}"
echo -e "${BOLD}${YELLOW}█████╔╝ ██║   ██║██████╔╝ ╚████╔╝${NC}"
echo -e "${BOLD}${YELLOW}██╔═██╗ ██║   ██║██╔══██╗  ╚██╔╝${NC}"
echo -e "${BOLD}${YELLOW}██║  ██╗╚██████╔╝██████╔╝   ██║${NC}"
echo -e "${BOLD}${YELLOW}╚═╝  ╚═╝ ╚═════╝ ╚═════╝    ╚═╝ ${NC}"
echo -e "${CYAN}=========================================${NC}"
echo -e "${BOLD}${GREEN}Koby Dev Environment - Local Deployment${NC}"

echo -e "${CYAN}=========================================${NC}"
echo ""
echo -e "${YELLOW}This will install the development environment on localhost.${NC}"
echo -e "${YELLOW}You will be prompted for your sudo password if needed.${NC}"
echo ""

# Check if ansible-playbook is installed
if ! command -v ansible-playbook &> /dev/null; then
    echo -e "${RED}Error: ansible-playbook is not installed.${NC}"
    echo -e "${YELLOW}Please install ansible first:${NC}"
    echo -e "${GREEN}  sudo apt-get update && sudo apt-get install ansible${NC}"
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Default to all tags
TAGS=""
SKIP_TAGS=""
VERBOSITY=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --tags)
            TAGS="--tags $2"
            shift 2
            ;;
        --skip-tags)
            SKIP_TAGS="--skip-tags $2"
            shift 2
            ;;
        -v|-vv|-vvv|-vvvv)
            VERBOSITY="$1"
            shift
            ;;
        --help|-h)
            echo -e "${BOLD}Usage:${NC} $0 [OPTIONS]"
            echo ""
            echo -e "${BOLD}Options:${NC}"
            echo -e "  ${CYAN}--tags TAGS${NC}        Only run tasks with specific tags (e.g., 'light' or 'zsh,tmux')"
            echo -e "  ${CYAN}--skip-tags TAGS${NC}   Skip tasks with specific tags (e.g., 'heavy')"
            echo -e "  ${CYAN}-v, -vv, -vvv, -vvvv${NC}  Increase verbosity of ansible output"
            echo -e "  ${CYAN}--help, -h${NC}         Show this help message"
            echo ""
            echo -e "${BOLD}Available tags:${NC}"
            echo -e "  ${GREEN}light${NC}    - Install lightweight tools and configs"
            echo -e "  ${GREEN}heavy${NC}    - Install resource-intensive tools (docker, npm, cargo)"
            echo -e "  ${GREEN}zsh${NC}      - Install zsh and oh-my-zsh"
            echo -e "  ${GREEN}tmux${NC}     - Install tmux and configuration"
            echo -e "  ${GREEN}neovim${NC}   - Install Neovim"
            echo -e "  ${GREEN}lunarvim${NC} - Install LunarVim"
            echo -e "  ${GREEN}p10k${NC}     - Install Powerlevel10k theme"
            echo ""
            echo -e "${BOLD}Examples:${NC}"
            echo -e "  ${BLUE}$0${NC}                       # Install everything"
            echo -e "  ${BLUE}$0 --tags light${NC}          # Install only lightweight tools"
            echo -e "  ${BLUE}$0 --skip-tags heavy${NC}     # Install everything except heavy tools"
            echo -e "  ${BLUE}$0 --tags zsh,tmux${NC}       # Install only zsh and tmux"
            echo -e "  ${BLUE}$0 -vv${NC}                    # Install everything with verbose output"
            echo -e "  ${BLUE}$0 --tags lunarvim -vvv${NC}  # Debug lunarvim installation"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo -e "${YELLOW}Use --help for usage information${NC}"
            exit 1
            ;;
    esac
done

# Build the ansible-playbook command
CMD="ansible-playbook"
CMD="$CMD -i localhost,"
CMD="$CMD --connection=local"
CMD="$CMD --ask-become-pass"
CMD="$CMD $VERBOSITY"
CMD="$CMD $TAGS"
CMD="$CMD $SKIP_TAGS"
CMD="$CMD $SCRIPT_DIR/deploy.yml"

echo -e "${CYAN}Running:${NC} ${BOLD}$CMD${NC}"
echo ""
echo -e "${YELLOW}Press Ctrl+C to cancel, or Enter to continue...${NC}"
read -r

# Execute the playbook
eval $CMD

echo ""
echo -e "${CYAN}=========================================${NC}"
echo -e "${BOLD}${GREEN}Deployment complete!${NC}"
echo -e "${CYAN}=========================================${NC}"
echo ""
echo -e "${BOLD}You may need to:${NC}"
echo -e "${YELLOW}1.${NC} Log out and log back in for shell changes to take effect"
echo -e "${YELLOW}2.${NC} Open a new terminal to use zsh as your default shell"
echo -e "${YELLOW}3.${NC} Run ${GREEN}'tmux'${NC} and press ${GREEN}Prefix+I${NC} to install tmux plugins"
echo -e "${YELLOW}4.${NC} Run ${GREEN}'lvim'${NC} to open LunarVim and let it install plugins"
