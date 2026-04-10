# Aliases and functions
alias dsp="dka; docker system prune -a -f"

# Kills all running docker containers and prunes all but the images
function dka() {
    local running
    running=$(docker ps -q)
    [[ -n "$running" ]] && docker kill $running
    docker container prune -f
    docker network prune -f
    docker volume prune -f
}

# Load Docker CLI completions
if [ ! -d $HOME/.docker/completions ]; then
    mkdir -p $HOME/.docker/completions;
    docker completion zsh > $HOME/.docker/completions/_docker;
fi

export FPATH="$HOME/.docker/completions:$FPATH"
