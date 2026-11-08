#!/bin/sh

set -e
trap 'echo "configs.sh failed at line $LINENO" >&2' ERR

SHAREDPATH="$1"
MACHINEPATH="$2"

echo "Setting up shared config files"

# shellcheck source=SCRIPTDIR/lib.sh
. "$SHAREDPATH/scripts/lib.sh"

CONFIG_DIR="$SHAREDPATH/configs"

# Set up SSH config
if [ ! -d "$HOME/.ssh" ]; then
    mkdir -p "$HOME/.ssh"
fi
chmod 0700 "$HOME/.ssh"

link_config "$CONFIG_DIR/.ssh/config" "$HOME/.ssh/config" 0400

# GitHub's pinned host keys, read by the ssh config's github.com block
link_config "$CONFIG_DIR/.ssh/known_hosts.d/github.com" "$HOME/.ssh/known_hosts.d/github.com" 0444

# Set up Tmux configs
link_config "$CONFIG_DIR/.tmux.conf" "$HOME/.tmux.conf"

# Hush the login message
link_config "$CONFIG_DIR/.hushlogin" "$HOME/.hushlogin"

tmux source-file ~/.tmux.conf 2>/dev/null || true

# Setting up machine-specific configs
M_CONFIG_DIR="$MACHINEPATH/configs"

# Setup Mise if it is configured
if [ -f "$M_CONFIG_DIR/.config/mise/config.toml" ]; then
    link_config "$M_CONFIG_DIR/.config/mise/config.toml" "$HOME/.config/mise/config.toml"
    if ! command -v mise >/dev/null 2>&1; then
        warn "mise isn't installed (check the brew bundle output); tools in the mise config were not installed."
    elif ! mise install; then
        warn "mise install failed; open a new shell and run 'r_mise' to retry."
    fi
fi

# Machine-specific SSH settings, pulled in by the shared config's Include.
# Clear out old links first so a file removed from the repo stops applying.
mkdir -p "$HOME/.ssh/config.d"
find "$HOME/.ssh/config.d" -type l -delete
for f in "$M_CONFIG_DIR/.ssh/config.d/"*.conf; do
    [ -f "$f" ] && link_config "$f" "$HOME/.ssh/config.d/$(basename "$f")" 0600
done

# Set up Git configs
if [ ! -f "$HOME/.gitconfig" ] || ! grep -q "signingkey" "$HOME/.gitconfig" 2>/dev/null; then
    link_config "$M_CONFIG_DIR/.gitconfig" "$HOME/.gitconfig"
fi

# Global gitignore (git reads ~/.config/git/ignore on its own)
link_config "$CONFIG_DIR/.config/git/ignore" "$HOME/.config/git/ignore"

# Settings for shellcheck
link_config "$CONFIG_DIR/.config/shellcheckrc" "$HOME/.config/shellcheckrc"

# Let git verify commits signed with this machine's key. Only machines whose
# gitconfig signs with ~/.ssh/id_ed25519 (sshkey.sh creates it earlier in setup);
# work signs through 1Password, which manages its own config.
if grep -q 'id_ed25519' "$M_CONFIG_DIR/.gitconfig" 2>/dev/null && [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
    SIGNER_EMAIL="$(git config -f "$M_CONFIG_DIR/.gitconfig" user.email || true)"
    if [ -n "$SIGNER_EMAIL" ]; then
        mkdir -p "$HOME/.config/git"
        printf '%s namespaces="git" %s\n' "$SIGNER_EMAIL" "$(cat "$HOME/.ssh/id_ed25519.pub")" >|"$HOME/.config/git/allowed_signers"
    fi
fi

# Set up shell config
link_config "$M_CONFIG_DIR/.zshrc" "$HOME/.zshrc" 0600
