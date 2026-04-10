# Aliases and functions
alias inode="echo \"Updating Node and npm...\"; nvm install --lts --latest-npm"

export NVM_DIR="$HOME/.nvm"

# Load NVM once — becomes a no-op after first call
_nvm_load() {
    [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && source "/opt/homebrew/opt/nvm/nvm.sh"
    [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && source "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
    _nvm_load() { :; }  # Become no-op before _load_nvmrc to prevent circular calls
    _load_nvmrc         # Auto-switch to .nvmrc version for the current directory
}

# Stub each command to trigger lazy load on first use
for _cmd in node npm npx nvm yarn pnpm; do
    eval "function $_cmd() { unset -f $_cmd; _nvm_load; $_cmd \"\$@\"; }"
done
unset _cmd

# Auto-switch node version from .nvmrc on directory change
autoload -U add-zsh-hook

_load_nvmrc() {
    # Walk up the tree to find .nvmrc without requiring nvm to be loaded
    local dir="$PWD" nvmrc_path=""
    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/.nvmrc" ]]; then
            nvmrc_path="$dir/.nvmrc"
            break
        fi
        dir="${dir:h}"
    done

    if [[ -n "$nvmrc_path" ]]; then
        _nvm_load
        local nvmrc_node_version
        nvmrc_node_version=$(nvm version "$(cat "$nvmrc_path")")
        if [[ "$nvmrc_node_version" == "N/A" ]]; then
            nvm install
        elif [[ "$nvmrc_node_version" != "$(nvm version)" ]]; then
            nvm use
        fi
    elif type nvm &>/dev/null && [[ "$(nvm version)" != "$(nvm version default)" ]]; then
        echo "Reverting to nvm default version"
        nvm use default
    fi
}

add-zsh-hook chpwd _load_nvmrc
