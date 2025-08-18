#!/bin/zsh

OURPWD=$PWD
MACHINEPATH="$OURPWD/machines/$(basename "$1")"
SHAREDPATH="$OURPWD/shared"

die () {
    echo >&2 "$@"
    exit 1
}

FOLDER="./machines"

# Get only directories in the folder, not files
dirs=()
while IFS= read -r -d '' dir; do
  dirs+=("$(basename "$dir")")
done < <(find "$FOLDER" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

count=${#dirs[@]}
machines=""

if (( count == 0 )); then
  echo "No directories found in $FOLDER"
elif (( count == 1 )); then
  machines="'${dirs[0]}'"
else
  for (( i=1; i<=count; i++ )); do
    if (( i == count )); then
        machines="${machines}or '${dirs[i]}'"
    else
        machines="${machines}'${dirs[i]}', "
    fi
  done
  echo
fi

[ "$#" -eq 1 ] || die "Please invoke script with either $machines as argument"
echo $1 | grep -E -q "^($(printf "%s|" "${dirs[@]}" | sed 's/|$//'))$" || die "Please invoke script with either $machines as argument"

zsh $SHAREDPATH/setup.sh $SHAREDPATH $MACHINEPATH