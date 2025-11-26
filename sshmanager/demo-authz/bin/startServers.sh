#!/usr/bin/env bash
set -euo pipefail

SCRIPT_ROOT=${SCRIPT_ROOT:-$(dirname "$(realpath "${0}")")}

scriptRoot=$(dirname "$(realpath "${0}")")
source "$(dirname "$(realpath "${0}")")/lib/_lib.sh" 
common_init

# Check if an argument is provided
while :; do
  if [ ! -z "${1:-}" ]; then
    NUM_SERVERS="${1}"
  elif [ -z "${NUM_SERVERS:-}" ]; then
    printf "\n${YELLOW}${BOLD}Number of servers to start [1-20]: ${RESET}" >&2 
    read -r NUM_SERVERS
    echo >&2;
  fi

  # Must be numeric
  if ! [[ "$NUM_SERVERS" =~ ^[0-9]+$ ]]; then
    printf "\n${YELLOW}${BOLD}\tPlease enter a numeric value [1-20]: ${RESET}" >&2 
    continue
  fi

  # Must be between 1 and 20
  if [ "$NUM_SERVERS" -lt 1 ] || [ "$NUM_SERVERS" -gt 20 ]; then
    printf "\n${YELLOW}${BOLD}\tPlease enter a value between 1 and 20: ${RESET}" >&2 
    continue
  fi

  break
done

# Remove old directories
if [ -d "${VOL_DIR}/servers" ]; then
  rm -r "${VOL_DIR}/servers"/*
fi
if [ -d "${VOL_DIR}/logs" ]; then
  rm -r "${VOL_DIR}/logs"/*
fi

FILE_SERVERNAMES="${SCRIPT_ROOT}/res/servernames.txt"
[ -f "${FILE_SERVERNAMES}" ] || die "Unable to find servernames resource file: ${FILE_SERVERNAMES}"

servernames=()
while read -r first _; do
  # Skip empty lines and lines whose first non-whitespace char is '#'
  [[ -z "${first}" || "${first}" == \#* ]] && continue

  # Take only the first word on the line
  servernames+=("${first}")
done < "${FILE_SERVERNAMES}"

debug "Loaded server names from: '${BOLD}${FILE_SERVERNAMES}${RESET}'"

declare -a used

for ((i=0; i<${NUM_SERVERS}; i++)); do
  port=$((${START_PORT:-2000}+ ${i}))
  
  # Keep generating random indices until we find one that hasn't been used
  while true; do
    random_index=$((RANDOM % ${#servernames[@]}))
    # Check if this index is already in the used array
    found=false
    for used_index in ${used[@]:-}; do
      if [ "$used_index" -eq "${random_index}" ]; then
        found=true
        break
      fi
    done
    [ "$found" = false ] && break
  done
  
  used+=(${random_index})
  hostname="${servernames[${random_index}]}-${port}"
  info "Starting server: ${hostname} listening on port ${port}"

  out=$(${DOCKER_CMD} run --rm -d -v "${VOL_DIR}":"/ussh-data" -p ${port}:22 --name "${hostname}" --hostname "${hostname}" ${DOCKER_IMAGE_NAME} 2>&1) \
    || warn "Failed to start server ${hostname}: ${out}"
done
