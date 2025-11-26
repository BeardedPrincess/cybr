#!/bin/bash
############################################################################
# Initial setup script for demo-authz
# This script sets up the necessary environment for the authzhelper demo
# and validates prerequisites.
#
# Usage: /bin/sh _initialSetup.sh
set -euo pipefail

DEMO_ROOT=${DEMO_ROOT:-$(dirname "$(realpath "${0}")")}

if [ ! -f ${DEMO_ROOT}/.env ]; then
  if [ ! -f ${DEMO_ROOT}/.env-SAMPLE ]; then
    echo -e "${RED}[FATAL] ${DEMO_ROOT}/.env and ${DEMO_ROOT}/.env-SAMPLE not found, cannot continue${RESET}"
    exit 1
  fi
  cp ${DEMO_ROOT}/.env-SAMPLE ${DEMO_ROOT}/.env
  echo -e "${RED}[FATAL] ${DEMO_ROOT}/.env did not exist, it has been created from .env-SAMPLE. Please review, update, and try again.${RESET}"
  exit 1
fi

source "${DEMO_ROOT}/bin/_lib.sh" 
common_init
check_global_prereqs


# Set variables used in this script
ROOT_PEM_FILE="${DEMO_ROOT}/tmp/root-ca-bundle.pem"
mkdir -p "${DEMO_ROOT}/tmp"

# Retrieve the root certificate
get_root_cert_from "${TPP_HOST}" "${ROOT_PEM_FILE}"

# We need to make a copy of the root CA bundle for use inside the Docker container
cp "${ROOT_PEM_FILE}" "${DEMO_ROOT}/docker/src/root-ca-bundle.pem" > /dev/null

info "Building Docker image '${DOCKER_IMAGE_NAME}'"
out=$(${DOCKER_CMD} build -t "${DOCKER_IMAGE_NAME}" -f "${DEMO_ROOT}/docker/Dockerfile" "${DEMO_ROOT}/docker" 2>&1) || die "Failed to build Docker image: \n${DIM}${BOLD}$out${RESET}"
info "\t Image '${DOCKER_IMAGE_NAME}' built successfully"