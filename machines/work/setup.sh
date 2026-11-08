#!/bin/sh

set -e
trap 'echo "work/setup.sh failed at line $LINENO" >&2' ERR

SHAREDPATH="$1"

# shellcheck source=SCRIPTDIR/../../shared/scripts/lib.sh
. "$SHAREDPATH/scripts/lib.sh"

# 1Password writes the commit-signing config (signing key and op-ssh-sign) to
# ~/.gitconfig.local, which the work gitconfig includes. Setup can't do that
# step, so flag it if it hasn't happened yet.
if [ ! -f "$HOME/.gitconfig.local" ]; then
    warn "No ~/.gitconfig.local yet, so commit signing will fail. In 1Password, set up SSH commit signing and save its config to ~/.gitconfig.local."
fi

# Prefer HTTPS (via the gh CLI credential helper) over SSH for GitHub git
# operations. Commit/tag signing is unaffected either way, since it's handled
# separately by 1Password's ssh-agent signing (gpg.format=ssh in
# shared/configs/.gitconfig), not by the git remote transport.
# Guarded on being logged in already, since a fresh machine hasn't run
# `gh auth login` yet at this point in setup.
if command -v gh >/dev/null 2>&1 && gh auth status -h github.com >/dev/null 2>&1; then
    gh config set -h github.com git_protocol https
    gh auth setup-git
else
    warn "GitHub CLI isn't signed in. Run 'gh auth login', then re-run setup to switch git to HTTPS via gh."
fi

sh "$SHAREDPATH/scripts/vscode.sh" "$(dirname "$SHAREDPATH")"
sh "$SHAREDPATH/scripts/terminal.sh" "$(dirname "$SHAREDPATH")"
