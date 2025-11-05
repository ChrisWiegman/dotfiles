# oh-my-zsh path
export ZSH="$HOME/.oh-my-zsh"

# oh-my-zsh theme
ZSH_THEME="fwalch"

# zsh autocorrection
ENABLE_CORRECTION="true"

# Hide extra homebrew hints
HOMEBREW_NO_ENV_HINTS="false"

# oh-my-zsh plugins
plugins=(sudo)

# Load oh-my-zsh
source $ZSH/oh-my-zsh.sh

# Launch Homebrew
[ -s "/opt/homebrew/bin/brew" ] && eval "$(/opt/homebrew/bin/brew shellenv)"
[ -s "/home/linuxbrew/.linuxbrew/bin/brew" ] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Aliases and functions
alias fdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
alias gup="git fetch --all --prune; git pull; git gc"
alias mip="dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com"
alias szh="echo \"Reloading shell...\"; source ~/.zshrc"
alias update_ohmyzsh="echo \"Updating Oh My Zsh...\"; omz update"

# Update Homebrew packages and casks
function update_homebrew() {
  command brew update
  command brew upgrade --quiet
  command brew upgrade --cask --greedy --quiet
  command brew cleanup --prune=all --quiet
}

# Pull all the repose in my "Code" directory
function update_repos() {
  echo "Updating code repositories"
  CODE_DIR="$HOME/Code"
  if [ ! -d "$CODE_DIR" ]; then
    echo "$CODE_DIR does not exist. Skipping repo update."
    exit 0
  fi

  REPOS=$(find "$CODE_DIR" -maxdepth 2 -type d -name ".git" 2>/dev/null)
  if [ -z "$REPOS" ]; then
    echo "No git repositories found in $CODE_DIR. Skipping repo update."
    return
  fi
  local repo_dirs
  repo_dirs=(~/Code/*/)
  if [[ -d ~/Code && ${#repo_dirs[@]} -gt 0 ]]; then
    for D in "${repo_dirs[@]}"; do
      if [ -d "${D}" ]; then
        echo "Updating ${D}"
        pushd "${D}" > /dev/null
        gup
        popd > /dev/null
      fi
    done
  fi
}

# Runs daily updates
function rup() {
  [[ $(typeset -f update_repos)    ]] && update_repos
  [[ $(typeset -f update_dotfiles) ]] && update_dotfiles
  [[ $(typeset -f update_homebrew) ]] && update_homebrew
  [[ $(typeset -f update_ohmyzsh)  ]] && update_ohmyzsh
  [[ $(typeset -f inode)           ]] && inode
  [[ $(typeset -f szh)             ]] && szh
}

# Update my dotfiles repo automagically
function update_dotfiles() {
  echo "Updating dotfiles"
  cd $HOME/.dotfiles
  gup
  cd "$OLDPWD"
  szh
}

# Update system path
export PATH="/usr/local/sbin:$PATH"

# Source local ZSH config if it exists
[ -f ~/.local.zsh ] && source ~/.local.zsh