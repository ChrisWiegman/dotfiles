#!/bin/sh

set -e
trap 'echo "permissions.sh failed at line $LINENO" >&2' ERR

# macOS guards Full Disk Access and App Management behind TCC; a script can't grant
# them (Apple requires the user to toggle them in System Settings). So we check up
# front: if anything is missing we open the right pane, explain what to enable, and
# stop. Full Disk Access only takes effect after Terminal is restarted, so it's
# cleaner to grant the permissions, reopen Terminal, and run setup again than to
# limp along in a session that can't see them.
#
# This setup is always run from Apple's Terminal app, so the permissions attach to
# Terminal.
#
# Exit status: 0 = all good, continue; 1 = something was missing, stop and re-run.

MACHINE="${1:-<machine>}"
TERM_APP="Terminal"
MARKER_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles"
APPMGMT_MARKER="$MARKER_DIR/app-management-guided"

# Reading the user TCC database requires Full Disk Access, so it's a reliable probe.
has_full_disk_access() {
    dd if="$HOME/Library/Application Support/com.apple.TCC/TCC.db" \
        bs=1 count=1 of=/dev/null 2>/dev/null
}

echo "Checking macOS privacy permissions"

missing=0

# ---- Full Disk Access (detectable) ----
if has_full_disk_access; then
    echo "  Full Disk Access: granted"
else
    echo
    echo "  Full Disk Access is NOT granted to $TERM_APP."
    echo "  -> Opening Privacy & Security > Full Disk Access."
    echo "     Add and enable $TERM_APP."
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles" || true
    missing=1
fi

# ---- App Management (not detectable; guide through it once and remember) ----
if [ -f "$APPMGMT_MARKER" ]; then
    echo "  App Management: already reviewed"
else
    echo
    echo "  App Management lets Homebrew update apps already in /Applications."
    echo "  -> Opening Privacy & Security > App Management."
    echo "     Add and enable $TERM_APP."
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_AppBundles" || true
    mkdir -p "$MARKER_DIR"
    touch "$APPMGMT_MARKER"
    missing=1
fi

if [ "$missing" -ne 0 ]; then
    echo
    echo "  Grant the permission(s) above, then QUIT and REOPEN $TERM_APP."
    echo "  After that, run setup again:"
    echo
    echo "      ./setup.sh $MACHINE"
    echo
    exit 1
fi

echo "  All required permissions are in place."
