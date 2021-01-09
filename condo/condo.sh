#!/bin/bash
#
# The Condo provides easy access to the local build environments.

set -e

source /usr/local/Condo/json.sh

env_names=()
env_name=""
env_index=""
verbose='false'

readonly CONDO_CONFIG="$HOME/.condo/condo.json"
readonly NAME_NOT_COUND_ERROR=2

###############################################################################
# Writes the given details to the STDOUT
###############################################################################
log() {
  if [[ "$verbose" = "true" ]]; then
    echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*"    
  fi
}

###############################################################################
# Writes the given details to the STDERR
###############################################################################
err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

###############################################################################
# Reads the input flags
###############################################################################
read_flags() {
  for arg in "$@"; do
    case "${arg}" in
      -h|--help)
        echo "The Condo provides easy access to the local build environments."
        echo " "
        echo "usage: $0 [command] [env-name]"
        echo " "
        echo "options:"
        echo "-h, --help          show brief help"
        echo "-v, --verbose       detailed logs"
        exit 0
        ;;
      -v|--verbose)
        readonly verbose='true'
        ;;
      *)
        ;;
    esac
  done
}



###############################################################################
# Loads environment names
###############################################################################
load_env_names () {
  for name in $(cat $CONDO_CONFIG | tokenize | parse | egrep '\[*,\"name\"\]' | awk '{$1=""; print $0}' | awk '{$1=$1};1' | sed 's/^"\(.*\)"$/\1/'); do
    env_names+=("$name")
    log "Adding environment name to the list, name: $name"
  done
  readonly env_names
}

###############################################################################
# Loads environment name and index for command execution
# Arguments:
#   Name of the environment to be loaded, a string
# Outputs:
#   env_name
#   env_index
###############################################################################
load_env () {
  log "Loading environment details for '$1'"
  for i in "${!env_names[@]}"; do
    if [[ "$1" = "${env_names[$i]}" ]]; then
      readonly env_name=${env_names[$i]}
      readonly env_index=$i
      log "Environment found, name: '${env_names[$i]}', index: $i."
      return
    fi
  done
  err "Environment not found, name: '$1'."
  exit $NAME_NOT_COUND_ERROR
}

###############################################################################
# Starts a docker container with the given name
# Arguments:
#   Name for the docker container
###############################################################################
start_docker_container () {
  log "Starting build environment '$1'"
  docker start $1
  log "Build environment '$1' started successfully"
}

###############################################################################
# Runs a docker container with the given name
# Arguments:
#   Name for the docker container
#   Additional arguments
#   Docker image name
###############################################################################
run_docker_container () {
  log "Run docker container name:'$1', additional-arguments:'$2', image:'$3'"
  docker run -dit --name $1 $2 $3
  log "Docker image run successfully"
}

###############################################################################
# Attach to an existing containers
# Arguments:
#   Name for the docker container
#   Command
###############################################################################
attach_to_container () {
  log "Attaching to the container name:'$1', command:'$2'"
  docker exec -it $1 $2
  log "Successfully atttaching to the container name:'$1', command:'$2'"
}

###############################################################################
# Prepere an environment
# Arguments:
#   Name for the docker container
###############################################################################
prepare_environment () {
  log "Prepare environment, name:'$1'"
  
  local container_image=$(cat $CONDO_CONFIG | tokenize | parse | egrep '\['$env_index',\"image\"\]' | awk '{$1=""; print $0}' | awk '{$1=$1};1' | sed 's/^"\(.*\)"$/\1/')
  local additional_arguments=$(cat $CONDO_CONFIG | tokenize | parse | egrep '\['$env_index',\"additional-arguments\"\]' | awk '{$1=""; print $0}' | awk '{$1=$1};1' | sed 's/^"\(.*\)"$/\1/')
  local exec_command=$(cat $CONDO_CONFIG | tokenize | parse | egrep '\['$env_index',\"exec-command\"\]' | awk '{$1=""; print $0}' | awk '{$1=$1};1' | sed 's/^"\(.*\)"$/\1/')
  
  log "Details extracted from the configuration. image: $container_image, additional_arguments: $additional_arguments, exec_command: $exec_command"
  
  if [[ -z "$additional_arguments" ]]; then
    additional_arguments=""
  fi

  if [[ -z "$exec_command" ]]; then
    exec_command="/bin/bash"
  fi
  
  log "Setting defaults for missing values, additional_arguments: $additional_arguments, exec_command: $exec_command"

  local existing_container_id=$(docker ps -a -f "name=$1" --format "{{.ID}}")
  if [[ -z "$existing_container_id" ]]; then
    log "Starting a new environment. name: $1"
    run_docker_container $1 "$additional_arguments" "$container_image"
    attach_to_container $1 "$exec_command"
  else
    log "Starting the existing environment. name: $1"
    start_docker_container $1
    attach_to_container $1 "$exec_command"
  fi
}

###############################################################################
# Stops the environment
# Arguments:
#   Name for the docker container
###############################################################################
stop () {
  log "Stopping the environment, name:'$1'"

  local container_state=$(docker ps -a -f "name=$1" --format "{{.State}}")
  if [[ -z "$container_state" ]]; then
    log "The environment does not exist to stop. name: $1"
  else
    if [[ "$container_state" == "running" ]]; then
      docker stop $1
      log "Environment stopped. name: $1"
      echo "Environment stopped successfully"
    else
      log "Environment is not in the running state to stop. name: $1, state: $container_state"
    fi
  fi
}

###############################################################################
# Clean the environment
# Arguments:
#   Name for the docker container
###############################################################################
clean_environment () {
  local container_state=$(docker ps -a -f "name=$1" --format "{{.State}}")
  if [[ -z "$container_state" ]]; then
    log "The environment does not exist to clean. name: $1"
  else
    if [[ "$container_state" == "running" ]]; then
      docker stop $1
    fi
    docker container rm $1
    echo "Environment cleaned successfully"
  fi
}

###############################################################################
# Cleaning the environment
# Arguments:
#   Name for the docker container
###############################################################################
clean () {
  log "Cleaning the environment, name:'$1'"
  
  stop $1

  local container_state=$(docker ps -a -f "name=$1" --format "{{.State}}")
  if [[ -z "$container_state" ]]; then
    log "The environment does not exist to clean. name: $1"
  else
    docker container rm $1
    log "Environment, '$1', cleaned successfully"
  fi
}

###############################################################################
# Lists the environment
# Arguments:
#   Name for the docker container
###############################################################################
list () {
  log "Listing the environments"

  local line='          '
  if (( ${#env_names[@]} > 0 )); then
    for name in "${env_names[@]}"; do
      local container_state=$(docker ps -a -f "name=$name" --format "{{.State}}")
      if [[ -z "$container_state" ]]; then
        container_state="not started"
      fi
      printf "%s %s $container_state\n" $name "${line:${#name}}"
    done
  else
    echo "No environments available"
  fi    
}

read_flags "$@"
load_env_names

case $1 in    
  # Stop an environment
  "stop")
    load_env $2
    stop $env_name
    ;;
    
  # List all environments
  "list") 
    list
    ;;

  # Clean an environment
  "clean") 
    load_env $2
    clean $env_name
    ;;

  # Starts an environment
  *)
    load_env $1
    prepare_environment $env_name
    ;;
esac
