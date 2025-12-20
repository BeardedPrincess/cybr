#!/usr/bin/env bash
set -euo pipefail

SCRIPT_ROOT=${SCRIPT_ROOT:-$(dirname "$(realpath "${0}")")}

scriptRoot=$(dirname "$(realpath "${0}")")
source "$(dirname "$(realpath "${0}")")/lib/_lib.sh" 
common_init

# Get a list of running containers, based on our image
image_ancestor=$(${DOCKER_CMD} images -q "${DOCKER_IMAGE_NAME}") || die "Failed to get image id for ${DOCKER_IMAGE_NAME}"
running_ids=$(${DOCKER_CMD} container ps -q --filter ancestor=${image_ancestor}) || die "Failed to get running containers"
image_ancestor=$(${DOCKER_CMD} images -q "${DOCKER_IMAGE_NAME}") > /dev/null 2>&1 || die "Failed to get image id for ${DOCKER_IMAGE_NAME}"
running_ids=$(${DOCKER_CMD} container ps -q --filter ancestor=${image_ancestor}) || die "Failed to get running containers"
if [ -z "${running_ids}" ]; then
  info "No running containers found for image '${DOCKER_IMAGE_NAME}'. Nothing to stop."
  exit 0
fi

info "Stopping running containers for image '${DOCKER_IMAGE_NAME}'..."
result=$(${DOCKER_CMD} container stop ${running_ids} 2>&1) || die "Failed to stop running containers: ${result}"


