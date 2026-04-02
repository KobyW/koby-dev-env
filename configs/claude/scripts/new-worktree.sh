#!/bin/bash
# new-worktree.sh - Create a git worktree with a full tmux dev environment
#
# Layout per window (2x2):
# ┌──────────────────┬──────────────────┐
# │  cdsp / claude   │    lazygit       │
# │  (or shell)      │    (or shell)    │
# ├──────────────────┼──────────────────┤
# │  pnpm dev        │  npx convex dev  │
# │  -H 0.0.0.0     │  (or shell)      │
# │  -p <port>       │                  │
# └──────────────────┴──────────────────┘

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
log_dry()     { echo -e "${YELLOW}[DRY-RUN]${NC} $1"; }

# Defaults
SESSION_NAME="worktrees"
DRY_RUN=false
SOURCE_DIR=""
WORKTREE_NAME=""

usage() {
    cat << EOF
Usage: $(basename "$0") <name> [source-dir] [OPTIONS]

Create a git worktree with a full tmux dev environment.

ARGUMENTS:
    name                Worktree/branch name (required)
    source-dir          Source repo directory (default: pwd)

OPTIONS:
    --dry-run, -n       Preview without executing
    --help, -h          Show this help message

EXAMPLES:
    $(basename "$0") fix-auth-bug
    $(basename "$0") fix-auth-bug /home/user/my-project
    $(basename "$0") fix-auth-bug . --dry-run
EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        -*)
            log_error "Unknown option: $1"
            usage
            ;;
        *)
            if [[ -z "$WORKTREE_NAME" ]]; then
                WORKTREE_NAME="$1"
            elif [[ -z "$SOURCE_DIR" ]]; then
                SOURCE_DIR="$1"
            else
                log_error "Unexpected argument: $1"
                usage
            fi
            shift
            ;;
    esac
done

# Validate name
if [[ -z "$WORKTREE_NAME" ]]; then
    log_error "Worktree name is required"
    usage
fi

# Resolve source directory
if [[ -z "$SOURCE_DIR" ]]; then
    SOURCE_DIR="$(pwd)"
else
    SOURCE_DIR="$(cd "$SOURCE_DIR" && pwd)"
fi

# Validate source is a git repo
if ! git -C "$SOURCE_DIR" rev-parse --is-inside-work-tree &>/dev/null; then
    log_error "$SOURCE_DIR is not a git repository"
    exit 1
fi

# Resolve git root and worktree path
GIT_ROOT="$(git -C "$SOURCE_DIR" rev-parse --show-toplevel)"
REPO_PARENT="$(dirname "$GIT_ROOT")"
WORKTREE_PATH="$REPO_PARENT/$WORKTREE_NAME"

# Check if worktree path already exists
if [[ -d "$WORKTREE_PATH" ]]; then
    log_error "Directory already exists: $WORKTREE_PATH"
    exit 1
fi

# --- Detect project configuration ---

# Detect package manager
detect_pkg_manager() {
    if [[ -f "$GIT_ROOT/pnpm-lock.yaml" ]]; then
        echo "pnpm"
    elif [[ -f "$GIT_ROOT/yarn.lock" ]]; then
        echo "yarn"
    elif [[ -f "$GIT_ROOT/package-lock.json" ]]; then
        echo "npm"
    elif [[ -f "$GIT_ROOT/package.json" ]]; then
        echo "pnpm"  # default fallback
    else
        echo ""
    fi
}

# Detect base dev port from package.json
detect_base_port() {
    local pkg="$GIT_ROOT/package.json"
    if [[ ! -f "$pkg" ]]; then
        echo "3000"
        return
    fi

    # Try to extract port from dev script
    local dev_script
    dev_script=$(grep -oP '"dev"\s*:\s*"[^"]*"' "$pkg" 2>/dev/null | head -1)

    # Look for --port or -p flag
    local port
    port=$(echo "$dev_script" | grep -oP '(?:--port|-p)\s+(\d+)' | grep -oP '\d+' | head -1)

    if [[ -n "$port" ]]; then
        echo "$port"
    else
        echo "3000"
    fi
}

# Find a free port starting from base
find_free_port() {
    local port="$1"
    local max_attempts=20

    for ((i = 0; i < max_attempts; i++)); do
        if ! lsof -i ":$port" &>/dev/null 2>&1 && ! ss -tlnp 2>/dev/null | grep -q ":$port "; then
            echo "$port"
            return
        fi
        ((port++))
    done

    # Fallback: return the incremented port and hope for the best
    echo "$port"
}

# Detect if convex is used
has_convex() {
    [[ -d "$GIT_ROOT/convex" ]]
}

# Detect available commands
has_cmd() {
    command -v "$1" &>/dev/null
}

PKG_MANAGER=$(detect_pkg_manager)
BASE_PORT=$(detect_base_port)
FREE_PORT=$(find_free_port "$BASE_PORT")

# Build pane commands
build_dev_cmd() {
    if [[ -z "$PKG_MANAGER" ]]; then
        echo ""
        return
    fi
    echo "$PKG_MANAGER dev --hostname 0.0.0.0 --port $FREE_PORT"
}

build_secondary_cmd() {
    if has_convex; then
        echo "npx convex dev"
    else
        echo ""
    fi
}

build_claude_cmd() {
    if has_cmd cdsp; then
        echo "cdsp"
    elif has_cmd claude; then
        echo "claude"
    else
        echo ""
    fi
}

build_lazygit_cmd() {
    if has_cmd lazygit; then
        echo "lazygit"
    else
        echo ""
    fi
}

CMD_TOP_LEFT=$(build_claude_cmd)
CMD_TOP_RIGHT=$(build_lazygit_cmd)
CMD_BOTTOM_LEFT=$(build_dev_cmd)
CMD_BOTTOM_RIGHT=$(build_secondary_cmd)

# --- Show configuration ---

echo ""
echo "Configuration:"
echo "  Source repo:    $GIT_ROOT"
echo "  Worktree path:  $WORKTREE_PATH"
echo "  Branch:         $WORKTREE_NAME"
echo "  Package manager: ${PKG_MANAGER:-none}"
echo "  Dev port:       $FREE_PORT (base: $BASE_PORT)"
echo "  Has Convex:     $(has_convex && echo 'yes' || echo 'no')"
echo ""
echo "Pane layout:"
echo "  ┌──────────────────────────┬──────────────────────────┐"
printf "  │ %-24s │ %-24s │\n" "${CMD_TOP_LEFT:-shell}" "${CMD_TOP_RIGHT:-shell}"
echo "  ├──────────────────────────┼──────────────────────────┤"
printf "  │ %-24s │ %-24s │\n" "${CMD_BOTTOM_LEFT:-shell}" "${CMD_BOTTOM_RIGHT:-shell}"
echo "  └──────────────────────────┴──────────────────────────┘"
echo ""

# --- Dry run ---

if [[ "$DRY_RUN" == true ]]; then
    log_dry "Would create worktree at $WORKTREE_PATH"
    log_dry "Would copy env files from $GIT_ROOT"
    log_dry "Would run '$PKG_MANAGER install' in worktree"
    log_dry "Would create/add window '$WORKTREE_NAME' in tmux session '$SESSION_NAME'"
    exit 0
fi

# --- Create worktree ---

log_info "Creating git worktree..."

# Check if branch already exists
if git -C "$GIT_ROOT" show-ref --verify --quiet "refs/heads/$WORKTREE_NAME" 2>/dev/null; then
    log_warn "Branch '$WORKTREE_NAME' already exists, using it"
    git -C "$GIT_ROOT" worktree add "$WORKTREE_PATH" "$WORKTREE_NAME"
else
    git -C "$GIT_ROOT" worktree add -b "$WORKTREE_NAME" "$WORKTREE_PATH"
fi

log_success "Worktree created at $WORKTREE_PATH"

# --- Copy env files ---

log_info "Copying environment files..."

ENV_FILES=(".env.local" ".env" ".env.development.local")
COPIED=0

for env_file in "${ENV_FILES[@]}"; do
    if [[ -f "$GIT_ROOT/$env_file" ]]; then
        cp "$GIT_ROOT/$env_file" "$WORKTREE_PATH/$env_file"
        log_success "Copied $env_file"
        ((COPIED++)) || true
    fi
done

if [[ $COPIED -eq 0 ]]; then
    log_warn "No env files found to copy"
fi

# --- Install dependencies ---

if [[ -n "$PKG_MANAGER" ]]; then
    log_info "Installing dependencies with $PKG_MANAGER..."
    (cd "$WORKTREE_PATH" && $PKG_MANAGER install) || log_warn "$PKG_MANAGER install exited with warnings (non-zero), continuing..."
    log_success "Dependencies installed"
else
    log_warn "No package manager detected, skipping install"
fi

# --- Tmux setup ---

log_info "Setting up tmux environment..."

# Get tmux base indices (respect user's config)
PANE_BASE=$(tmux show-options -gv pane-base-index 2>/dev/null || echo 0)
WINDOW_BASE=$(tmux show-options -gv base-index 2>/dev/null || echo 0)

# Create session or add window
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    log_info "Adding window to existing session '$SESSION_NAME'"
    tmux new-window -t "$SESSION_NAME" -n "$WORKTREE_NAME" -c "$WORKTREE_PATH"
else
    log_info "Creating new tmux session '$SESSION_NAME'"
    tmux new-session -d -s "$SESSION_NAME" -n "$WORKTREE_NAME" -c "$WORKTREE_PATH"
fi

# Setup 2x2 pane layout
setup_panes() {
    local dir="$1"
    local window="$2"
    local target="$SESSION_NAME:$window"
    local pb=$PANE_BASE

    # Starting state: 1 pane (index $pb) = full window
    #
    # Step 1: split horizontally → left | right
    #   pane $pb = left,  pane $((pb+1)) = right
    tmux split-window -t "$target.$pb" -h -c "$dir"

    # Step 2: split left pane vertically → top-left / bottom-left
    #   pane $pb = top-left,  pane $((pb+1)) = bottom-left,  pane $((pb+2)) = right (shifted)
    tmux split-window -t "$target.$pb" -v -c "$dir"

    # Step 3: split right pane (now index pb+2) vertically → top-right / bottom-right
    #   pane $pb   = top-left
    #   pane $pb+1 = bottom-left
    #   pane $pb+2 = top-right
    #   pane $pb+3 = bottom-right
    tmux split-window -t "$target.$((pb + 2))" -v -c "$dir"

    # Final layout:
    # ┌────────┬────────┐
    # │ pb+0   │ pb+2   │
    # │ TL     │ TR     │
    # ├────────┼────────┤
    # │ pb+1   │ pb+3   │
    # │ BL     │ BR     │
    # └────────┴────────┘

    # Send commands to each pane
    [[ -n "$CMD_TOP_LEFT" ]]     && tmux send-keys -t "$target.$((pb + 0))" "$CMD_TOP_LEFT" Enter
    [[ -n "$CMD_BOTTOM_LEFT" ]]  && tmux send-keys -t "$target.$((pb + 1))" "$CMD_BOTTOM_LEFT" Enter
    [[ -n "$CMD_TOP_RIGHT" ]]    && tmux send-keys -t "$target.$((pb + 2))" "$CMD_TOP_RIGHT" Enter
    [[ -n "$CMD_BOTTOM_RIGHT" ]] && tmux send-keys -t "$target.$((pb + 3))" "$CMD_BOTTOM_RIGHT" Enter

    # Select top-left pane as active
    tmux select-pane -t "$target.$((pb + 0))"
}

setup_panes "$WORKTREE_PATH" "$WORKTREE_NAME"

log_success "Tmux window '$WORKTREE_NAME' ready in session '$SESSION_NAME'"
echo ""
echo "  Worktree: $WORKTREE_PATH"
echo "  Dev URL:  http://0.0.0.0:$FREE_PORT"
echo ""
echo "  Attach with: tmux attach -t $SESSION_NAME"
