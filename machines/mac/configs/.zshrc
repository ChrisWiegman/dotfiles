# Load shared ZSH config
source $HOME/.dotfiles/shared/configs/.zshrc

# Runs daily updates
function rup() {
  brew update
  brew upgrade --quiet
  brew upgrade --cask --greedy --quiet
  brew cleanup --prune=all --quiet
  inode
  omz update
  update_repos
  update_dotfiles
  szh
}

# Configure Rust
export PATH="$HOME/.cargo/bin:$PATH"

# Configure NVM
export NVM_DIR="$HOME/.nvm"
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && . "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && . "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion