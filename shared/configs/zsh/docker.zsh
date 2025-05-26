# Aliases and functions
alias dsp="dka; docker system prune -a -f"

# Kills all running docker containers and prunes all but the images
function dka() {
    docker kill $(docker ps -q)
    docker container prune -f
    docker network prune -f
    docker volume prune -f
}