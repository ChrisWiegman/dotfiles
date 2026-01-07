# ---- Homebrew first (so PATH/FPATH are set before OMZ loads) ----
[ -s "/opt/homebrew/bin/brew" ] && eval "$(/opt/homebrew/bin/brew shellenv)"
[ -s "/home/linuxbrew/.linuxbrew/bin/brew" ] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Hide extra homebrew hints
export HOMEBREW_NO_ENV_HINTS=1

# ---- Oh My Zsh ----
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="fwalch"
ENABLE_CORRECTION="true"
plugins=(sudo)

source "$ZSH/oh-my-zsh.sh"

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

# ---- Completion niceties ----
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# ---- Editor ----
export EDITOR="${EDITOR:-vim}"

# ---- Aliases ----
alias fdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
alias gup="git fetch --all --prune; git pull --ff-only; git gc"
alias mip="dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com"
alias szh='echo "Reloading shell..."; source ~/.zshrc'


update_ohmyzsh() {
  echo "Updating Oh My Zsh..."; omz update;
}

# ---- Update Homebrew packages and casks ----
update_homebrew() {
  command brew update
  command brew upgrade --quiet
  command brew upgrade --cask --greedy --quiet
  command brew cleanup --prune=all --quiet
}

# ---- Update repos in ~/Code (depth 2, real) ----
update_repos() {
  echo "Updating code repositories"
  local CODE_DIR="$HOME/Code"
  [[ -d "$CODE_DIR" ]] || { echo "$CODE_DIR does not exist. Skipping repo update."; return 0; }

  local gitdirs
  gitdirs=("${(@f)$(find "$CODE_DIR" -maxdepth 2 -type d -name ".git" 2>/dev/null)}")
  [[ ${#gitdirs[@]} -gt 0 ]] || { echo "No git repositories found in $CODE_DIR. Skipping repo update."; return 0; }

  local repo
  for repo in "${gitdirs[@]}"; do
    local repodir="${repo:h}"
    echo "Updating ${repodir}"
    pushd "$repodir" > /dev/null || continue
    gup
    popd > /dev/null
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
  [[ $(typeset -f update_homebrew) ]] && update_homebrew
  [[ $(typeset -f update_ohmyzsh)  ]] && update_ohmyzsh
  [[ $(typeset -f szh)             ]] && szh
}

# ---- PATH (prefer not to hardcode /usr/local on Apple Silicon, but harmless) ----
export PATH="/usr/local/sbin:$PATH"
