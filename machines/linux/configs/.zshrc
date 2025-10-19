# Load shared ZSH config
source $HOME/.dotfiles/shared/configs/.zshrc

# Runs daily updates
function rup() {
  brew update
  brew upgrade --quiet
  brew upgrade --cask --greedy --quiet
  brew cleanup --prune=all --quiet
  sudo apt-get update
  sudo apt-get dist-upgrade -y
  sudo apt-get clean
  sudo snap refresh
  omz update
  inode
  update_repos
  update_dotfiles
  szh
}