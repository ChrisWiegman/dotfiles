# Load shared ZSH config
source $HOME/.dotfiles/shared/configs/.zshrc
source $HOME/.dotfiles/shared/configs/zsh/docker.zsh
source $HOME/.dotfiles/shared/configs/zsh/go.zsh
source $HOME/.dotfiles/shared/configs/zsh/nvm.zsh

# Runs daily updates
function rup() {
  echo "Updating Homebrew..."
  command brew update
  command brew upgrade --quiet
  command brew upgrade --cask --greedy --quiet
  command brew cleanup --prune=all --quiet
  echo "Updating macOS software..."
  softwareupdate -i -a
  echo "Updating Oh My Zsh..."
  omz update
  echo "Updating Node..."
  inode
  echo "Updating repos..."
  update_repos
  echo "Updating dotfiles..."
  update_dotfiles
  echo "Reloading shell..."
  szh
}