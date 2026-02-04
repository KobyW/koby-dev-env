#!/usr/bin/env bash

# === ICON PLACEHOLDERS - Replace these with your preferred icons ===
FOLDER_ICON=""   # e.g., , 📁, or leave empty
GIT_ICON=""         # e.g., , 🌿, or leave empty  
CLOCK_ICON=""     # e.g., , 🕐, or leave empty

# Read JSON input from stdin
input=$(cat)

# Extract user@host:directory
user=$(whoami)
host=$(hostname -s)
dir=$(basename "$(pwd)")

# Extract context window data and calculate percentage
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

if [ -n "$used_pct" ]; then
  percentage=$(printf "%.0f" "$used_pct")
else
  used=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
  max=$(echo "$input" | jq -r '.context_window.context_window_size // 0')
  
  if [ "$max" -gt 0 ]; then
    percentage=$(awk "BEGIN {printf \"%.0f\", ($used / $max) * 100}")
  else
    percentage="0"
  fi
fi

# Color codes
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RED=$'\033[31m'
BLUE=$'\033[34m'
LIGHT_BLUE=$'\033[94m'
PURPLE=$'\033[35m'
RESET=$'\033[0m'
DIM=$'\033[2m'

# Git branch and status
git_section=""
if git rev-parse --git-dir > /dev/null 2>&1; then
  git_branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
  
  if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    git_status="●"
    status_color="$YELLOW"
  else
    git_status="✓"
    status_color="$GREEN"
  fi
  
  git_section=" | ${GREEN}${GIT_ICON} ${git_branch}${RESET} ${status_color}${git_status}${RESET}"
fi

# Determine color based on percentage
if [ "$percentage" -le 40 ]; then
  pct_color="$GREEN"
elif [ "$percentage" -le 70 ]; then
  pct_color="$YELLOW"
else
  pct_color="$RED"
fi

# Get current time in HH:MM format
current_time=$(date +%H:%M)

# Output the status line using echo -e for proper escape code handling
echo -n "${BLUE}${FOLDER_ICON} ${user}@${host}${RESET}${DIM}:${RESET}${LIGHT_BLUE}${dir}${RESET}${git_section}${DIM} | ${RESET}${pct_color}${percentage}%${RESET}${DIM} | ${RESET}${DIM}${current_time} ${CLOCK_ICON}${RESET}"
