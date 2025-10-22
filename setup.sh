#!/bin/sh

OURPWD=$PWD
ARG_MACHINE="$(basename "$1")"
MACHINEPATH="$OURPWD/machines/$ARG_MACHINE"
SHAREDPATH="$OURPWD/shared"

die () {
    echo >&2 "$@"
    exit 1
}

FOLDER="./machines"

# Get only directories in the folder, not files
dirs=""
for dir in "$FOLDER"/*; do
  [ -d "$dir" ] && dirs="$dirs $(basename "$dir")"
done

# Convert dirs string to set positional parameters for counting
set -- $dirs
count=$#

machines=""

if [ "$count" -eq 0 ]; then
  echo "No directories found in $FOLDER"
elif [ "$count" -eq 1 ]; then
  machines="'$1'"
else
  i=1
  while [ "$i" -le "$count" ]; do
    eval d=\${$i}
    if [ "$i" -eq "$count" ]; then
      machines="${machines}or '$d'"
    else
      machines="${machines}'$d', "
    fi
    i=$(expr $i + 1)
  done
  echo
fi

# Validate original argument
if [ -z "$ARG_MACHINE" ]; then
  die "Please invoke script with either $machines as argument"
fi

found=0
for d in $dirs; do
  if [ "$ARG_MACHINE" = "$d" ]; then
    found=1
    break
  fi
done

if [ "$found" -ne 1 ]; then
  die "Please invoke script with either $machines as argument"
fi

sh "$SHAREDPATH/setup.sh" "$SHAREDPATH" "$MACHINEPATH"
