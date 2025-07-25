#!/bin/bash

# Claude Init Script
# Based on Claude-Init-PRD.md

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Create CLAUDE.md in the current directory
echo -e "${CYAN}Creating CLAUDE.md in the current directory...${NC}"
cp ~/STD-CLAUDE.md ./CLAUDE.md

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ CLAUDE.md created successfully${NC}"
else
    echo -e "${RED}✗ Failed to create CLAUDE.md${NC}"
    exit 1
fi

# Install MCPs with user confirmation
echo -e "\n${BLUE}=== MCP Installation ===${NC}"

# context7
echo -e "\n${YELLOW}Do you want to install context7 MCP? (yes/y/no/n)${NC}"
read -r response
if [[ "$response" =~ ^([Yy][Ee][Ss]|[Yy])$ ]]; then
    echo -e "${CYAN}Installing context7 MCP...${NC}"
    claude mcp add --transport http context7 https://mcp.context7.com/mcp
    echo -e "${GREEN}✓ context7 MCP installation complete${NC}"
else
    echo -e "${YELLOW}⊘ Skipping context7 MCP${NC}"
fi

# Playwright
echo -e "\n${YELLOW}Do you want to install Playwright MCP? (yes/y/no/n)${NC}"
read -r response
if [[ "$response" =~ ^([Yy][Ee][Ss]|[Yy])$ ]]; then
    echo -e "${CYAN}Installing Playwright MCP...${NC}"
    claude mcp add playwright npx @playwright/mcp@latest
    echo -e "${GREEN}✓ Playwright MCP installation complete${NC}"
else
    echo -e "${YELLOW}⊘ Skipping Playwright MCP${NC}"
fi

# task-master
echo -e "\n${YELLOW}Do you want to install task-master-ai MCP? (yes/y/no/n)${NC}"
read -r response
if [[ "$response" =~ ^([Yy][Ee][Ss]|[Yy])$ ]]; then
    echo -e "${CYAN}Installing task-master-ai MCP...${NC}"
    claude mcp add --scope project taskmaster-ai -- npx -y --package=task-master-ai task-master-ai
    echo -e "${GREEN}✓ task-master-ai MCP installation complete${NC}"
else
    echo -e "${YELLOW}⊘ Skipping task-master-ai MCP${NC}"
fi

echo -e "\n${BLUE}=== Claude initialization complete ===${NC}"