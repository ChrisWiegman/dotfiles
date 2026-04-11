# Aliases and functions
alias inode="echo \"Updating Node and npm...\"; nvm install --lts --latest-npm"

export NVM_DIR="$HOME/.nvm"
_NVM_LOADED=0

# Make the default Node install available to child processes like make
# before nvm itself is lazily loaded into the shell.
_resolve_nvm_default_version() {
    local alias_target alias_file="$NVM_DIR/alias/default" depth=0

    [[ -r "$alias_file" ]] || return 1
    alias_target="$(<"$alias_file")"

    while [[ "$alias_target" != v* ]]; do
        alias_file="$NVM_DIR/alias/$alias_target"
        [[ -r "$alias_file" ]] || return 1
        alias_target="$(<"$alias_file")"
        (( ++depth > 10 )) && return 1
    done

    [[ -x "$NVM_DIR/versions/node/$alias_target/bin/node" ]] || return 1
    printf '%s\n' "$alias_target"
}

_prepend_default_node_path() {
    local default_node_version default_node_bin
    default_node_version="$(_resolve_nvm_default_version)" || return 0
    default_node_bin="$NVM_DIR/versions/node/$default_node_version/bin"

    path=("$default_node_bin" ${path:#$default_node_bin})
    export PATH
}

_prepend_default_node_path

# Load NVM if it is not already available in this shell.
_ensure_nvm_loaded() {
    if (( _NVM_LOADED )); then
        return
    fi

    [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && source "/opt/homebrew/opt/nvm/nvm.sh"
    [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && source "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
    _NVM_LOADED=1

    if ! command -v node >/dev/null 2>&1; then
        nvm use default >/dev/null 2>&1
    fi
}

# Stub each command to trigger lazy load on first use
for _cmd in node npm npx nvm yarn pnpm; do
    eval "function $_cmd() {
        local cmd=$_cmd
        unset -f $_cmd
        if (( ! _NVM_LOADED )); then
            [ -s \"/opt/homebrew/opt/nvm/nvm.sh\" ] && source \"/opt/homebrew/opt/nvm/nvm.sh\"
            [ -s \"/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm\" ] && source \"/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm\"
            _NVM_LOADED=1
            if ! command -v node >/dev/null 2>&1; then
                nvm use default >/dev/null 2>&1
            fi
        fi
        (( \${+functions[_load_nvmrc]} )) && _load_nvmrc
        if [[ \"\$cmd\" == \"nvm\" ]]; then
            nvm \"\$@\"
        else
            command \"\$cmd\" \"\$@\"
        fi
    }"
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
        _ensure_nvm_loaded
        local nvmrc_node_version
        nvmrc_node_version=$(nvm version "$(cat "$nvmrc_path")")
        if [[ "$nvmrc_node_version" == "N/A" ]]; then
            nvm install
        elif [[ "$nvmrc_node_version" != "$(nvm version)" ]]; then
            nvm use
        fi
    elif (( _NVM_LOADED )) && [[ "$(nvm version)" != "$(nvm version default)" ]]; then
        echo "Reverting to nvm default version"
        nvm use default
    fi
}

add-zsh-hook chpwd _load_nvmrc
