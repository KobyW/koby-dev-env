#!/usr/bin/env bash

###                                                                    ###
#                                                                        #
# BACK UP AND REMOVE AN EXISTING LUNARVIM INSTALLATION                   #
#                                                                        #
# Idempotent: exits 0 with "nothing to do" when LunarVim is not present, #
# so deploy.yml can run it on every deploy safely.                       #
# Portable: works on Linux and macOS (bash 3.2 compatible).              #
#                                                                        #
# Usage: decommission-lunarvim.sh [--dry-run]                            #
#                                                                        #
###                                                                    ###

set -eo pipefail

DRY_RUN=0
if [ "${1:-}" = "--dry-run" ]; then
    DRY_RUN=1
    echo "[dry-run] No changes will be made."
fi

LVIM_PATHS="
.local/bin/lvim
.config/lvim
.local/share/lunarvim
.local/share/lvim
.cache/lvim
.local/state/lvim
"

# Collect the paths (relative to $HOME) that actually exist
found=""
for rel in $LVIM_PATHS; do
    if [ -e "$HOME/$rel" ] || [ -L "$HOME/$rel" ]; then
        found="$found $rel"
    fi
done

if [ -z "$found" ]; then
    echo "LunarVim not found - nothing to do."
    exit 0
fi

echo "Found LunarVim components:"
for rel in $found; do
    echo "  ~/$rel"
done

BACKUP_DIR="$HOME/.dotfile-backups"
STAMP="$(date +%Y%m%d-%H%M%S)"
ARCHIVE="$BACKUP_DIR/lunarvim-backup-$STAMP.tar.gz"

if [ "$DRY_RUN" -eq 1 ]; then
    echo "[dry-run] Would archive the above to $ARCHIVE and then remove them."
    exit 0
fi

mkdir -p "$BACKUP_DIR"
# shellcheck disable=SC2086 # word splitting of $found is intentional
tar czf "$ARCHIVE" -C "$HOME" $found
echo "Backup written: $ARCHIVE"

for rel in $found; do
    rm -rf "${HOME:?}/$rel"
    echo "Removed: ~/$rel"
done

echo "LunarVim decommissioned. Restore any time with:"
echo "  tar xzf $ARCHIVE -C \$HOME"
