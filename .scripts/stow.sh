#!/usr/bin/env bash

source ./lib/logging.sh
set -euo pipefail

DOTDIR="$HOME/.dotfiles"
STOW_CMD="stow"

if [[ ! -d "$DOTDIR" ]]; then
    error "Directory $DOTDIR does not exist!"
    error "Clone your repo first:"
    error "git clone https://github.com/you/dotfiles $DOTDIR"
    exit 1
fi

log "Found $DOTDIR"
cd "$DOTDIR" || { error "Failed to cd into $DOTDIR"; exit 1; }

mapfile -t ITEMS < <(
    find . -maxdepth 1 \
         -not -path '.' \
         -not -name '.git' \
         -not -name 'README.md'
         -printf '%P\n' | sort
)

(( ${#ITEMS[@]} == 0 )) && {
    warn "Nothing to stow (only .git found)."
    exit 0
}

log "Stowing ${#ITEMS[@]} item(s):"
for i in "${!ITEMS[@]}"; do
    echo "  $((i+1))| ${ITEMS[i]}"
done

for item in "${ITEMS[@]}"; do
    log "Stowing $item ..."
    if stow -v --no-folding "$item" 2>&1; then
        log "Successfully stowed $item"
    else
        error "Failed to stow $item"
        exit 1
    fi
done
