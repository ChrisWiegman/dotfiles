# Aliases and functions
alias dsp="dka; docker system prune -a -f"

# Kills all running docker containers and prunes all but the images
function dka() {
    docker kill $(docker ps -q)
    docker container prune -f
    docker network prune -f
    docker volume prune -f
}

# Update Docker-compose
function udc() {
  VERSION=$(curl --silent https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K.*\d')
  DESTINATION=/usr/local/bin/docker-compose
  sudo curl -L https://github.com/docker/compose/releases/download/${VERSION}/docker-compose-$(uname -s)-$(uname -m) -o $DESTINATION
  sudo chmod 755 $DESTINATION
}