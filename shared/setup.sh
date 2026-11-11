#!/bin/sh

set -e
trap 'echo "setup.sh failed at line $LINENO" >&2' ERR

SHAREDPATH="$1"
MACHINEPATH="$2"

# Install MonoLisa from the zip beside this repo copy (its thumb drive) before
# anything else, and stop if it can't be: VS Code and Terminal need it, and
# finding out at the end of a long run would waste it.
if ! sh "$SHAREDPATH/scripts/fonts.sh"; then
    exit 1
fi

# Check macOS privacy permissions before anything else. If something is missing,
# permissions.sh opens the right Settings pane and explains what to enable; we then
# stop cleanly so the user can grant it, restart Terminal, and re-run setup. (Full
# Disk Access only registers after Terminal is restarted, so a second run is
# expected on a fresh machine — the up-front check saves a half-finished setup.)
if ! sh "$SHAREDPATH/scripts/permissions.sh" "$(basename "$MACHINEPATH")"; then
    exit 0
fi

# Request administrator access once and keep the sudo timestamp warm for the rest
# of the run so steps that need it (Rosetta, etc.) don't pause for a password.
# This survives the re-exec below because `exec` preserves the process PID, and
# the keep-alive loop exits once that PID is gone. The env marker keeps us from
# starting a second loop on the re-exec.
if [ -z "$DOTFILES_SUDO_KEEPALIVE" ]; then
    export DOTFILES_SUDO_KEEPALIVE=1
    echo "Requesting administrator access for setup..."
    if ! sudo -v; then
        echo "Administrator access is required to run setup." >&2
        exit 1
    fi
    (while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" 2>/dev/null || exit
    done) &
fi

sh "$SHAREDPATH/scripts/mac.sh"

# Clone the dotfiles repo to ~/.dotfiles and re-exec from there.
# This handles the bootstrap case where the repo was downloaded as a zip
# (before git was available) and git is now installed via Xcode CLT above.
DOTFILES_DIR="$HOME/.dotfiles"
DOTFILES_REPO_SSH="git@github.com:ChrisWiegman/dotfiles.git"
DOTFILES_REPO_HTTPS="https://github.com/ChrisWiegman/dotfiles.git"
if [ "$SHAREDPATH" != "$DOTFILES_DIR/shared" ]; then
    if [ ! -d "$DOTFILES_DIR/.git" ]; then
        echo "Cloning dotfiles to $DOTFILES_DIR..."
        git clone "$DOTFILES_REPO_HTTPS" "$DOTFILES_DIR"
        # Fetch over HTTPS (works anonymously, so `rup` keeps updating dotfiles
        # even on a machine with no GitHub SSH key) and push over SSH.
        git -C "$DOTFILES_DIR" remote set-url --push origin "$DOTFILES_REPO_SSH"
    fi
    MACHINE_NAME="$(basename "$MACHINEPATH")"
    cd "$DOTFILES_DIR"
    exec sh "$DOTFILES_DIR/setup.sh" "$MACHINE_NAME"
fi

. "$SHAREDPATH/scripts/lib.sh"

# Collect non-fatal problems from every step for the summary at the end.
DOTFILES_WARNINGS="$(mktemp)"
export DOTFILES_WARNINGS
trap 'rm -f "$DOTFILES_WARNINGS"' EXIT

# Create this machine's SSH key (if it needs one) before the long Homebrew step,
# while you're still at the keyboard.
sh "$SHAREDPATH/scripts/sshkey.sh" "$MACHINEPATH"

sh "$SHAREDPATH/scripts/homebrew.sh" "$MACHINEPATH"

sh "$SHAREDPATH/scripts/touchid.sh"

sh "$SHAREDPATH/scripts/security.sh"

# homebrew.sh runs `brew shellenv` in its own shell, so that PATH never reaches
# us. Repeat it here on a fresh machine, where /opt/homebrew/bin isn't on PATH
# yet, so the steps below can find brew-installed tools (configs.sh runs
# `mise install` and would abort setup with "mise: command not found").
if [ -s "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

sh "$SHAREDPATH/scripts/configs.sh" "$SHAREDPATH" "$MACHINEPATH"

# Run the local config if its available
# (App configs like VS Code and Terminal.app are opt-in per machine — call
# scripts/vscode.sh / scripts/terminal.sh from a machine's setup.sh.)
if [ -s "$MACHINEPATH/setup.sh" ]; then
    sh "$MACHINEPATH/setup.sh" "$SHAREDPATH" "$MACHINEPATH"
fi

# Apply the tracked macOS and app settings: shared/settings on every machine,
# then the machine's own machines/<m>/settings (managed with `macsettings`;
# see shared/scripts/settings.py).
if [ -d "$SHAREDPATH/settings" ] || [ -d "$MACHINEPATH/settings" ]; then
    echo "Applying macOS settings"
    if ! /usr/bin/python3 -I "$SHAREDPATH/scripts/settings.py" \
        --machine "$(basename "$MACHINEPATH")" apply; then
        warn "Some macOS settings couldn't be applied (see above). Re-run: macsettings apply"
    fi
fi

# Clone repos listed in the machine's Repos file into ~/Code. This runs last so
# the ssh config is already linked. A fresh machine usually has no GitHub SSH
# key yet, so fall back to an HTTPS clone (fine for public repos) that keeps
# SSH as the push URL, and never let one repo stop the run.
mkdir -p "$HOME/Code"
if [ -f "$MACHINEPATH/Repos" ]; then
    echo "Cloning repos into ~/Code"
    while IFS= read -r repo || [ -n "$repo" ]; do
        case "$repo" in '' | '#'*) continue ;; esac
        reponame="$(basename "$repo" .git)"
        dest="$HOME/Code/$reponame"
        [ -d "$dest" ] && continue

        # No StrictHostKeyChecking override: GitHub's host keys are pinned in
        # the ssh config, so a key that doesn't match fails instead of being
        # accepted.
        if GIT_SSH_COMMAND="ssh -o BatchMode=yes" \
            git clone --quiet "$repo" "$dest" </dev/null 2>/dev/null; then
            echo "  cloned $reponame"
            continue
        fi

        https="$(echo "$repo" | sed -E 's#^git@github\.com:#https://github.com/#')"
        if [ "$https" != "$repo" ] && GIT_TERMINAL_PROMPT=0 \
            git clone --quiet "$https" "$dest" </dev/null; then
            git -C "$dest" remote set-url --push origin "$repo"
            echo "  cloned $reponame (over HTTPS)"
        else
            warn "Couldn't clone $repo (add your SSH key to GitHub and re-run setup)."
        fi
    done <"$MACHINEPATH/Repos"
fi

echo
echo "✅ Setup complete for '$(basename "$MACHINEPATH")'."
echo "   • Homebrew packages, casks, and App Store apps installed"
echo "   • Shell, git, ssh, tmux, mise, and app configs linked"
echo "   Open a new terminal (or run 'szh') to pick up the new shell config."

if [ -s "$DOTFILES_WARNINGS" ]; then
    echo
    echo "⚠️  Needs your attention:"
    while IFS= read -r line; do
        echo "   • $line"
    done <"$DOTFILES_WARNINGS"
fi
