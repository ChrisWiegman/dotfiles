#!/bin/sh

set -e
trap 'echo "setup.sh failed at line $LINENO" >&2' ERR

# Resolve paths from this script's location, not the current directory, so
# `sh ~/Downloads/dotfiles-main/setup.sh joy` works from anywhere.
OURPWD="$(cd "$(dirname "$0")" && pwd)"
ARG_MACHINE="$(basename "${1:-}")"
MACHINEPATH="$OURPWD/machines/$ARG_MACHINE"
SHAREDPATH="$OURPWD/shared"

die () {
    echo >&2 "$@"
    exit 1
}

# Each subfolder of machines/ is a valid target. Match the argument exactly
# and list the targets for the usage message.
machines=""
found=0
for dir in "$OURPWD/machines"/*/; do
  [ -d "$dir" ] || continue
  name="$(basename "$dir")"
  if [ "$name" = "$ARG_MACHINE" ]; then
    found=1
  fi
  machines="${machines:+$machines, }'$name'"
done
machines="$(echo "$machines" | sed 's/\(.*\), /\1, or /')"

if [ "$found" -ne 1 ]; then
  die "Please invoke script with either $machines as argument"
fi

sh "$SHAREDPATH/setup.sh" "$SHAREDPATH" "$MACHINEPATH"
