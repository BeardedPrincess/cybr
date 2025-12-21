#!/usr/bin/env bash
set -euo pipefail

SCRIPT_ROOT=${SCRIPT_ROOT:-$(dirname "$(realpath "${0}")")}

# Initialize all vars
${SCRIPT_ROOT}/initVars.sh 2>&1
source /tmp/.env

# Start SSHD
${SCRIPT_ROOT}/startSSHD.sh >> ${logDir}/startSSHD.log 2>&1

# Create users
${SCRIPT_ROOT}/createUsers.sh >> ${logDir}/createUsers.log 2>&1

# Start the SSH connection script in the background
while :; do
    ${SCRIPT_ROOT}/connectSSH.sh >> ${logDir}/ssh-client.log 2>&1
    # Sleep for a random time between 5 and 8 seconds before next connection attempt
    sleep $((RANDOM % 4 + 5))
done