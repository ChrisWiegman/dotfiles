#!/bin/sh

set -e
trap 'echo "fonts.sh failed at line $LINENO" >&2' ERR

# Check for fonts setup can't install. MonoLisa's license only allows
# installing it from its thumb drive, so that's done by hand; VS Code and the
# Terminal profile both use it. This is opt-in: call it from a machine's
# setup.sh only on computers that use those apps, e.g.
#   sh "$SHAREDPATH/scripts/fonts.sh"

. "$(dirname "$0")/lib.sh"

echo "Checking fonts"

# Ask macOS for its installed font families, wherever the font files live.
families="$(osascript -l JavaScript -e 'ObjC.import("AppKit");
    ObjC.deepUnwrap($.NSFontManager.sharedFontManager.availableFontFamilies).join("\n")' \
    2>/dev/null || true)"

if ! printf '%s\n' "$families" | grep -qx 'MonoLisaCode'; then
    warn "The MonoLisa font isn't installed, so VS Code and Terminal use a fallback font. Install MonoLisaCode from its thumb drive (open each .ttf file and click Install Font)."
fi
