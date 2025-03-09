# Load shared ZSH config
source $HOME/.dotfiles/shared/configs/.zshrc
source $HOME/.dotfiles/shared/configs/zsh/docker.zsh
source $HOME/.dotfiles/shared/configs/zsh/go.zsh
source $HOME/.dotfiles/shared/configs/zsh/nvm.zsh

function cleanup() {
  snap list --all | awk '/disabled/{print $1, $3}' |
    while read snapname revision; do
        sudo snap remove "$snapname" --revision="$revision"
    done
}

# Runs daily updates
function rup() {
  sudo snap refresh
  cleanup
  flatpak update
  flatpak uninstall --unused
  sudo apt-get update -y
  sudo apt-get dist-upgrade -o APT::Get::Always-Include-Phased-Updates=true -y
  sudo apt-get autoremove -y
  brew update
  brew upgrade --quiet
  brew cleanup --prune=all --quiet
  mise use -g node@lts
  mise upgrade --bump go
  npm update -g npm
  udc
  omz update
  update_repos
  update_dotfiles
  szh
}

# Configure GoLang
export CGO_ENABLED=0

# Setup Homebrew
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"