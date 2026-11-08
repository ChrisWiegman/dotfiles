#!/bin/sh

set -e
trap 'echo "fonts.sh failed at line $LINENO" >&2' ERR

# Check for fonts setup can't install. MonoLisa's license only allows
# installing it from its thumb drive, so that's done by hand on every machine.
# VS Code and the Terminal profile use it.

. "$(dirname "$0")/lib.sh"

echo "Checking fonts"

# Ask macOS for its installed font families, wherever the font files live.
families="$(osascript -l JavaScript -e 'ObjC.import("AppKit");
    ObjC.deepUnwrap($.NSFontManager.sharedFontManager.availableFontFamilies).join("\n")' \
    2>/dev/null || true)"

if ! printf '%s\n' "$families" | grep -qx 'MonoLisaCode'; then
    warn "The MonoLisa font isn't installed, so apps set to use it fall back to another font. Install MonoLisaCode from its thumb drive (open each .ttf file and click Install Font)."
fi
