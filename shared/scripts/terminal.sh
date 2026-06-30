#!/bin/sh

set -e
trap 'echo "terminal.sh failed at line $LINENO" >&2' ERR

# Sets up the Terminal.app theme stored in the repo's `apps/` folder. This is
# opt-in: call it from a machine's setup.sh only on computers that use
# Terminal.app, e.g.
#   sh "$SHAREDPATH/scripts/terminal.sh" "$(dirname "$SHAREDPATH")"
# $1 = path to the dotfiles root (parent of `shared`).
DOTFILES_ROOT="$1"
APPS_DIR="$DOTFILES_ROOT/apps"

echo "Setting up Terminal.app theme"

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
