# Load shared ZSH config
source $HOME/.dotfiles/shared/configs/zsh/docker.zsh
source $HOME/.dotfiles/shared/configs/zsh/go.zsh
source $HOME/.dotfiles/shared/configs/.zshrc

# Last, so the mise shims land ahead of /opt/homebrew/bin (which .zshrc
# prepends) and mise stays the source of truth for the tools it manages.
source $HOME/.dotfiles/shared/configs/zsh/mise.zsh