#!/bin/sh

set -e
trap 'echo "homebrew.sh failed at line $LINENO" >&2' ERR

MACHINEPATH="$1"
SHARED_BREWFILE="$(cd "$(dirname "$0")/.." && pwd)/Brewfile"

. "$(dirname "$0")/lib.sh"

echo "Setting up Homebrew"

if test ! "$(command -v brew)"; then
    echo "Homebrew not installed. Installing."
    # NONINTERACTIVE skips the "Press RETURN to continue" pause; the sudo
    # keep-alive in shared/setup.sh supplies the admin access it needs.
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Launch Homebrew
[ -s "/opt/homebrew/bin/brew" ] && eval "$(/opt/homebrew/bin/brew shellenv)"

if ! command -v brew > /dev/null 2>&1; then
    echo "Error: Homebrew installation failed" >&2
    exit 1
fi

brew analytics off

# If a Brewfile installs Mac App Store apps, make sure `mas` is present first.
# (macOS no longer lets `mas` check App Store sign-in, so a signed-out App Store
# shows up as failed `mas` lines in the bundle below.)
if grep -q '^[[:space:]]*mas ' "$SHARED_BREWFILE" "${MACHINEPATH}/Brewfile" 2>/dev/null; then
    if ! command -v mas > /dev/null 2>&1; then
        brew install mas
    fi
fi

# Install everything in the shared Brewfile, then the machine's. brew bundle
# keeps going past a failed entry but exits non-zero at the end; treat that as a
# warning rather than aborting, so configs still get linked and the rest of
# setup still runs.
for brewfile in "$SHARED_BREWFILE" "${MACHINEPATH}/Brewfile"; do
    [ -f "$brewfile" ] || continue
    if ! brew bundle --file="$brewfile"; then
        warn "Some Brewfile entries failed to install (see the brew output above). If they're App Store apps, sign in to the App Store, then run: brew bundle --file=\"$brewfile\""
    fi
    rm -f "${brewfile}.lock.json"
done

# If the Brewfile installed the full Xcode app (via `mas`), its license must be
# accepted before any xcrun-based tool (e.g. `mise install`, run right after this
# script) will work. Accept it non-interactively now rather than let those steps
# fail on the license prompt.
if [ -d "/Applications/Xcode.app" ] && ! sudo xcodebuild -license status > /dev/null 2>&1; then
    echo "Accepting Xcode license..."
    sudo xcodebuild -license accept
fi

# Cleanup all leftovers from the installation.
brew cleanup --prune=all --quiet
