#!/bin/sh

set -e
trap 'echo "security.sh failed at line $LINENO" >&2' ERR

# Baseline macOS security settings for every machine.

. "$(dirname "$0")/lib.sh"

echo "Checking macOS security settings"

FW=/usr/libexec/ApplicationFirewall/socketfilterfw

# Firewall on, and stealth mode so the Mac doesn't answer pings or probes
# of closed ports.
if ! "$FW" --getglobalstate | grep -q 'State = 1'; then
    echo "  turning on the firewall"
    sudo "$FW" --setglobalstate on > /dev/null || warn "Couldn't turn on the firewall. Enable it in System Settings > Network > Firewall."
fi
if ! "$FW" --getstealthmode | grep -q 'stealth mode is on'; then
    echo "  turning on firewall stealth mode"
    sudo "$FW" --setstealthmode on > /dev/null || warn "Couldn't turn on firewall stealth mode. Enable it in System Settings > Network > Firewall > Options."
fi

# FileVault normally gets turned on in Setup Assistant. Enabling it here would
# mean handling the recovery key in a script, so just flag it if it's off.
if ! fdesetup status | grep -q 'FileVault is On'; then
    warn "FileVault is off. Turn it on in System Settings > Privacy & Security > FileVault, and keep the recovery key somewhere safe."
fi

# The rest are on by default and each needs a person (a confirmation dialog,
# a password, or Recovery mode) to change, so only flag them if they're off.
if ! spctl --status 2>/dev/null | grep -q 'assessments enabled'; then
    warn "Gatekeeper is off. Turn it back on with: sudo spctl --global-enable"
fi

if ! csrutil status 2>/dev/null | grep -q 'enabled\.$'; then
    warn "System Integrity Protection is off. Turn it back on from Recovery mode with: csrutil enable"
fi

# sysadminctl prints its answer on stderr, e.g. "screenLock delay is immediate".
if sysadminctl -screenLock status 2>&1 | grep -q 'screenLock is off'; then
    warn "The screen doesn't lock with a password. Set it in System Settings > Lock Screen > Require password after screen saver begins."
fi

# Only an explicit 0 means off: a fresh Mac may not have written these yet.
updates_off=""
for key in AutomaticCheckEnabled AutomaticDownload AutomaticallyInstallMacOSUpdates \
    CriticalUpdateInstall ConfigDataInstall; do
    if [ "$(defaults read /Library/Preferences/com.apple.SoftwareUpdate "$key" 2>/dev/null)" = "0" ]; then
        updates_off="$updates_off $key"
    fi
done
if [ "$(defaults read /Library/Preferences/com.apple.commerce AutoUpdate 2>/dev/null)" = "0" ]; then
    updates_off="$updates_off AppStoreAutoUpdate"
fi
if [ -n "$updates_off" ]; then
    warn "Some automatic updates are off ($(echo "$updates_off" | sed 's/^ //')). Turn them on in System Settings > General > Software Update > Automatic Updates."
fi
