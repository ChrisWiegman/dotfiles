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
        "$HOME/Library/Preferences/com.apple.Terminal.plist" >/dev/null 2>&1; then
        echo "  importing Terminal profile '$TERMINAL_PROFILE'"
        open "$TERMINAL_FILE"
        # Give Terminal a moment to register the imported profile.
        sleep 1
    fi
    # Option as Meta, so tmux's Option bindings (M-j / M-k) reach tmux instead of
    # typing ∆ and ˚. The profile is only imported once, so also set it on a
    # profile that's already there. Writes go through `defaults` so the rest of
    # the profile (colors, fonts) is kept as is.
    if [ "$(/usr/libexec/PlistBuddy -c "Print :'Window Settings':'$TERMINAL_PROFILE':useOptionAsMetaKey" \
        "$HOME/Library/Preferences/com.apple.Terminal.plist" 2>/dev/null)" != "true" ]; then
        PROFILE_XML="$(defaults export com.apple.Terminal - |
            plutil -extract "Window Settings.$TERMINAL_PROFILE" xml1 -o - - |
            plutil -replace useOptionAsMetaKey -bool YES -o - -)"
        if [ -n "$PROFILE_XML" ]; then
            defaults write com.apple.Terminal "Window Settings" -dict-add "$TERMINAL_PROFILE" "$PROFILE_XML"
            echo "  turned on Option as Meta key (restart Terminal to use it)"
        fi
    fi

    defaults write com.apple.Terminal "Default Window Settings" -string "$TERMINAL_PROFILE"
    defaults write com.apple.Terminal "Startup Window Settings" -string "$TERMINAL_PROFILE"
fi
