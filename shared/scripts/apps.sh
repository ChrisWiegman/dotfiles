#!/bin/sh

set -e
trap 'echo "apps.sh failed at line $LINENO" >&2' ERR

# Applies app configs stored in the repo's `apps/` folder.
# $1 = path to the dotfiles root (parent of `shared`).
DOTFILES_ROOT="$1"
APPS_DIR="$DOTFILES_ROOT/apps"

echo "Setting up application configs"

# Symlink a repo file into place, replacing whatever is there. Backs up a real
# (non-symlink) file once so nothing is lost the first time we take ownership.
link_config() {
    src="$1"
    dest="$2"

    [ -e "$src" ] || { echo "  skip (missing in repo): $src"; return 0; }

    mkdir -p "$(dirname "$dest")"

    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        mv "$dest" "$dest.pre-dotfiles"
        echo "  backed up existing $(basename "$dest") -> $(basename "$dest").pre-dotfiles"
    fi

    rm -f "$dest"
    ln -s "$src" "$dest"
}

# ---- VS Code ----
VSCODE_USER="$HOME/Library/Application Support/Code/User"
link_config "$APPS_DIR/VS Code/settings.json" "$VSCODE_USER/settings.json"
link_config "$APPS_DIR/VS Code/keybindings.json" "$VSCODE_USER/keybindings.json"

# ---- Terminal.app theme ----
# Import the profile (if not already known to Terminal) and make it the default.
TERMINAL_PROFILE="Kana Dark"
TERMINAL_FILE="$APPS_DIR/Terminal/$TERMINAL_PROFILE.terminal"
if [ -f "$TERMINAL_FILE" ]; then
    if ! /usr/libexec/PlistBuddy -c "Print :'Window Settings':'$TERMINAL_PROFILE'" \
        "$HOME/Library/Preferences/com.apple.Terminal.plist" > /dev/null 2>&1; then
        echo "  importing Terminal profile '$TERMINAL_PROFILE'"
        open "$TERMINAL_FILE"
        # Give Terminal a moment to register the imported profile.
        sleep 1
    fi
    defaults write com.apple.Terminal "Default Window Settings" -string "$TERMINAL_PROFILE"
    defaults write com.apple.Terminal "Startup Window Settings" -string "$TERMINAL_PROFILE"
fi
