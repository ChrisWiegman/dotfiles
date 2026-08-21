#!/bin/sh

set -e
trap 'echo "touchid.sh failed at line $LINENO" >&2' ERR

# Enable Touch ID for sudo. macOS ships /etc/pam.d/sudo_local.template and
# /etc/pam.d/sudo already includes sudo_local, so writing it this way survives OS
# updates, unlike editing /etc/pam.d/sudo directly.
#
# tmux (used on every machine here) detaches sudo's calling process from the Aqua
# session pam_tid.so checks against, so Touch ID silently falls back to a password
# prompt inside tmux. pam-reattach re-associates the two, so it must run first.
[ -f /etc/pam.d/sudo_local.template ] || exit 0

REATTACH_LIB=""
if command -v brew > /dev/null 2>&1 && brew list pam-reattach > /dev/null 2>&1; then
    REATTACH_LIB="$(brew --prefix pam-reattach)/lib/pam/pam_reattach.so"
fi

TMP="$(mktemp)"
sed 's/^#auth/auth/' /etc/pam.d/sudo_local.template > "$TMP"
if [ -n "$REATTACH_LIB" ]; then
    sed -i '' "/pam_tid\.so/i\\
auth       optional       $REATTACH_LIB
" "$TMP"
fi

if ! diff -q "$TMP" /etc/pam.d/sudo_local > /dev/null 2>&1; then
    echo "Enabling Touch ID for sudo..."
    sudo cp "$TMP" /etc/pam.d/sudo_local
    sudo chmod 644 /etc/pam.d/sudo_local
fi
rm -f "$TMP"
