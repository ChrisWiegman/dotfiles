# Load shared ZSH config
source $HOME/.dotfiles/shared/configs/.zshrc
source $HOME/.dotfiles/shared/configs/zsh/docker.zsh
source $HOME/.dotfiles/shared/configs/zsh/go.zsh
source $HOME/.dotfiles/shared/configs/zsh/nvm.zsh
source $HOME/.dotfiles/shared/configs/zsh/php.zsh

# Runs daily updates
function rup() {
  brew update
  brew upgrade --quiet
  brew upgrade --cask --greedy --quiet
  brew cleanup --prune=all --quiet
  softwareupdate -i -a
  omz update
  inode
  update_repos
  update_dotfiles
  szh
}