#!/bin/sh

set -e
trap 'echo "setup.sh failed at line $LINENO" >&2' ERR

SHAREDPATH="$1"
MACHINEPATH="$2"

# Request administrator access once and keep the sudo timestamp warm for the rest
# of the run so steps that need it (Rosetta, etc.) don't pause for a password.
# This survives the re-exec below because `exec` preserves the process PID, and
# the keep-alive loop exits once that PID is gone. The env marker keeps us from
# starting a second loop on the re-exec.
if [ -z "$DOTFILES_SUDO_KEEPALIVE" ]; then
    export DOTFILES_SUDO_KEEPALIVE=1
    echo "Requesting administrator access for setup..."
    if ! sudo -v; then
        echo "Administrator access is required to run setup." >&2
        exit 1
    fi
    ( while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done ) &
fi

sh "$SHAREDPATH/scripts/mac.sh"

# Clone the dotfiles repo to ~/.dotfiles and re-exec from there.
# This handles the bootstrap case where the repo was downloaded as a zip
# (before git was available) and git is now installed via Xcode CLT above.
DOTFILES_DIR="$HOME/.dotfiles"
DOTFILES_REPO_SSH="git@github.com:ChrisWiegman/dotfiles.git"
DOTFILES_REPO_HTTPS="https://github.com/ChrisWiegman/dotfiles.git"
if [ "$SHAREDPATH" != "$DOTFILES_DIR/shared" ]; then
    if [ ! -d "$DOTFILES_DIR/.git" ]; then
        echo "Cloning dotfiles to $DOTFILES_DIR..."
        git clone "$DOTFILES_REPO_HTTPS" "$DOTFILES_DIR"
        git -C "$DOTFILES_DIR" remote set-url origin "$DOTFILES_REPO_SSH"
    fi
    MACHINE_NAME="$(basename "$MACHINEPATH")"
    cd "$DOTFILES_DIR"
    exec sh "$DOTFILES_DIR/setup.sh" "$MACHINE_NAME"
fi

# Create the code folder if we don't have it
if [ ! -d "$HOME/Code" ]; then
    mkdir -p "$HOME/Code"
fi

# Clone repos listed in the machine's Repos file into ~/Code
if [ -f "$MACHINEPATH/Repos" ]; then
    while IFS= read -r repo || [ -n "$repo" ]; do
        [ -z "$repo" ] && continue
        reponame="$(basename "$repo" .git)"
        if [ ! -d "$HOME/Code/$reponame" ]; then
            git clone "$repo" "$HOME/Code/$reponame"
        fi
    done < "$MACHINEPATH/Repos"
fi

sh "$SHAREDPATH/scripts/permissions.sh"

sh "$SHAREDPATH/scripts/homebrew.sh" "$MACHINEPATH"

sh "$SHAREDPATH/scripts/configs.sh" "$SHAREDPATH" "$MACHINEPATH"

sh "$SHAREDPATH/scripts/apps.sh" "$(dirname "$SHAREDPATH")"

# Run the local config if its available
if [ -s "$MACHINEPATH/setup.sh" ]; then
    sh "$MACHINEPATH/setup.sh" "$SHAREDPATH" "$MACHINEPATH"
fi

echo
echo "✅ Setup complete for '$(basename "$MACHINEPATH")'."
echo "   • Homebrew packages, casks, and App Store apps installed"
echo "   • Shell, git, ssh, tmux, mise, and app configs linked"
echo "   Open a new terminal (or run 'szh') to pick up the new shell config."
