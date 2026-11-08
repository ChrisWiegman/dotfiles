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
