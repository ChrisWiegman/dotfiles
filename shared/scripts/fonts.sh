#!/bin/sh

set -e
trap 'echo "fonts.sh failed at line $LINENO" >&2' ERR

# Make sure MonoLisa is installed. VS Code and the Terminal profile need it, so
# setup runs this first and stops if it fails. Its license only allows
# installing it from its thumb drive, so it never lives in this repo. Instead,
# keep MonoLisaCode.zip at the drive's root next to the dotfiles folder and run
# setup from the drive:
#
#   <drive>/MonoLisaCode.zip
#   <drive>/dotfiles/setup.sh
#
# We look for the zip in the folder holding the repo copy this script runs
# from. Exit status: 0 = installed, continue; 1 = missing, stop setup.

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SEARCH_DIR="$(dirname "$REPO_ROOT")"
FONT_DIR="$HOME/Library/Fonts"

echo "Checking fonts"

# Ask macOS for its installed font families, wherever the font files live. Also
# accept the font files themselves: fonts copied a moment ago (on the run before
# setup re-execs) may not be registered yet.
monolisa_installed() {
    for f in "$FONT_DIR"/MonoLisaCode*.ttf /Library/Fonts/MonoLisaCode*.ttf; do
        [ -f "$f" ] && return 0
    done
    osascript -l JavaScript -e 'ObjC.import("AppKit");
        ObjC.deepUnwrap($.NSFontManager.sharedFontManager.availableFontFamilies).join("\n")' \
        2>/dev/null | grep -qx 'MonoLisaCode'
}

missing() {
    echo >&2
    echo >&2 "  The MonoLisa font isn't installed, and setup needs it. $*"
    echo >&2 "  Put MonoLisaCode.zip next to the dotfiles folder on the font's thumb drive"
    echo >&2 "  and run setup from there:"
    echo >&2
    echo >&2 "      <drive>/MonoLisaCode.zip"
    echo >&2 "      <drive>/dotfiles/setup.sh"
    echo >&2
    echo >&2 "  Or open each .ttf file and click Install Font, then run setup again."
    exit 1
}

if monolisa_installed; then
    echo "  MonoLisa: installed"
    exit 0
fi

zip=""
for f in "$SEARCH_DIR"/MonoLisa*.zip; do
    [ -f "$f" ] && zip="$f" && break
done
[ -n "$zip" ] || missing "No MonoLisa*.zip in $SEARCH_DIR."

echo "  Installing MonoLisa from $zip"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
unzip -qjo "$zip" '*.ttf' -d "$tmp" || missing "Couldn't unzip $zip."

mkdir -p "$FONT_DIR"
installed=0
for ttf in "$tmp"/*.ttf; do
    # Skip macOS resource forks (__MACOSX/._*.ttf) that zips made in Finder carry.
    case "$(basename "$ttf")" in ._*) continue ;; esac
    [ -f "$ttf" ] || continue
    cp -f "$ttf" "$FONT_DIR/"
    echo "  installed $(basename "$ttf")"
    installed=1
done

[ "$installed" -eq 1 ] || missing "$zip has no .ttf files."
