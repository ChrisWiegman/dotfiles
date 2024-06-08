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
  flatpak update -y
  flatpak uninstall --unused -y
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

function cleanup() {
  snap list --all | awk '/disabled/{print $1, $3}' |
    while read snapname revision; do
        sudo snap remove "$snapname" --revision="$revision"
    done
}

# Configure GoLang
export CGO_ENABLED=0

# SSH config
export GPG_TTY="$(tty)"
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
gpgconf --launch gpg-agent

# Setup Homebrew
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
