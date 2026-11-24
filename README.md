# My dotfiles

This repo is a bit more than dotfiles. It includes those, of course, as well as scripts allowing me to setup (or reset) any of my machines very quickly.

Note this is an evolving repo and tends to represent where my machines are on any given day. My motivation is that it allows me to rebuild a machine I own in 2 hours or less, something I've found can be very handy over the years. Use it at your own risk.

## Layout

- **apps** Configs for the various apps I use
- **machines** dotfiles and setup scripts that are applicable per machine
- **profiles** Mac settings for a group of machines (see [Mac settings](#mac-settings))
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
9. Runs the machine's own `setup.sh`, if it has one (e.g. VS Code settings and the Terminal theme), then applies the machine's macOS and app settings (see [Mac settings](#mac-settings)).
10. Clones any repos listed in the machine's `Repos` file into `~/Code`, over SSH if a key is set up and otherwise over HTTPS.

Problems that shouldn't stop a rebuild (a Brewfile entry that fails to install,
a repo that can't be cloned yet, a missing SSH key) don't abort setup. They're
collected and listed under **Needs your attention** when it finishes. Fix
those, then re-run setup; it skips anything already done.

The script asks for your administrator password once up front and keeps that
access alive for the rest of the run, so you can start it and walk away.

## Mac settings

Each machine keeps its System Settings and app preferences (Mail, Safari,
Calendar, Reminders, Podcasts, Music, Notes, …) and third-party apps' settings in
`machines/<machine>/settings/`. There's one plist per preferences domain,
holding only the keys being tracked. Window positions, timestamps, and account
IDs stay out. Setup applies them, and the `macsettings` shell command keeps them
up to date.

Settings come in three layers, which setup applies in this order, so a later
layer overrides an earlier one:

1. `shared/settings/`: every machine, Joy's included (like not writing
   `.DS_Store` files to network and USB drives). Manage them with
   `macsettings --machine shared …`.
2. `profiles/<name>/settings/`: a group of machines. A machine gets a profile
   by listing its name in `machines/<machine>/Profiles`; `mac` and `work` both
   list `chris`, for settings I want on my machines but not Joy's. Manage them
   with `macsettings --profile chris …`.
3. `machines/<machine>/settings/`: that machine alone (the default).

`track`, `watch`, `untrack`, and `export` change one layer: the machine's own
unless you pass `--machine shared` or `--profile <name>`. In their listings,
`*` marks a key already tracked in that layer and `+` one tracked in a shared
or profile layer. To move a key into a profile, track it there
(`macsettings --profile chris track <domain> <key>`), then untrack it from the
machine (`macsettings untrack <domain> <key>`).

Run `macsettings` from **Terminal**. It needs the same Full Disk Access as setup,
because macOS hides sandboxed apps' settings (Mail, Safari, Notes, …) from
everything else.

**Save this Mac's settings.** Run `macsettings export`, review `git diff`, and
commit `machines/<machine>/settings/`. In one pass it refreshes every tracked
key from the Mac's current values and captures every new key that looks like a
setting, in System Settings, Apple's apps, and third-party apps. It leaves out:

- Apple's background services (Siri, iCloud, Messages sync, and so on). Their
  preferences are bookkeeping, and replaying some of it on a new Mac would do
  harm, like telling Messages its first sync already happened.
- App state: window positions, timestamps, "already showed this" flags, caches.
- Anything that looks personal, because this repo is public: email addresses,
  account and device IDs, MAC addresses, tokens, paths in your home folder, and
  your name or the Mac's name.
- Keys a shared or profile layer already tracks.

Those filters are educated guesses, so read the diff before pushing.

A key that's back to its default stops being tracked. If a whole domain reads
back empty (usually because macOS is hiding it, as it does without Full Disk
Access), export leaves it alone and says so rather than untracking everything in
it. Export only captures into the machine's own layer (`--machine shared` and
`--profile` exports just refresh what's tracked there), but it lists any shared
or profile key that's different on this Mac, since the next setup run would put
the tracked value back.

**Leave something out.** `macsettings untrack <domain> [<key>…]` stops tracking
keys, or a whole domain, and records them in the machine's
`settings/_ignore.plist` so export doesn't capture them again.
`macsettings track` brings them back, and `macsettings list` shows what's left
out.

**Find a specific setting.** Run `macsettings watch`, change the setting in
System Settings or the app, and press Enter. It lists what changed; pick the
ones to keep. This is the way to add a setting export leaves out, or one for a
shared or profile layer.

**Other commands:**

- `macsettings list` shows what's tracked, in every layer the machine gets.
- `macsettings track <domain>` lists a domain's keys to pick from, and
  `macsettings track <domain> <key>…` tracks specific keys.
- `macsettings apply` writes the tracked settings to this Mac (setup does this).

The machine comes from whichever one `~/.zshrc` is linked to; add
`--machine <name>` to use another. To save the settings of a Mac that isn't
built from this repo yet (an old Mac being replaced), clone the repo there,
create `machines/<name>/`, and run
`python3 shared/scripts/settings.py --machine <name> export`.
