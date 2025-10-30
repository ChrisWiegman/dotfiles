# Load shared ZSH config
source $HOME/.dotfiles/shared/configs/.zshrc

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
  echo "Updating dotfiles..."
  update_dotfiles
  echo "Reloading shell..."
  szh
}