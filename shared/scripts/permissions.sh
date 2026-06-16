#!/bin/sh

set -e
trap 'echo "permissions.sh failed at line $LINENO" >&2' ERR

# macOS guards Full Disk Access and App Management behind TCC. There is no
# supported way to grant these from a script — Apple requires the user to toggle
# them in System Settings. What we can do is detect what's missing, jump straight
# to the right pane, and pause until the user has granted it.
#
# This setup is always run from Apple's Terminal app, so the permissions attach to
# Terminal. Full Disk Access usually only takes effect after Terminal is quit and
# reopened.
TERM_APP="Terminal"

# Prompts read from the real terminal even when this script is piped through `sh`.
prompt() {
    printf '%s' "$1" > /dev/tty
    read -r REPLY < /dev/tty || REPLY=""
}

# Reading the user TCC database requires Full Disk Access, so it's a reliable probe.
has_full_disk_access() {
    dd if="$HOME/Library/Application Support/com.apple.TCC/TCC.db" \
        bs=1 count=1 of=/dev/null 2>/dev/null
}

echo "Checking macOS privacy permissions"

# ---- Full Disk Access ----
if has_full_disk_access; then
    echo "  Full Disk Access: already granted"
else
    while ! has_full_disk_access; do
        echo
        echo "  Full Disk Access is NOT granted to $TERM_APP."
        echo "  Opening Settings > Privacy & Security > Full Disk Access."
        echo "  Add and enable $TERM_APP there, then QUIT and REOPEN it."
        open "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles" || true
        prompt "  Press Return to re-check, or type 's' then Return to skip: "
        case "$REPLY" in
            s|S)
                echo "  Skipping Full Disk Access. Some steps may not work until it's granted."
                break
                ;;
        esac
        if ! has_full_disk_access; then
            echo "  Still not detected — this usually means $TERM_APP needs a restart."
            echo "  Grant it, then quit/reopen $TERM_APP and re-run setup."
        fi
    done
    has_full_disk_access && echo "  Full Disk Access: granted"
fi

# ---- App Management ----
# There's no reliable read probe for App Management, so we deep-link and confirm.
# Homebrew casks that update apps already in /Applications need this.
echo
echo "  App Management lets Homebrew update apps already in /Applications."
echo "  Opening Settings > Privacy & Security > App Management."
echo "  Add and enable $TERM_APP if it isn't already."
open "x-apple.systempreferences:com.apple.preference.security?Privacy_AppBundles" || true
prompt "  Press Return once you've reviewed App Management: "
