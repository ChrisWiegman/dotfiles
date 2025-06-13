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
alias gup="git fetch --all --prune; git pull; git gc"
alias mip="dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com"
alias szh="source ~/.zshrc"

# Pull all the repose in my "Code" directory
function update_repos() {
  if [ "$(ls -A ~/Code)" ]; then
    for D in ~/Code/*/; do
      if [ -d "${D}" ]; then
        echo "Updating ${D}"
        cd "${D}"
        gup
        cd "$OLDPWD"
      fi
    done
  fi
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