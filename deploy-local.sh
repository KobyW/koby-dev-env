#!/bin/bash

# Deploy script for localhost installation
# This script runs the ansible playbook against localhost without requiring
# inventory files or vault credentials

set -e

echo "========================================="
echo "Koby Dev Environment - Local Deployment"
echo "========================================="
echo ""
echo "This will install the development environment on localhost."
echo "You will be prompted for your sudo password if needed."
echo ""

# Check if ansible-playbook is installed
if ! command -v ansible-playbook &> /dev/null; then
    echo "Error: ansible-playbook is not installed."
    echo "Please install ansible first:"
    echo "  sudo apt-get update && sudo apt-get install ansible"
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Default to all tags
TAGS=""
SKIP_TAGS=""

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
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --tags TAGS        Only run tasks with specific tags (e.g., 'light' or 'zsh,tmux')"
            echo "  --skip-tags TAGS   Skip tasks with specific tags (e.g., 'heavy')"
            echo "  --help, -h         Show this help message"
            echo ""
            echo "Available tags:"
            echo "  light    - Install lightweight tools and configs"
            echo "  heavy    - Install resource-intensive tools (docker, npm, cargo)"
            echo "  zsh      - Install zsh and oh-my-zsh"
            echo "  tmux     - Install tmux and configuration"
            echo "  neovim   - Install Neovim"
            echo "  lunarvim - Install LunarVim"
            echo "  p10k     - Install Powerlevel10k theme"
            echo ""
            echo "Examples:"
            echo "  $0                       # Install everything"
            echo "  $0 --tags light          # Install only lightweight tools"
            echo "  $0 --skip-tags heavy     # Install everything except heavy tools"
            echo "  $0 --tags zsh,tmux       # Install only zsh and tmux"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Build the ansible-playbook command
CMD="ansible-playbook"
CMD="$CMD -i localhost,"
CMD="$CMD --connection=local"
CMD="$CMD --ask-become-pass"
CMD="$CMD $TAGS"
CMD="$CMD $SKIP_TAGS"
CMD="$CMD $SCRIPT_DIR/deploy.yml"

echo "Running: $CMD"
echo ""
echo "Press Ctrl+C to cancel, or Enter to continue..."
read -r

# Execute the playbook
eval $CMD

echo ""
echo "========================================="
echo "Deployment complete!"
echo "========================================="
echo ""
echo "You may need to:"
echo "1. Log out and log back in for shell changes to take effect"
echo "2. Open a new terminal to use zsh as your default shell"
echo "3. Run 'tmux' and press Prefix+I to install tmux plugins"
echo "4. Run 'lvim' to open LunarVim and let it install plugins"