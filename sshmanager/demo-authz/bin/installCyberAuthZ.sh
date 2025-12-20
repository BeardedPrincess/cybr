#!/usr/bin/env bash
set -euo pipefail

SCRIPT_ROOT=${SCRIPT_ROOT:-$(dirname "$(realpath "${0}")")}

scriptRoot=$(dirname "$(realpath "${0}")")
source "$(dirname "$(realpath "${0}")")/lib/_lib.sh" 
common_init

RES_DIR="${SCRIPT_ROOT}/res"

# AuthZHelper Source
authZName='authzhelper'
authZSrc="${DEMO_ROOT}/tmp/${authZName}"
authZConfigSrc="${RES_DIR}/authz_config_template.yml"
rootBundleSrc="${DEMO_ROOT}/tmp/root-ca-bundle.pem"
sshdConf="${RES_DIR}/sshd_config_template.conf"

# Destinations for authZHelper
authZBin="/usr/local/bin/${authZName}"
authZConfDir="/var/opt/cyberark/sshmanager"
authZConf="${authZConfDir}/config.yml"

tgtIDs=($(${DOCKER_CMD} container ls -q --filter ancestor=${DOCKER_IMAGE_NAME}))

if [ ${#tgtIDs[@]} -gt 0 ]; then
  info "Installing on ${#tgtIDs[@]} target host(s)..."
else
  info "No targets running. Start servers first with 'startServers.sh <num_servers>'"
  exit 0
fi

confirmAll=false

if [ ! -f "${authZSrc}" ]; then
  die "AuthZ Helper binary not found at expected location: ${DEMO_ROOT}/tmp/${authZName}. Please run 'update-demo-authz.sh' to download the latest version."
fi

if [ ! -f "${rootBundleSrc}" ]; then
  die "Root CA bundle not found at expected location: ${DEMO_ROOT}/tmp/root-ca-bundle.pem. Please run 'update-demo-authz.sh' to download the latest version."
fi

for i in ${!tgtIDs[@]}; do
  tgtId=${tgtIDs[${i}]}
  tgtName=$(${DOCKER_CMD} inspect --format '{{ .Name }}' ${tgtId})
  tgtPort=$(${DOCKER_CMD} inspect --format '{{ (index (index .NetworkSettings.Ports "22/tcp") 0).HostPort }}' ${tgtId})
  sshCmd="ssh -i ${SCRIPT_ROOT}/res/.ssh/ansible.key -p ${tgtPort} ansible@localhost"
  scpCmd="scp -i ${SCRIPT_ROOT}/res/.ssh/ansible.key -P ${tgtPort}" 

  if [ "${confirmAll}" = false ]; then
    # Get confirmation before installing
    prompt="Install CyberArk authzhelper on ${tgtName}?"
    read -p "${prompt} [y/n/a]" -n 1 -r
    echo ##Newline

    if [[ ! $REPLY =~ ^[YyAa]$ ]]; then
      break
    fi
    if [[ $REPLY =~ [Aa]$ ]]; then
      confirmAll=true
    fi
  fi
  
  echo -e "${BOLD} =================  Installing latest authzhelper on ${BLUE}${tgtName}${RESET}${BOLD} =================${RESET}"

  if ${sshCmd} -q [[ -f ${authZConfDir}/.authzid ]]; then
    echo -e "${YELLOW}\t...Already installed on ${tgtName}${RESET}\n" 
    continue
  fi

  echo #newline
  printf "%b${YELLOW}\tCopy ${authZName} to ${authZBin}${RESET}"
    ${scpCmd} ${authZSrc} ansible@localhost:${authZBin} > /dev/null 2>&1
  printf "%b${GREEN}...[SUCCESS]${RESET}\n"

  printf "%b${YELLOW}\tSet permissions to 0700 on ${authZBin}${RESET}"
    ${sshCmd} "chmod 0700 ${authZBin}" > /dev/null 2>&1
  printf "%b${GREEN}...[SUCCESS]${RESET}\n"

  printf "%b${YELLOW}\tCreating config directory ${authZConfDir}${RESET}"
    ${sshCmd} "mkdir -p ${authZConfDir}" > /dev/null 2>&1
  printf "%b${GREEN}...[SUCCESS]${RESET}\n"

  printf "%b${YELLOW}\tChanging owner to root:root on ${authZConfDir}${RESET}"
    ${sshCmd} "chown root:root ${authZConfDir}" > /dev/null 2>&1
  printf "%b${GREEN}...[SUCCESS]${RESET}\n"

  printf "%b${YELLOW}\tSetting permissions to 0700 on ${authZConfDir}${RESET}"
    ${sshCmd} "chmod 0700 ${authZConfDir}" > /dev/null 2>&1
  printf "%b${GREEN}...[SUCCESS]${RESET}\n"
  
  printf "%b${YELLOW}\tCreating config file ${authZConfDir}/config.yml${RESET}"
    ${scpCmd} ${authZConfigSrc} ansible@localhost:${authZConf} > /dev/null 2>&1
    ${sshCmd} "echo \"api-host: ${TPP_HOST}\" >> ${authZConf}" > /dev/null 2>&1
    ${sshCmd} "chmod 0600 ${authZConf}" > /dev/null 2>&1
    ${scpCmd} ${rootBundleSrc} ansible@localhost:${authZConfDir} > /dev/null 2>&1
  printf "%b${GREEN}...[SUCCESS]${RESET}\n"

  printf "%b${YELLOW}\tAuthorizing API grant for ${tgtName}${RESET}"
    ${sshCmd} "${authZBin} authenticate --user ${TPP_USER} --password ${TPP_PASS}" > /dev/null 2>&1
    # TODO: Check for errors?
  printf "%b${GREEN}...[SUCCESS]${RESET}\n"

  printf "%b${YELLOW}\tBacking up sshd_config${RESET}"
    ${sshCmd} "cp /etc/ssh/sshd_config ${authZConfDir}" > /dev/null 2>&1
  printf "%b${GREEN}...[SUCCESS]${RESET}\n"

  printf "%b${YELLOW}\tUpdating sshd_config${RESET}"
    ${scpCmd} ${sshdConf} ansible@localhost:/etc/ssh/sshd_config > /dev/null 2>&1
    ${sshCmd} "chmod 0600 /etc/ssh/sshd_config" > /dev/null 2>&1
  printf "%b${GREEN}...[SUCCESS]${RESET}\n"
  
  printf "%b${YELLOW}\tRestarting SSHD${RESET}"
    ${sshCmd} "/ussh-data/bin/startSSHD.sh" > /dev/null 2>&1
  printf "%b${GREEN}...[SUCCESS]${RESET}\n\n\n"


done


