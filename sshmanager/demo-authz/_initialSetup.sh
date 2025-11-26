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

mkdir -p "${DEMO_ROOT}/tmp"
get_root_cert_from "https://jhtpp253.lab.securafi.net" "${DEMO_ROOT}/tmp/root-ca-bundle.pem"

${DOCKER_CMD} build -t "${DOCKER_IMAGE_NAME}" -f "${DEMO_ROOT}/docker/Dockerfile" "${DEMO_ROOT}/docker"