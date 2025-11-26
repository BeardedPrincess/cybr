#!/usr/bin/env bash
############################################################################
# Initial setup script for demo-authz
# This script sets up the necessary environment for the authzhelper demo
# and validates prerequisites.
#
# Usage: /bin/sh _initialSetup.sh
set -euo pipefail

SCRIPT_ROOT=${SCRIPT_ROOT:-$(dirname "$(realpath "${0}")")}
GIT_CMD="${GIT_CMD:-$(command -v git)}"

echo -e "\033[37m[INFO]\033[0mPulling latest updates from git repository..." >&2
pushd "${SCRIPT_ROOT}" > /dev/null 2>&1
out=$(${GIT_CMD} pull 2>&1) || echo -e "\033[33m[WARN]\t..failed to pull updates from git: \n${DIM}\t$out${RESET}" >&2
popd > /dev/null 2>&1

source "$(dirname "$(realpath "${0}")")/lib/_lib.sh" 
common_init

# Add the script bin to the path if it's not already there
if [ "${SHELL}" = "/bin/bash" ]; then
  grep -q "${DEMO_ROOT}/bin" "${HOME}/.bashrc" || (echo "PATH=\"${PATH}:${DEMO_ROOT}/bin\"" >> "${HOME}/.bashrc" && \
    info "Added ${DEMO_ROOT}/bin to PATH in ~/.bashrc for future sessions. Restart your shell or run: '${BOLD}source ~/.bashrc${RESET}'")
elif [ "${SHELL}" = "/bin/zsh" ]; then
  grep -q "${DEMO_ROOT}/bin" "${HOME}/.zshrc" || (echo "PATH=\"${PATH}:${DEMO_ROOT}/bin\"" >> "${HOME}/.zshrc" && \
    info "Added ${DEMO_ROOT}/bin to PATH in ~/.zshrc for future sessions. Restart your shell or run: '${BOLD}source ~/.zshrc${RESET}'")
fi

${CMD_FIND:-$(command -v find)} "${DEMO_ROOT}/bin" "${PWD}" -type f -iname "*.sh" -exec chmod 0755 {} +
debug "Set execute permissions on scripts in ${DEMO_ROOT}/bin/"

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
