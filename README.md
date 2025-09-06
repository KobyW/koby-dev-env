# Koby's Dev Environment

An automated development environment setup using Ansible for Linux systems. This repository contains playbooks and configurations to quickly provision a consistent, feature-rich development environment across multiple machines.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
  - [Local Installation](#local-installation)
  - [Remote Installation](#remote-installation)
- [Configuration Files](#configuration-files)
- [Installed Tools](#installed-tools)
- [Directory Structure](#directory-structure)
- [Tags System](#tags-system)
- [Customization](#customization)
- [Troubleshooting](#troubleshooting)

## Overview

This repository provides an Ansible-based solution for setting up a complete development environment with modern terminal tools, text editors, and developer utilities. It's designed to be modular, allowing you to install only the components you need using Ansible tags.

## Features

- **Automated Setup**: One-command installation using Ansible
- **Modular Installation**: Use tags to install only what you need
- **Modern Terminal Stack**: Zsh with Oh-My-Zsh, Powerlevel10k theme, and tmux
- **Advanced Text Editing**: Neovim v0.9.5 with LunarVim IDE layer
- **Developer Tools**: Docker, npm, Rust/Cargo, and various CLI utilities
- **Version Control**: Lazygit for enhanced Git workflows
- **Cross-Architecture Support**: Works on both x86_64 and ARM64 systems

## Prerequisites

- **Operating System**: Ubuntu/Debian-based Linux distribution
- **Required Software**: 
  - Ansible (for deployment)
  - Git (installed automatically if missing)
  - Python3 with pip

To install Ansible:
```bash
sudo apt-get update && sudo apt-get install ansible
```

## Installation

### Local Installation

The easiest way to deploy on your local machine:

```bash
# Clone the repository
git clone https://github.com/KobyW/koby-dev-env
cd koby-dev-env

# Run the deployment script
./deploy-local.sh
```

#### Local Installation Options

```bash
# Install everything
./deploy-local.sh

# Install only lightweight tools
./deploy-local.sh --tags light

# Install everything except heavy tools
./deploy-local.sh --skip-tags heavy

# Install specific tools only
./deploy-local.sh --tags "zsh,tmux,neovim"

# Verbose output for debugging
./deploy-local.sh -vv
```

### Remote Installation

For deploying to remote servers:

```bash
# Basic remote deployment
ansible-playbook -i hosts/<inventory>.ini deploy.yml \
  --extra-vars "@creds/<vault>.yml" \
  --ask-vault-pass \
  --private-key=<private-key-path>

# With specific tags
ansible-playbook -i hosts/<inventory>.ini deploy.yml \
  --extra-vars "@creds/<vault>.yml" \
  --ask-vault-pass \
  --tags "light" \
  --private-key=<private-key-path>
```

## Configuration Files

### Core Configurations

| File | Purpose |
|------|---------|
| `configs/zshrc` | Zsh shell configuration with plugins, aliases, and custom functions |
| `configs/p10k.zsh` | Powerlevel10k theme configuration for an enhanced prompt |
| `configs/tmux.conf` | Tmux configuration with custom keybindings and plugins |
| `configs/LVIMconfig.lua` | LunarVim IDE configuration with custom plugins and settings |
| `configs/lua/koby/` | Additional Lua modules for LunarVim customization |

### Environment Files

| File | Purpose |
|------|---------|
| `env/zsh-machine-specific.zshrc` | Machine-specific Zsh configurations |
| `env/zsh-machine-specific.example` | Template for machine-specific settings |

### Helper Scripts

| Script | Purpose |
|------|---------|
| `deploy-local.sh` | Simplified local deployment with colorful UI |
| `set-configs-to-local.sh` | Link configuration files to home directory |
| `util/misc/claude-init.sh` | Initialize Claude AI development tools |
| `util/misc/setup-docker-permissions.sh` | Configure Docker user permissions |
| `util/ssh/zsh-ssh-util.zshrc` | SSH utility functions for Zsh |

## Installed Tools

### Core Tools (Always Installed)

- **Git**: Version control system
- **Curl**: Command-line data transfer tool
- **Build-essential**: Compilation tools (gcc, make, etc.)
- **Python3-pip**: Python package manager
- **Net-tools**: Network utilities
- **Nmap**: Network exploration tool
- **Unzip**: Archive extraction utility

### Lightweight Tools (Tag: `light`)

- **Zsh & Oh-My-Zsh**: Modern shell with plugin framework
  - Zsh-autosuggestions plugin for command completion
  - Custom aliases and functions
- **Powerlevel10k**: Feature-rich Zsh theme
- **Tmux**: Terminal multiplexer with TPM (Tmux Plugin Manager)
- **Neovim v0.9.5**: Modern text editor
  - Architecture-aware installation (x86_64 and ARM64)
- **LunarVim**: IDE layer for Neovim
  - Uses release-1.3 branch for Neovim 0.9 compatibility
  - Custom configuration with Tailwind CSS support
- **Bat**: Enhanced `cat` with syntax highlighting
- **Zoxide**: Smarter `cd` command with directory jumping
- **Fzf**: Fuzzy finder for command-line
- **Expect**: Automation tool for interactive applications
- **Wget**: Network downloader
- **Pfetch**: System information display
- **Lazydocker**: Docker management TUI
- **Lazygit**: Git management TUI

### Heavy Tools (Tag: `heavy`)

- **Docker.io**: Container platform
- **NPM**: Node.js package manager
- **Rust/Cargo**: Rust programming language and package manager

## Directory Structure

```
koby-dev-env/
├── deploy.yml              # Main Ansible playbook
├── deploy-local.sh         # Local deployment script
├── ansible.cfg             # Ansible configuration
├── configs/                # Configuration files
│   ├── zshrc              # Zsh configuration
│   ├── p10k.zsh           # Powerlevel10k theme
│   ├── tmux.conf          # Tmux configuration
│   ├── LVIMconfig.lua     # LunarVim configuration
│   └── lua/koby/          # LunarVim Lua modules
├── creds/                  # Vault credentials (gitignored)
│   └── example-format.yml # Credential template
├── hosts/                  # Inventory files for remote hosts
├── env/                    # Environment-specific configs
├── util/                   # Utility scripts
│   ├── misc/              # Miscellaneous utilities
│   └── ssh/               # SSH-related utilities
└── README.md              # This file
```

## Tags System

The playbook uses Ansible tags to control which components are installed:

### Available Tags

| Tag | Description | Tools Included |
|-----|-------------|----------------|
| `always` | Always run (prerequisites) | Git, Curl, Build tools |
| `light` | Lightweight tools | Zsh, Tmux, Neovim, LunarVim, CLI utilities |
| `heavy` | Resource-intensive tools | Docker, NPM, Cargo |
| `zsh` | Zsh shell only | Zsh, Oh-My-Zsh, plugins |
| `p10k` | Powerlevel10k theme | Theme installation and config |
| `tmux` | Tmux only | Tmux and TPM |
| `neovim` | Neovim editor | Neovim v0.9.5 |
| `lunarvim`, `lvim` | LunarVim IDE | LunarVim and configurations |
| `docker` | Docker only | Docker.io |
| `npm` | NPM only | Node.js package manager |
| `cargo` | Rust/Cargo only | Rust toolchain |

### Tag Usage Examples

```bash
# Install everything
ansible-playbook deploy.yml -i localhost, --connection=local

# Install only lightweight tools
ansible-playbook deploy.yml -i localhost, --connection=local --tags "light"

# Install Zsh and Tmux only
ansible-playbook deploy.yml -i localhost, --connection=local --tags "zsh,tmux"

# Install everything except Docker and NPM
ansible-playbook deploy.yml -i localhost, --connection=local --skip-tags "docker,npm"

# Sync repository and update (normally skipped)
ansible-playbook deploy.yml -i localhost, --connection=local --tags "sync"
```

## Customization

### Adding Machine-Specific Configuration

1. Copy the example template:
   ```bash
   cp env/zsh-machine-specific.example env/zsh-machine-specific.zshrc
   ```

2. Edit `env/zsh-machine-specific.zshrc` with your custom settings

3. The file will be automatically sourced by the main zshrc configuration

### Remote Host Setup

1. Create an inventory file in `hosts/`:
   ```ini
   [servers]
   myserver ansible_host=192.168.1.100 ansible_user=myuser
   ```

2. Create a vault file in `creds/` with credentials:
   ```yaml
   vault_ansible_user: myuser
   vault_sudo_pass: mysudopassword
   ```

3. Encrypt the vault file:
   ```bash
   ansible-vault encrypt creds/myserver-creds.yml
   ```

## Troubleshooting

### Common Issues

1. **Neovim Installation Fails**
   - The playbook automatically detects architecture (x86_64 vs ARM64)
   - For ARM systems, it uses AppImage from matsuu/neovim-aarch64-appimage
   - Check the output with `-vv` flag for detailed error messages

2. **LunarVim Crashes**
   - Ensure Neovim v0.9.5 is installed (LunarVim release-1.3 is used for compatibility)
   - Run `:checkhealth` in Neovim to diagnose issues

3. **Zsh Not Default Shell**
   - Log out and log back in after installation
   - Manually change shell: `chsh -s /bin/zsh`

4. **Tmux Plugins Not Loading**
   - Open tmux and press `Prefix + I` (default: `Ctrl-b` then `I`)
   - This triggers TPM to install plugins

5. **Docker Permission Issues**
   - Run the helper script: `util/misc/setup-docker-permissions.sh`
   - Add user to docker group: `sudo usermod -aG docker $USER`
   - Log out and back in for changes to take effect

### Debug Mode

For verbose output during installation:
```bash
# Increasing levels of verbosity
./deploy-local.sh -v    # Basic verbose
./deploy-local.sh -vv   # More verbose
./deploy-local.sh -vvv  # Debug level
./deploy-local.sh -vvvv # Maximum verbosity
```

## Post-Installation Steps

After successful installation:

1. **Restart your shell** or log out/in for Zsh to become default
2. **Configure Powerlevel10k**: Run `p10k configure` if prompted
3. **Install Tmux plugins**: Start tmux and press `Prefix + I`
4. **Open LunarVim**: Run `lvim` to trigger plugin installation
5. **Docker setup** (if installed): Add yourself to docker group
   ```bash
   sudo usermod -aG docker $USER
   # Log out and back in
   ```

## Contributing

Feel free to submit issues and enhancement requests!

## Author

**Koby W**  
GitHub: [KobyW](https://github.com/KobyW)

## License

This project is open source and available under the [MIT License](LICENSE).
