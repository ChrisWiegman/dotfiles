# ---- Homebrew first (so PATH/FPATH are set before completions load) ----
# Cache shellenv output — re-generate only when the brew binary changes
_brew_cache="${XDG_CACHE_HOME:-$HOME/.cache}/brew_shellenv.sh"
if [ -s "/opt/homebrew/bin/brew" ]; then
    if [[ ! -f "$_brew_cache" || "/opt/homebrew/bin/brew" -nt "$_brew_cache" ]]; then
        mkdir -p "${_brew_cache:h}"
        /opt/homebrew/bin/brew shellenv >| "$_brew_cache"
    fi
    source "$_brew_cache"
fi
unset _brew_cache

# Hide extra homebrew hints
export HOMEBREW_NO_ENV_HINTS=1

# ---- Prompt: bold green path, blue parens, red branch, yellow dirty markers ----
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:git:*' unstagedstr $' \u2716'
zstyle ':vcs_info:git:*' stagedstr ' +'
zstyle ':vcs_info:git:*' formats ' %F{blue}(%f%F{red}%b%F{blue})%f%F{yellow}%u%c%f'
zstyle ':vcs_info:git:*' actionformats ' %F{blue}(%f%F{red}%b|%a%F{blue})%f%F{yellow}%u%c%f'
precmd() {
  vcs_info
  if [[ "$PWD" == "$HOME" ]]; then
    _pdir="~"
  elif [[ "$PWD" == "$HOME/"* ]]; then
    _pdir="${PWD#$HOME/}"
  else
    _pdir="$PWD"
  fi
}
setopt PROMPT_SUBST
PROMPT='%B%F{green}${_pdir}%f%b${vcs_info_msg_0_} '

# ---- Spell correction ----
setopt CORRECT

# ---- sudo escape (ESC ESC prepends sudo to current command) ----
_sudo-command-line() {
    [[ -z $BUFFER ]] && zle up-history
    [[ $BUFFER != sudo\ * ]] && BUFFER="sudo $BUFFER"
    zle end-of-line
}
zle -N _sudo-command-line
bindkey "\e\e" _sudo-command-line

# ---- History (good shared defaults) ----
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=50000
export SAVEHIST=50000
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS

# Search history by the text already typed, like old OMZ behavior
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search
bindkey "${terminfo[kcuu1]}" up-line-or-beginning-search
bindkey "${terminfo[kcud1]}" down-line-or-beginning-search

# ---- Completion niceties ----
autoload -Uz compinit
if [[ -n ${HOME}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# ---- Editor ----
export EDITOR="${EDITOR:-vim}"

# ---- ls colors ----
if ls --color=auto /dev/null &>/dev/null; then
  alias ls='ls --color=auto'
else
  export CLICOLOR=1
fi

# ---- Aliases ----
alias fdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
alias gup="git fetch --all --prune; git pull --ff-only"
alias mip="dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com"
alias szh='echo "Reloading shell..."; source ~/.zshrc'


# ---- Update Homebrew packages and casks ----
update_homebrew() {
  command brew update --quiet
  command brew upgrade --quiet
  command brew upgrade --cask --greedy --quiet
  command brew cleanup --prune=all --quiet
}

# ---- Update Mac App Store apps ----
update_app_store() {
  [[ "$OSTYPE" == darwin* ]] || return 0

  if ! command -v mas >/dev/null 2>&1; then
    echo "mas not installed. Skipping Mac App Store updates."
    return 0
  fi

  echo "Updating Mac App Store apps"
  command mas upgrade --accurate || echo "Mac App Store update failed (check App Store sign-in)"
}

# ---- Update repos in ~/Code (depth 2, real) ----
update_repos() {
  echo "Updating code repositories"
  local CODE_DIR="$HOME/Code"
  [[ -d "$CODE_DIR" ]] || { echo "$CODE_DIR does not exist. Skipping repo update."; return 0; }

  local gitdirs
  gitdirs=("${(@f)$(find "$CODE_DIR" -maxdepth 2 -type d -name ".git" 2>/dev/null)}")
  [[ ${#gitdirs[@]} -gt 0 ]] || { echo "No git repositories found in $CODE_DIR. Skipping repo update."; return 0; }

  local repo repodir
  for repo in "${gitdirs[@]}"; do
    repodir="${repo:h}"
    echo "  -> ${repodir:t}"

    # Skip dirty working trees
    if ! git -C "$repodir" diff --quiet 2>/dev/null || \
       ! git -C "$repodir" diff --cached --quiet 2>/dev/null; then
      echo "     skipping (uncommitted changes)"
      continue
    fi

    # Fetch with prune — bail gracefully if offline or unreachable
    if ! git -C "$repodir" fetch --all --prune --quiet 2>/dev/null; then
      echo "     fetch failed (offline or unreachable)"
      continue
    fi

    # Only pull if an upstream branch is configured
    if ! git -C "$repodir" rev-parse --abbrev-ref --symbolic-full-name @{u} &>/dev/null; then
      echo "     no upstream configured, skipping pull"
      continue
    fi

    git -C "$repodir" pull --ff-only --quiet 2>/dev/null || echo "     pull failed (try manually)"
  done
}

# ---- Update dotfiles ----
update_dotfiles() {
  echo "Updating dotfiles"
  local DOT="$HOME/.dotfiles"
  [[ -d "$DOT/.git" ]] || { echo "$DOT is not a git repo. Skipping."; return 0; }

  pushd "$DOT" > /dev/null || return 0
  gup
  popd > /dev/null

  szh
}

# ---- Local overrides ----
[ -f ~/.local.zsh ] && source ~/.local.zsh

# ---- Daily runner (runs once per day) ----
rup() {
  [[ $(typeset -f update_repos)    ]] && update_repos
  [[ $(typeset -f update_dotfiles) ]] && update_dotfiles

  local stamp="${XDG_CACHE_HOME:-$HOME/}/.rup.last"
  mkdir -p "${stamp:h}"

  local today="$(date +%Y-%m-%d)"
  if [[ -f "$stamp" ]] && [[ "$(cat "$stamp")" == "$today" ]]; then
    return 0
  fi
  print -r -- "$today" >| "$stamp"

  [[ $(typeset -f inode)           ]] && inode
  [[ $(typeset -f update_app_store) ]] && update_app_store
  [[ $(typeset -f update_homebrew) ]] && update_homebrew
  [[ $(typeset -f szh)             ]] && szh
}
