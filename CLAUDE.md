# Dotfiles repo

Setup scripts and dotfiles that rebuild any of my Macs (`joy`, `mac`, `work`) in
under two hours. `README.md` covers usage and what setup does; keep it in sync
with any change to setup behavior.

## Conventions

- Setup scripts are POSIX `sh` (`#!/bin/sh`, `set -e`, an ERR trap naming the
  script). No bashisms. Shell configs under `shared/configs/` are zsh.
- Anything that shouldn't stop a rebuild calls `warn` from
  `shared/scripts/lib.sh` instead of exiting. Warnings are collected and shown
  under "Needs your attention" at the end of the run.
- Put files in place with `link_config src dest [perms]`, which symlinks into
  the repo and backs up a real file once. `chmod` follows the symlink, so a
  `0400` link makes the repo file read-only. Run `chmod u+w` before editing.
- Everything must be safe to re-run: setup is also how a machine gets updated.
- Shared first, machine overrides second: `shared/Brewfile` then
  `machines/<m>/Brewfile`; the shared SSH config `Include`s
  `~/.ssh/config.d/*.conf`, linked from `machines/<m>/configs/.ssh/config.d/`.
- Machine selection at runtime comes from where `~/.zshrc` links to
  (see `r_mise` and `settings.py`).

## Signing and keys

- `joy` and `mac` sign commits with a per-machine `~/.ssh/id_ed25519` created by
  `sshkey.sh`. Never copy keys between machines.
- `work` signs through 1Password. 1Password writes `~/.gitconfig.local`; don't
  move its signing settings into this repo.

## Checking changes

- `sh -n` setup scripts and `zsh -n` zsh files.
- Test tmux config changes on an isolated server: `tmux -L test -f <file> ...`.
- Test SSH config with `ssh -F <file> -G github.com`.
- `brew bundle check --file=<Brewfile>` confirms a Brewfile resolves.
