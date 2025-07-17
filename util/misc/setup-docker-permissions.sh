#!/bin/bash

# Docker Permissions Setup Script
# This script helps manage Docker group membership and /docker_data directory permissions

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    local color=$1
    shift
    echo -e "${color}$@${NC}"
}

# Function to check prerequisites
check_prerequisites() {
    print_color $BLUE "Checking prerequisites..."
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        print_color $RED "Error: Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check if docker group exists
    if ! getent group docker > /dev/null 2>&1; then
        print_color $RED "Error: Docker group does not exist. Docker may not be properly installed."
        exit 1
    fi
    
    print_color $GREEN "✓ Prerequisites checked successfully"
}

# Function to add user to docker group
add_user_to_docker_group() {
    print_color $YELLOW "\nAdding user '$USER' to docker group..."
    
    # Check if user is already in docker group
    if groups "$USER" | grep -q '\bdocker\b'; then
        print_color $GREEN "User '$USER' is already a member of the docker group"
    else
        sudo usermod -aG docker "$USER"
        print_color $GREEN "✓ User '$USER' added to docker group"
        print_color $YELLOW "Note: You'll need to log out and back in, or run 'newgrp docker' for changes to take effect"
        
        # Ask if user wants to apply group membership now
        read -p "Apply group membership now with 'newgrp docker'? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            newgrp docker
        fi
    fi
}

# Function to change docker_data permissions
change_docker_data_permissions() {
    print_color $YELLOW "\nChanging /docker_data ownership to docker group..."
    
    # Check if /docker_data exists
    if [ ! -d "/docker_data" ]; then
        print_color $RED "Error: /docker_data directory does not exist"
        read -p "Create /docker_data directory? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo mkdir -p /docker_data
            print_color $GREEN "✓ Created /docker_data directory"
        else
            return 1
        fi
    fi
    
    # Change group ownership
    sudo chgrp -R docker /docker_data
    print_color $GREEN "✓ Changed group ownership to docker"
    
    # Set permissions
    sudo chmod -R g+rwX /docker_data
    print_color $GREEN "✓ Set group read/write permissions (with execute for directories)"
}

# Function to verify changes
verify_changes() {
    print_color $BLUE "\n=== Verification ==="
    
    # Check user groups
    print_color $YELLOW "Current user groups:"
    id -nG | tr ' ' '\n' | grep -E '^(docker|$USER)$' | sort | tr '\n' ' '
    echo
    
    # Check if docker group is listed
    if id -nG | grep -q '\bdocker\b'; then
        print_color $GREEN "✓ User is in docker group"
    else
        print_color $YELLOW "⚠ User is not yet in docker group (may need to log out/in)"
    fi
    
    # Check /docker_data permissions if it exists
    if [ -d "/docker_data" ]; then
        print_color $YELLOW "\n/docker_data directory info:"
        ls -ld /docker_data
        
        # Check if group is docker
        if ls -ld /docker_data | awk '{print $4}' | grep -q '^docker$'; then
            print_color $GREEN "✓ /docker_data is owned by docker group"
        else
            print_color $RED "✗ /docker_data is not owned by docker group"
        fi
    fi
}

# Main menu
show_menu() {
    print_color $BLUE "\n=== Docker Permissions Setup Script ==="
    echo "Please select an option:"
    echo "1) Add current user to docker group only"
    echo "2) Change /docker_data ownership to docker group only"
    echo "3) Both (add user to group AND change directory ownership)"
    echo "4) Verify current settings"
    echo "5) Exit"
    echo
}

# Main script
main() {
    check_prerequisites
    
    while true; do
        show_menu
        read -p "Enter your choice (1-5): " choice
        
        case $choice in
            1)
                add_user_to_docker_group
                verify_changes
                ;;
            2)
                change_docker_data_permissions
                verify_changes
                ;;
            3)
                add_user_to_docker_group
                change_docker_data_permissions
                verify_changes
                ;;
            4)
                verify_changes
                ;;
            5)
                print_color $BLUE "Exiting..."
                exit 0
                ;;
            *)
                print_color $RED "Invalid option. Please try again."
                ;;
        esac
        
        echo
        read -p "Press Enter to continue..."
    done
}

# Run main function
main