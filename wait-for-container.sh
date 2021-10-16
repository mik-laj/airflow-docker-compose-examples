#!/usr/bin/env bash

set -euo pipefail

timeout=300
CMDNAME="$(basename -- "$0")"

function usage() {
  cat << EOF
Usage: ${CMDNAME} <container_id>

Waits for the container to be in a healthy condition.

POSITIONAL ARGUMENTS:
  container_id    Id of docker container

OPTIONAL ARGUMENTS:
  -h, --help          Show this help message and exit
  -t, --timeout       The maximum waiting time for the container to start in seconds. By detault, ${timeout} seconds

EXAMPLE:
  $ docker-compose ps -q | xargs -n 1 -P 8 ${CMDNAME}
EOF

}

if [[ "$#" -ne 1 ]]; then
    echo "You must provide a one argument."
    echo
    usage
    exit 1
fi

set +e

getopt -T >/dev/null
GETOPT_RETVAL=$?
set -e

if [[ ${GETOPT_RETVAL} != 4 ]]; then
    echo
    if [[ $(uname -s) == 'Darwin' ]] ; then
        echo "You are running ${CMDNAME} in OSX environment"
        echo "And you need to install gnu commands"
        echo
        echo "Run 'brew install gnu-getopt coreutils'"
        echo
        echo "Then link the gnu-getopt to become default as suggested by brew by typing:"
        echo "echo 'export PATH=\"/usr/local/opt/gnu-getopt/bin:\$PATH\"' >> ~/.bash_profile"
        echo ". ~/.bash_profile"
        echo
        echo "Login and logout afterwards"
        echo
    else
        echo "You do not have necessary tools in your path (getopt)."
        echo "Please install latest/GNU version of getopt."
        echo "This can usually be done with 'apt install util-linux'"
    fi
    echo
    exit 1
fi

if ! PARAMS=$(getopt \
    -o "${_SHORT_OPTIONS:=}" \
    -l "${_LONG_OPTIONS:=}" \
    --name "$CMDNAME" -- "$@")
then
    usage
    exit 1
fi
eval set -- "${PARAMS}"
unset PARAMS


# Parse Flags.
while true
do
  case "${1}" in
    -h|--help)
      usage;
      exit 0 ;;
    -t|--timeout)
      timeout="${2}";
      shift 2 ;;
    --)
      shift ;
      break ;;
    *)
      usage
      echo "ERROR: Unknown argument ${1}"
      exit 1
      ;;
  esac
done

CONTAINER_ID="$1"

function wait_for_container {
    start_timestamp=$(date +%s)

    container_id="$1"
    container_name="$(docker inspect "${container_id}" --format '{{ .Name }}')"
    echo "Waiting for container: ${container_name} [${container_id}]"
    waiting_done="false"
    while [[ "${waiting_done}" != "true" ]]; do
        container_state="$(docker inspect "${container_id}" --format '{{ .State.Status }}')"
        if [[ "${container_state}" == "running" ]]; then
            health_status="$(docker inspect "${container_id}" --format '{{ .State.Health.Status }}')"
            echo "${container_name}: container_state=${container_state}, health_status=${health_status}"
            if [[ ${health_status} == "healthy" ]]; then
                waiting_done="true"
            fi
        else
            echo "${container_name}: container_state=${container_state}"
            waiting_done="true"
        fi
        current_timestamp=$(date +%s)
        if [[ "${timeout}" != "0" ]]; then
            if [[ "$(( current_timestamp - start_timestamp ))" -gt "${timeout}" ]]; then
                ecoh "Timeout. The operation takes longer than the maximum waiting time (${timeout}s)"
                exit 1
            fi
        fi
        sleep 1;
    done;
}

if ! command -v docker; then
    echo 'The "docker" command found.'
    exit 1
fi

if ! docker inspect "${CONTAINER_ID}" &>/dev/null; then
    echo "Container does not exists"
    exit 1
fi

wait_for_container "$CONTAINER_ID"
