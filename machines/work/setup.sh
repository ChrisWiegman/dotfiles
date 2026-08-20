#!/bin/sh

set -e
trap 'echo "work/setup.sh failed at line $LINENO" >&2' ERR

SHAREDPATH="$1"
MACHINEPATH="$2"

. "$SHAREDPATH/scripts/lib.sh"

M_CONFIG_DIR="$MACHINEPATH/configs"

# Set up SSH configs
if [ ! -d "$HOME/.ssh" ]; then
    mkdir -p "$HOME/.ssh"
fi
chmod 0700 "$HOME/.ssh"

link_config "$M_CONFIG_DIR/.ssh/config" "$HOME/.ssh/config" 0400

# Prefer HTTPS (via the gh CLI credential helper) over SSH for GitHub git
# operations. Commit/tag signing is unaffected either way, since it's handled
# separately by 1Password's ssh-agent signing (gpg.format=ssh in
# shared/configs/.gitconfig), not by the git remote transport.
# Guarded on being logged in already, since a fresh machine hasn't run
# `gh auth login` yet at this point in setup.
if command -v gh >/dev/null 2>&1 && gh auth status -h github.com >/dev/null 2>&1; then
    gh config set -h github.com git_protocol https
    gh auth setup-git
fi

sh "$SHAREDPATH/scripts/vscode.sh" "$(dirname "$SHAREDPATH")"

## Remove extra configs
rm ~/.tmux.conf
