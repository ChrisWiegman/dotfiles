# ~/.zprofile
eval "$(mise activate zsh --shims)"

# Update all mise-managed tools (go, node, npm, etc.) to the latest
# versions allowed by the mise config, then remove the old installs.
function u_mise() {
  mise upgrade
  mise prune --yes
}

# Repair the mise setup the way setup.sh originally did it: re-link the
# machine's mise config if the symlink has gone missing (it sometimes comes
# unlinked), then (re)install any tools declared in the config that aren't
# currently present. Safe to run repeatedly; `mise install` is a no-op when
# everything is already there.
function r_mise() {
  command -v mise >/dev/null 2>&1 || return 0

  # The active machine is whichever config dir ~/.zshrc resolves to, mirroring
  # M_CONFIG_DIR in scripts/configs.sh.
  local zshrc; zshrc="$(readlink "$HOME/.zshrc" 2>/dev/null)" || return 0
  local src="${zshrc:h}/.config/mise/config.toml"
  local dest="$HOME/.config/mise/config.toml"

  [[ -f "$src" ]] || return 0

  # Re-link the config if the symlink is missing or pointing elsewhere.
  if [[ ! -L "$dest" || "$(readlink "$dest")" != "$src" ]]; then
    mkdir -p "${dest:h}"
    rm -f "$dest"
    ln -s "$src" "$dest"
    echo "Re-linked mise config"
  fi

  # Install any tools from the config that aren't installed yet.
  mise install
}