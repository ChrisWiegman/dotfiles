#!/bin/sh

set -e
trap 'echo "fonts.sh failed at line $LINENO" >&2' ERR

# Install MonoLisa, which VS Code and the Terminal profile use. Its license
# only allows installing it from its thumb drive, so it never lives in this
# repo. Instead, keep MonoLisaCode.zip at the drive's root next to the dotfiles
# folder and run setup from the drive:
#
#   <drive>/MonoLisaCode.zip
#   <drive>/dotfiles/setup.sh
#
# shared/setup.sh exports DOTFILES_BOOTSTRAP_DIR (the copy setup was started
# from) before re-running from ~/.dotfiles; we look for the zip beside it.

. "$(dirname "$0")/lib.sh"

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SEARCH_DIR="$(dirname "${DOTFILES_BOOTSTRAP_DIR:-$REPO_ROOT}")"
FONT_DIR="$HOME/Library/Fonts"

echo "Checking fonts"

# Ask macOS for its installed font families, wherever the font files live.
monolisa_installed() {
    osascript -l JavaScript -e 'ObjC.import("AppKit");
        ObjC.deepUnwrap($.NSFontManager.sharedFontManager.availableFontFamilies).join("\n")' \
        2>/dev/null | grep -qx 'MonoLisaCode'
}

if monolisa_installed; then
    echo "  MonoLisa: installed"
    exit 0
fi

zip=""
for f in "$SEARCH_DIR"/MonoLisa*.zip; do
    [ -f "$f" ] && zip="$f" && break
done

if [ -z "$zip" ]; then
    warn "The MonoLisa font isn't installed, so apps set to use it fall back to another font. Put MonoLisaCode.zip next to the dotfiles folder on its thumb drive and run setup from there, or open each .ttf file and click Install Font."
    exit 0
fi

echo "  Installing MonoLisa from $zip"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
if ! unzip -qjo "$zip" '*.ttf' -d "$tmp"; then
    warn "Couldn't unzip $zip, so MonoLisa isn't installed. Open each .ttf file in it and click Install Font."
    exit 0
fi

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

if [ "$installed" -ne 1 ]; then
    warn "$zip has no .ttf files, so MonoLisa isn't installed."
fi
