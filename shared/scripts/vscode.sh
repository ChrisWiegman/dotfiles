#!/bin/sh

set -e
trap 'echo "vscode.sh failed at line $LINENO" >&2' ERR

# Links VS Code configs stored in the repo's `apps/` folder. This is opt-in:
# call it from a machine's setup.sh only on computers that use VS Code, e.g.
#   sh "$SHAREDPATH/scripts/vscode.sh" "$(dirname "$SHAREDPATH")"
# $1 = path to the dotfiles root (parent of `shared`).
DOTFILES_ROOT="$1"
APPS_DIR="$DOTFILES_ROOT/apps"

. "$DOTFILES_ROOT/shared/scripts/lib.sh"

echo "Setting up VS Code configs"

VSCODE_USER="$HOME/Library/Application Support/Code/User"
link_config "$APPS_DIR/VS Code/settings.json" "$VSCODE_USER/settings.json"
link_config "$APPS_DIR/VS Code/keybindings.json" "$VSCODE_USER/keybindings.json"
