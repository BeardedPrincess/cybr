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
out=$(${GIT_CMD} pull 2>&1) || echo -e "\033[33m[WARN]\t..failed to pull updates from git: \n\033[2m\t${out}\033[0m" >&2
popd > /dev/null 2>&1

source "${SCRIPT_ROOT}/lib/_lib.sh" 
common_init

mkdir -p "${DEMO_ROOT}/tmp/$$"
TMP_DIR="${DEMO_ROOT}/tmp/$$"

# Add the script bin to the path if it's not already there
if [ "${SHELL}" = "/bin/bash" ]; then
  grep -q "${DEMO_ROOT}/bin" "${HOME}/.bashrc" || (echo "PATH=\"${PATH}:${DEMO_ROOT}/bin\"" >> "${HOME}/.bashrc" && \
    info "Added ${DEMO_ROOT}/bin to PATH in ~/.bashrc for future sessions. Restart your shell or run: '${BOLD}source ~/.bashrc${RESET}'")
elif [ "${SHELL}" = "/bin/zsh" ]; then
  grep -q "${DEMO_ROOT}/bin" "${HOME}/.zshrc" || (echo "PATH=\"${PATH}:${DEMO_ROOT}/bin\"" >> "${HOME}/.zshrc" && \
    info "Added ${DEMO_ROOT}/bin to PATH in ~/.zshrc for future sessions. Restart your shell or run: '${BOLD}source ~/.zshrc${RESET}'")
fi

${CMD_FIND:-$(command -v find)} "${DEMO_ROOT}/bin" -type f -iname "*.sh" -exec chmod 0755 {} +
debug "Set execute permissions on scripts in ${DEMO_ROOT}/bin/"

${CMD_FIND:-$(command -v find)} "${VOL_DIR}/bin" -type f -iname "*.sh" -exec chmod 0755 {} +
debug "Set execute permissions on scripts in ${VOL_DIR}/bin/"

chmod 0600 "${SCRIPT_ROOT}/res/.ssh/ansible.key"

# Set variables used in this script
ROOT_PEM_FILE="${DEMO_ROOT}/tmp/root-ca-bundle.pem"
mkdir -p "${DEMO_ROOT}/tmp"

info "Validating connection to TPP server at ${TPP_HOST}..."
curl -o /dev/null -s -w "%{http_code}" --insecure "https://${TPP_HOST}/healthcheck" | grep -q "200" || \
  die "Failed to connect to TPP server at ${TPP_HOST}. Please ensure the TPP host is correct and reachable."

# Retrieve the root certificate
get_root_cert_from "${TPP_HOST}" "${ROOT_PEM_FILE}"

# We need to make a copy of the root CA bundle for use inside the Docker container
cp "${ROOT_PEM_FILE}" "${DEMO_ROOT}/docker/src/root-ca-bundle.pem" > /dev/null

info "Building Docker image '${DOCKER_IMAGE_NAME}'"
out=$(${DOCKER_CMD} build -t "${DOCKER_IMAGE_NAME}" -f "${DEMO_ROOT}/docker/Dockerfile" "${DEMO_ROOT}/docker" 2>&1) || die "Failed to build Docker image: \n${DIM}${BOLD}$out${RESET}"
info "\t Image '${DOCKER_IMAGE_NAME}' built successfully"

# Download the latest authz-helper release
info "Downloading latest authz-helper release from ${AUTHZ_SRC}..."

curl -o "${TMP_DIR}/authz-helper-latest.tgz" -s --cacert "${ROOT_PEM_FILE}" \
  "${AUTHZ_SRC}" || \
  die "Failed to download authz-helper. Please check your network connection and the AUTHZ_SRC URL."

tar -xzf "${TMP_DIR}/authz-helper-latest.tgz" -C "${TMP_DIR}" || \
  die "Failed to extract authz-helper archive"

cp "${TMP_DIR}/authzhelper" "${DEMO_ROOT}/tmp/authzhelper" || \
  die "Failed to copy authz-helper binary to ${DEMO_ROOT}/tmp/"

# Cleanup temporary files
rm -rf "${TMP_DIR}"