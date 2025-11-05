# Load shared ZSH config
source $HOME/.dotfiles/shared/configs/.zshrc

# Runs daily updates
function rup() {
  echo "Updating dotfiles..."
  update_dotfiles
  echo "Updating Homebrew..."
  command brew update
  command brew upgrade --quiet
  command brew upgrade --cask --greedy --quiet
  command brew cleanup --prune=all --quiet
  echo "Updating Oh My Zsh..."
  omz update
  echo "Reloading shell..."
  szh
}