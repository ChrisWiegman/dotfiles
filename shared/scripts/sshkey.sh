#!/bin/sh

set -e
trap 'echo "sshkey.sh failed at line $LINENO" >&2' ERR

# Create a fresh SSH key for this machine instead of copying one over from an
# old machine. Each machine gets its own key, so losing or retiring a machine
# only means deleting that one key from GitHub.
#
# The same key is used for GitHub auth and for git commit signing (the machine's
# gitconfig points user.signingkey at ~/.ssh/id_ed25519.pub). Only machines whose
# gitconfig uses that key get one; the work machine signs via 1Password instead.
#
# This runs early in setup, while someone is at the keyboard, so the key can be
# added to GitHub while the rest of setup runs (the repo clones at the end then
# work over SSH).

MACHINEPATH="$1"
KEY="$HOME/.ssh/id_ed25519"

. "$(dirname "$0")/lib.sh"

grep -q 'id_ed25519' "$MACHINEPATH/configs/.gitconfig" 2>/dev/null || exit 0
[ -f "$KEY" ] && exit 0

# ssh-keygen asks for a passphrase, so this needs a person at a terminal.
if [ ! -t 0 ]; then
    warn "No SSH key at ~/.ssh/id_ed25519 (git commit signing will fail). Re-run setup from Terminal to create one."
    exit 0
fi

EMAIL="$(git config -f "$MACHINEPATH/configs/.gitconfig" user.email || true)"
COMMENT="${EMAIL:-$(whoami)} ($(scutil --get ComputerName 2>/dev/null || hostname -s))"

mkdir -p "$HOME/.ssh"
chmod 0700 "$HOME/.ssh"

echo
echo "Creating a new SSH key for this machine (used for GitHub and commit signing)."
echo "  Choose a passphrase. It's saved in your login Keychain, so you won't"
echo "  have to type it again. (Press Enter twice for no passphrase.)"
ssh-keygen -q -t ed25519 -C "$COMMENT" -f "$KEY"

# Load the key into the agent and save its passphrase in the Keychain. The shell
# config reloads it from the Keychain after a reboot (see .zshrc), so signing a
# commit never stops to ask for the passphrase.
ssh-add -q --apple-use-keychain "$KEY" || true

pbcopy < "$KEY.pub"
open "https://github.com/settings/ssh/new" || true

echo
echo "  Your new public key is on the clipboard and GitHub's 'New SSH key' page is open."
echo "  Add it TWICE: once with Key type 'Authentication Key', and once more"
echo "  as 'Signing Key'. (You can do this while setup keeps running.)"
echo
echo "  Public key (also in ~/.ssh/id_ed25519.pub):"
echo "    $(cat "$KEY.pub")"
echo

warn "New SSH key created. If you haven't yet, add ~/.ssh/id_ed25519.pub to GitHub (https://github.com/settings/keys) as both an Authentication Key and a Signing Key. Remove the old machine's key there too."
