# Shared helpers for setup scripts. Source this file; it defines no top-level
# behavior of its own.

# Symlink a repo file into place, replacing whatever is there. Backs up a real
# (non-symlink) file once so nothing is lost the first time we take ownership.
# $3 = optional permissions for the linked file (chmod follows the symlink to
# the repo source); defaults to 0644 when omitted.
link_config() {
    src="$1"
    dest="$2"
    perms="${3:-0644}"

    [ -e "$src" ] || { echo "  skip (missing in repo): $src"; return 0; }

    mkdir -p "$(dirname "$dest")"

    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        mv "$dest" "$dest.pre-dotfiles"
        echo "  backed up existing $(basename "$dest") -> $(basename "$dest").pre-dotfiles"
    fi

    rm -f "$dest"
    ln -s "$src" "$dest"
    chmod "$perms" "$dest"
}
