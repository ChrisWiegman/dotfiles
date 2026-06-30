#!/bin/sh

set -e
trap 'echo "mac/setup.sh failed at line $LINENO" >&2' ERR

SHAREDPATH="$1"
MACHINEPATH="$2"

# Link app configs that only belong on this machine.
sh "$SHAREDPATH/scripts/vscode.sh" "$(dirname "$SHAREDPATH")"
sh "$SHAREDPATH/scripts/terminal.sh" "$(dirname "$SHAREDPATH")"
