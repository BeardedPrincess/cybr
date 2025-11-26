#!/bin/bash
############################################################################
# Initial setup script for demo-authz
# This script sets up the necessary environment for the authzhelper demo
# and validates prerequisites.
#
# Usage: /bin/sh _initialSetup.sh
set -euo pipefail

source "${DEMO_ROOT:-${HOME}/demo-authz}/bin/_lib.sh" 
common_init
check_global_prereqs

# Set variables used in this script
ROOT_PEM_FILE="${DEMO_ROOT}/tmp/root-ca-bundle.pem"

# Installation pre-requisites


mkdir -p "${DEMO_ROOT}/tmp"
get_root_cert_from "https://jhtpp253.lab.securafi.net" "${ROOT_PEM_FILE}"

# We need to make a copy of the root CA bundle for use inside the Docker container
cp "${ROOT_PEM_FILE}" "${DEMO_ROOT}/docker/src/root-ca-bundle.pem" > /dev/null

info "Building Docker image '${DOCKER_IMAGE_NAME}'"
${DOCKER_CMD} build -t "${DOCKER_IMAGE_NAME}" -f "${DEMO_ROOT}/docker/Dockerfile" "${DEMO_ROOT}/docker"