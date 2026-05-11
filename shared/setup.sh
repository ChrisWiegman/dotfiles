#!/bin/sh

set -e
trap 'echo "setup.sh failed at line $LINENO" >&2' ERR

SHAREDPATH="$1"
MACHINEPATH="$2"

OS="$(uname)"

if [ "$OS" = "Darwin" ]; then
    sh "$SHAREDPATH/scripts/mac.sh"
fi

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

sh "$SHAREDPATH/scripts/homebrew.sh" "$MACHINEPATH"

sh "$SHAREDPATH/scripts/configs.sh" "$SHAREDPATH" "$MACHINEPATH"

# Run the local config if its available
if [ -s "$MACHINEPATH/setup.sh" ]; then
    sh "$MACHINEPATH/setup.sh" "$SHAREDPATH" "$MACHINEPATH"
fi
