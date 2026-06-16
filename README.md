# My dotfiles

This repo is a bit more than dotfiles. It includes those, of course, as well as scripts allowing me to setup (or reset) any of my machines very quickly.

Note this is an evolving repo and tends to represent where my machines are on any given day. My motivation is that it allows me to rebuild a machine I own in 2 hours or less, something I've found can be very handy over the years. Use it at your own risk.

## Layout

- **apps** Configs for the various apps I use
- **machines** dotfiles and setup scripts that are applicable per machine
- **shared** dotfiles and setup scripts that I can use on any machine

## Machines

Each subfolder of `machines` is a target you can pass to `setup.sh`:

- **joy** my personal laptop
- **mac** my personal desktop
- **work** my work machine

## Usage

The setup script bootstraps itself: it installs the Xcode Command Line Tools
(which provide `git`), clones this repo to `~/.dotfiles`, and re-runs itself from
there. That means you don't need `git` or `~/.dotfiles` to exist ahead of time —
you only need a copy of this repo and the name of the machine you're setting up.

### Fresh machine (no git yet)

On a brand-new Mac `git` isn't available, so grab the repo as a zip, extract it,
and run the setup script from wherever it landed:

```sh
# Download and extract the repo (anywhere — Downloads is fine)
curl -L https://github.com/ChrisWiegman/dotfiles/archive/refs/heads/main.zip -o dotfiles.zip
unzip dotfiles.zip
cd dotfiles-main

# Run setup for the target machine (joy, mac, or work)
./setup.sh mac
```

The script will install the Xcode Command Line Tools, clone this repo to
`~/.dotfiles`, and re-exec from there. Once it finishes you can delete the
downloaded copy — `~/.dotfiles` is the canonical clone going forward.

### Existing machine (git already installed)

If you already have `git`, just clone and run:

```sh
git clone https://github.com/ChrisWiegman/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./setup.sh mac
```

Re-running `./setup.sh <machine>` from `~/.dotfiles` at any time is safe and is
how I reset or update a machine.

## What setup does

For the selected machine, `setup.sh`:

1. Installs the Xcode Command Line Tools and sets `zsh` as the default shell.
2. Clones this repo to `~/.dotfiles` (and re-execs from there) if it isn't already.
3. Creates `~/Code` and clones any repos listed in the machine's `Repos` file.
4. Installs everything in the machine's `Brewfile` via Homebrew.
5. Symlinks the shared and machine-specific config files (ssh, tmux, git, zsh, mise, etc.).
6. Runs the machine's own `setup.sh`, if it has one, for any final machine-specific steps.
