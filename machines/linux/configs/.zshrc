# Update Docker-compose
function udc() {
  VERSION=$(curl --silent https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K.*\d')
  DESTINATION=/usr/local/bin/docker-compose
  sudo curl -L https://github.com/docker/compose/releases/download/${VERSION}/docker-compose-$(uname -s)-$(uname -m) -o $DESTINATION
  sudo chmod 755 $DESTINATION
}

# Load shared ZSH config
source $HOME/.dotfiles/shared/configs/.zshrc

# Runs daily updates
function rup() {
  sudo snap refresh
  cleanup
  sudo apt-get update -y
  sudo apt-get dist-upgrade -y
  sudo apt-get autoremove -y
  brew update
  brew upgrade --quiet
  brew cleanup --prune=all --quiet
  inode
  udc
  omz update
  update_repos
  update_dotfiles
  szh
}

# SSH config
export GPG_TTY="$(tty)"
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
gpgconf --launch gpg-agent

function cleanup() {
  snap list --all | awk '/disabled/{print $1, $3}' |
    while read snapname revision; do
        sudo snap remove "$snapname" --revision="$revision"
    done
}

# Configure GoLang
export CGO_ENABLED=0

# Configure NVM
export NVM_DIR="$HOME/.nvm"
  [ -s "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh" ] && \. "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/home/linuxbrew/.linuxbrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/home/linuxbrew/.linuxbrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# Setup Homebrew
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
