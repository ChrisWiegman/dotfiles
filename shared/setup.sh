#!/bin/sh

set -e
trap 'echo "setup.sh failed at line $LINENO" >&2' ERR

SHAREDPATH="$1"
MACHINEPATH="$2"

OS="$(uname)"

if [ "$OS" = "Darwin" ]; then
    sh "$SHAREDPATH/scripts/mac.sh"
fi

# Create the code folder if we don't have it
if [ ! -d "$HOME/Code" ]; then
    mkdir -p "$HOME/Code"
fi

sh "$SHAREDPATH/scripts/homebrew.sh" "$MACHINEPATH"


sh "$SHAREDPATH/scripts/oh-my-z.sh"

sh "$SHAREDPATH/scripts/configs.sh" "$SHAREDPATH" "$MACHINEPATH"

# Run the local config if its available
if [ -s "$MACHINEPATH/setup.sh" ]; then
    sh "$MACHINEPATH/setup.sh" "$SHAREDPATH" "$MACHINEPATH"
fi
