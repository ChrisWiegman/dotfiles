# My dotfiles

This repo is a bit more than dotfiles. It includes those, of course, as well as scripts allowing me to setup (or reset) any of my machines very quickly.

Note this is an evolving repo and tends to represent where my machines are on any given day. My motivation is that it allows me to rebuild a machine I own in 2 hours or less, something I've found can be very handy over the years. Use it at your own risk.

## Layout

- **apps** Configs for the various apps I use
- **machines** dotfiles and setup scripts that are applicable per machine
- **shared** dotfiles and setup scripts that I can use on any machine

## Machines

Each subfolder of `machines` is a target you can pass to `setup.sh`:

- **joy** Joy's laptop
- **mac** my personal desktop
- **work** my work machine

## Usage

The setup script bootstraps itself: it installs the Xcode Command Line Tools
(which provide `git`), clones this repo to `~/.dotfiles`, and re-runs itself from
there. That means you don't need `git` or `~/.dotfiles` to exist ahead of time —
you only need a copy of this repo and the name of the machine you're setting up.

### Fresh machine (no git yet)

Run setup from **Apple's Terminal app** (the macOS privacy permissions below
attach to whichever app is running it). On a brand-new Mac `git` isn't available,
so download the repo as a tarball and run the setup script from it — one line:

```sh
curl -fsSL https://github.com/ChrisWiegman/dotfiles/archive/refs/heads/main.tar.gz | tar -xz && sh dotfiles-main/setup.sh joy
```

Swap `joy` for the machine you're setting up (`joy`, `mac`, or `work`).

**Before you start:** sign in to the App Store with the Apple ID that owns the
machine's App Store apps. Setup can't check this, and any App Store app it can't
install is listed at the end of the run instead.

The MonoLisa font (used by VS Code and the Terminal theme) can only be
installed from its thumb drive, so it isn't in this repo. To have setup install
it, put a copy of this repo on the drive next to the font zip and run setup from
there (`sh /Volumes/<drive>/dotfiles/setup.sh joy`):

```text
<drive>/MonoLisaCode.zip
<drive>/dotfiles/
```

Setup needs the font, so it checks for it before doing anything else. If
MonoLisa isn't installed, it looks for `MonoLisa*.zip` in the folder that holds
the copy you ran it from, copies its `.ttf` files into `~/Library/Fonts`, and
registers them with the current login session so Terminal and other open apps
can use the font right away, without a restart. If there's no zip, setup stops
and explains what to do. Once the font is in place, the drive isn't needed for
the rest of the run. If macOS still hasn't loaded the font, setup skips the
Terminal theme (so the profile doesn't get stuck on a fallback font) and asks
you to log out and back in and run setup again.

The script will install the Xcode Command Line Tools, clone this repo to
`~/.dotfiles`, and re-exec from there. Once it finishes you can delete the
downloaded copy — `~/.dotfiles` is the canonical clone going forward.

> **Heads up — the first run may stop on purpose.** Before doing anything, setup
> checks that Terminal has the macOS permissions it needs (see below). If they're
> missing it opens the right Settings panes, tells you what to enable, and stops.
> Grant them, **quit and reopen Terminal**, and run `sh dotfiles-main/setup.sh joy`
> again (from the same folder) — the second run goes start to finish.

### macOS permissions

Setup needs two privacy permissions granted to **Terminal**, because macOS won't
let a script grant them itself:

- **Full Disk Access** — detected automatically by the script.
- **App Management** — lets Homebrew update apps already in `/Applications`. macOS
  exposes no way to detect this, so setup walks you through it once and remembers
  (via a marker in `~/.cache/dotfiles/`) so it won't ask again.

Both are found in **System Settings > Privacy & Security**. Full Disk Access only
takes effect after Terminal is restarted, which is why a fresh machine usually
takes two runs.

### Existing machine (git already installed)

If you already have `git`, just clone and run:

```sh
git clone https://github.com/ChrisWiegman/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./setup.sh mac
```

Re-running `./setup.sh <machine>` from `~/.dotfiles` at any time is safe and is
how I reset or update a machine.

### Day to day

`rup` updates the repos in `~/Code` and this repo. Once a day it also updates
App Store apps and Homebrew packages (including Go and Node), and installs anything added
to the shared or machine `Brewfile` since setup last ran.

`flo` ("find left overs") lists the repos in `~/Code` with uncommitted work,
including untracked files.

## What setup does

For the selected machine, `setup.sh`:

1. Installs the MonoLisa font from the zip beside the repo copy you ran it from and loads it for open apps (see above), or stops if the font is missing and there's no zip.
2. Checks that Terminal has the required macOS permissions (Full Disk Access and App Management), opening the right Settings panes and stopping if any are missing.
3. Installs the Xcode Command Line Tools and sets `zsh` as the default shell.
4. Clones this repo to `~/.dotfiles` (and re-execs from there) if it isn't already. It fetches over HTTPS and pushes over SSH, so updates work before a GitHub SSH key exists.
5. Creates a new SSH key for this machine if it doesn't have one (`joy` and `mac`; `work` signs through 1Password). You pick a passphrase, which is saved in the Keychain. Setup then copies the public key and opens GitHub's "New SSH key" page. Add the key there twice, once as an **Authentication Key** and once as a **Signing Key**, while setup keeps running. Each machine gets its own key, so there's nothing to copy over from an old machine; just delete the old machine's key on GitHub.
6. Installs everything in `shared/Brewfile` (tools every machine gets), then the machine's own `Brewfile`, via Homebrew. A machine's `Brewfile` also lists its VS Code extensions (`vscode "…"` lines). Add or remove extensions there: one uninstalled only in VS Code is reinstalled the next time `rup` runs.
7. Enables Touch ID for `sudo` and turns on the firewall and its stealth mode. It warns if FileVault, Gatekeeper, System Integrity Protection, the screen-lock password, or automatic updates are off.
8. Symlinks the shared and machine-specific config files (ssh, tmux, git, zsh, etc.). SSH uses one shared config; machine-specific settings go in `machines/<machine>/configs/.ssh/config.d/*.conf`. GitHub's SSH host keys are pinned in `shared/configs/.ssh/known_hosts.d/github.com`, so a fresh machine never has to trust the key it sees on first connect; if GitHub rotates its keys, refresh that file from https://api.github.com/meta. On `joy` and `mac` it also writes `~/.config/git/allowed_signers` from the machine's key, so `git log --show-signature` can verify local commits. On `work`, commit signing comes from 1Password, which saves its config to `~/.gitconfig.local`. 1Password itself is installed by Iru (work's device management), not Homebrew, and setup warns if it isn't there yet. Setup can't do that step for you, so until the file exists it's listed under **Needs your attention**.
9. Runs the machine's own `setup.sh`, if it has one (e.g. VS Code settings and the Terminal theme).
10. Clones any repos listed in the machine's `Repos` file into `~/Code`, over SSH if a key is set up and otherwise over HTTPS.

Problems that shouldn't stop a rebuild (a Brewfile entry that fails to install,
a repo that can't be cloned yet, a missing SSH key) don't abort setup. They're
collected and listed under **Needs your attention** when it finishes. Fix
those, then re-run setup; it skips anything already done.

The script asks for your administrator password once up front and keeps that
access alive for the rest of the run, so you can start it and walk away.
