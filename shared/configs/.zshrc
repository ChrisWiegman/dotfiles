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

# Aliases and functions
alias dsp="dka; docker system prune -a -f"
alias gup="git fetch --all --prune; git pull; git gc"
alias inode="nvm install --lts --latest-npm"
alias mip="dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com"
alias szh="source ~/.zshrc"

# Kills all running docker containers and prunes all but the images
function dka() {
    docker kill $(docker ps -q)
    docker container prune -f
    docker network prune -f
    docker volume prune -f
}

# Installs the specified Go version for easier development
function gover() {
  go install golang.org/dl/go"$@"@latest
  go"$@" download
}

# Pull all the repose in my "Code" directory
function update_repos() {
  for D in ~/Code/*/; do
    if [ -d "${D}" ]; then
      cd "${D}"
      echo "Updating ${D}"
      gup
      cd "$OLDPWD"
    fi
  done
}

# Update my dotfiles repo automagically
function update_dotfiles() {
  cd $HOME/.dotfiles
  gup
  cd "$OLDPWD"
  szh
}

# Configure GoLang
export GOPATH="$HOME/.go"

# Update system path
export PATH="/usr/local/sbin:$GOPATH/bin:$PATH"
