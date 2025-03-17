# Load shared ZSH config
source $HOME/.dotfiles/shared/configs/.zshrc
source $HOME/.dotfiles/shared/configs/zsh/docker.zsh
source $HOME/.dotfiles/shared/configs/zsh/mise.zsh
source $HOME/.dotfiles/shared/configs/zsh/php.zsh

# Runs daily updates
function rup() {
  brew update
  brew upgrade --quiet
  brew upgrade --cask --greedy --quiet
  brew cleanup --prune=all --quiet
  omz update
  mise use -g node@lts
  mise upgrade --bump go
  npm update -g npm
  update_repos
  update_dotfiles
  szh
}