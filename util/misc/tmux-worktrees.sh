#!/bin/bash
# tmux-worktrees.sh - Create tmux session with windows for each subdirectory
#
# Layout per window:
# ┌─────────────────────────┐
# │      Top pane           │
# ├───────────┬─────────────┤
# │ Bottom    │ Bottom Right│
# │ Left      │ (lazygit)   │
# └───────────┴─────────────┘

set -e

# Defaults
SESSION_NAME="worktrees"
SESSION_NAME_SET=false  # Track if user explicitly set the name
BASE_DIR="$(pwd)"
TOP_CMD=""
BOTTOM_LEFT_CMD=""
BOTTOM_RIGHT_CMD="lazygit"
DRY_RUN=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Create a tmux session with windows for each subdirectory.

OPTIONS:
    -s, --session NAME      Session name (exits if taken; without -s: defaults to
                            'worktrees' with fallback to basename of pwd)
    -d, --base-dir DIR      Base directory to scan for subdirectories (default: pwd)
    -t, --top-cmd CMD       Command to run in top pane (default: none)
    -l, --bottom-left CMD   Command to run in bottom-left pane (default: none)
    -r, --bottom-right CMD  Command to run in bottom-right pane (default: lazygit)
    -n, --dry-run           Show what would be done without executing
    -h, --help              Show this help message

EXAMPLES:
    $(basename "$0")
    $(basename "$0") --top-cmd "nvim ." --bottom-left "npm run dev"
    $(basename "$0") -d ~/projects -s myprojects --dry-run
EOF
    exit 0
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_dry() {
    echo -e "${YELLOW}[DRY-RUN]${NC} $1"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--session)
            SESSION_NAME="$2"
            SESSION_NAME_SET=true
            shift 2
            ;;
        -d|--base-dir)
            BASE_DIR="$2"
            shift 2
            ;;
        -t|--top-cmd)
            TOP_CMD="$2"
            shift 2
            ;;
        -l|--bottom-left)
            BOTTOM_LEFT_CMD="$2"
            shift 2
            ;;
        -r|--bottom-right)
            BOTTOM_RIGHT_CMD="$2"
            shift 2
            ;;
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Resolve base directory to absolute path
BASE_DIR="$(cd "$BASE_DIR" && pwd)"

# Get list of non-hidden directories
mapfile -t DIRS < <(find "$BASE_DIR" -maxdepth 1 -mindepth 1 -type d ! -name '.*' | sort)

# Check if any directories exist
if [[ ${#DIRS[@]} -eq 0 ]]; then
    log_error "No directories found in $BASE_DIR"
    exit 1
fi

log_info "Found ${#DIRS[@]} directories in $BASE_DIR"

# Check if session name is taken
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    if [[ "$SESSION_NAME_SET" == true ]]; then
        # User explicitly specified this name - exit with error
        log_error "Session '$SESSION_NAME' already exists."
        exit 1
    fi

    # Default name taken - try fallback
    FALLBACK_NAME="$(basename "$BASE_DIR")"
    log_warn "Session '$SESSION_NAME' already exists, trying '$FALLBACK_NAME'"

    if tmux has-session -t "$FALLBACK_NAME" 2>/dev/null; then
        log_error "Session '$FALLBACK_NAME' also exists. Please close existing sessions or use -s to specify a different name."
        exit 1
    fi
    SESSION_NAME="$FALLBACK_NAME"
fi

log_info "Session name: $SESSION_NAME"

# Show configuration
echo ""
echo "Configuration:"
echo "  Session:      $SESSION_NAME"
echo "  Base dir:     $BASE_DIR"
echo "  Top cmd:      ${TOP_CMD:-<none>}"
echo "  Bottom-left:  ${BOTTOM_LEFT_CMD:-<none>}"
echo "  Bottom-right: ${BOTTOM_RIGHT_CMD:-<none>}"
echo ""
echo "Windows to create:"
for dir in "${DIRS[@]}"; do
    echo "  - $(basename "$dir")"
done
echo ""

# Dry run - just show what would happen
if [[ "$DRY_RUN" == true ]]; then
    log_dry "Would create tmux session '$SESSION_NAME'"
    for dir in "${DIRS[@]}"; do
        dir_name="$(basename "$dir")"
        log_dry "  Window '$dir_name' in $dir"
        log_dry "    Top pane: ${TOP_CMD:-shell}"
        log_dry "    Bottom-left: ${BOTTOM_LEFT_CMD:-shell}"
        log_dry "    Bottom-right: ${BOTTOM_RIGHT_CMD:-shell}"
    done
    exit 0
fi

# Get tmux base indices (respect user's config)
PANE_BASE=$(tmux show-options -gv pane-base-index 2>/dev/null || echo 0)
WINDOW_BASE=$(tmux show-options -gv base-index 2>/dev/null || echo 0)

# Create the session with first directory
FIRST_DIR="${DIRS[0]}"
FIRST_NAME="$(basename "$FIRST_DIR")"

log_info "Creating session with first window: $FIRST_NAME"
tmux new-session -d -s "$SESSION_NAME" -n "$FIRST_NAME" -c "$FIRST_DIR"

# Function to setup panes in current window
setup_panes() {
    local dir="$1"
    local window="$2"

    # Calculate pane indices based on configured base
    local pane_top=$PANE_BASE
    local pane_bl=$((PANE_BASE + 1))
    local pane_br=$((PANE_BASE + 2))

    # Split horizontally (creates bottom pane)
    tmux split-window -t "$SESSION_NAME:$window" -v -c "$dir"

    # Split bottom pane vertically (creates bottom-right)
    tmux split-window -t "$SESSION_NAME:$window.$pane_bl" -h -c "$dir"

    # Run commands if specified
    # pane_top = top, pane_bl = bottom-left, pane_br = bottom-right

    if [[ -n "$TOP_CMD" ]]; then
        tmux send-keys -t "$SESSION_NAME:$window.$pane_top" "$TOP_CMD" Enter
    fi

    if [[ -n "$BOTTOM_LEFT_CMD" ]]; then
        tmux send-keys -t "$SESSION_NAME:$window.$pane_bl" "$BOTTOM_LEFT_CMD" Enter
    fi

    if [[ -n "$BOTTOM_RIGHT_CMD" ]]; then
        tmux send-keys -t "$SESSION_NAME:$window.$pane_br" "$BOTTOM_RIGHT_CMD" Enter
    fi

    # Select top pane as active
    tmux select-pane -t "$SESSION_NAME:$window.$pane_top"
}

# Setup panes for first window
setup_panes "$FIRST_DIR" "$FIRST_NAME"
log_success "Created window: $FIRST_NAME"

# Create remaining windows
for ((i = 1; i < ${#DIRS[@]}; i++)); do
    dir="${DIRS[$i]}"
    dir_name="$(basename "$dir")"

    tmux new-window -t "$SESSION_NAME" -n "$dir_name" -c "$dir"
    setup_panes "$dir" "$dir_name"
    log_success "Created window: $dir_name"
done

# Select first window
tmux select-window -t "$SESSION_NAME:$WINDOW_BASE"

log_success "Session '$SESSION_NAME' created with ${#DIRS[@]} windows"
echo ""

# Prompt to attach
read -p "Attach to session? [Y/n] " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Nn]$ ]]; then
    log_info "Session created in background. Attach with: tmux attach -t $SESSION_NAME"
else
    exec tmux attach -t "$SESSION_NAME"
fi
