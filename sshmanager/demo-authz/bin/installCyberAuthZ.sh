#!/usr/bin/env bash
set -euo pipefail

SCRIPT_ROOT=${SCRIPT_ROOT:-$(dirname "$(realpath "${0}")")}

scriptRoot=$(dirname "$(realpath "${0}")")
source "$(dirname "$(realpath "${0}")")/lib/_lib.sh" 
common_init

# AuthZHelper Source
authZName='authzhelper'
authZSrc="${scriptRoot}/${authZName}"
authZConfigSrc="${scriptRoot}/authz_config"
sshdConf="${scriptRoot}/sshd_config"

# Destinations for authZHelper
authZBin="/usr/local/bin/${authZName}"
authZConfDir="/var/opt/cyberark/sshmanager"
authZConf="${authZConfDir}/config.yml"

tgtIDs=($(/usr/bin/docker container ls -q --filter ancestor=ussh))

if [ ${#tgtIDs[@]} -gt 0 ]; then
  echo "Installing on ${#tgtIDs[@]}"
else
  echo "No targets running.. done"
  exit 0
fi

confirmAll=false

for i in ${!tgtIDs[@]}; do
  tgtId=${tgtIDs[${i}]}
  tgtName=$(docker inspect --format '{{ .Name }}' ${tgtId})
  tgtPort=$(docker inspect --format '{{ (index (index .NetworkSettings.Ports "22/tcp") 0).HostPort }}' ${tgtId})
  sshCmd="ssh -i ${scriptRoot}/ansible.key -p ${tgtPort} ansible@localhost"
  scpCmd="scp -i ${scriptRoot}/ansible.key -P ${tgtPort}" 

  if [ "${confirmAll}" = false ]; then
    # Get confirmation before installing
    prompt="Install 'authZHelper' on ${tgtName}?"
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

  if ${sshCmd} -q [[ -f ${authZConf} ]]; then
    echo -e "${YELLOW}\t...Already installed on ${tgtName}${RESET}\n" 
    continue
  fi

  echo #newline
  printf "%b${YELLOW}\tCopy ${authZName} to ${authZBin}${RESET}"
  ${scpCmd} ${authZSrc} ansible@localhost:${authZBin} > /dev/null 2>&1
  printf "%b${GREEN}...[SUCCESS]${RESET}\n"

  printf "%b${YELLOW}\tSet permissions to 0700 on ${authZBin}${RESET}"
  ${sshCmd} "chmod 0700 ${authZBin}"
  printf "%b${GREEN}...[SUCCESS]${RESET}\n"

  printf "%b${YELLOW}\tCreating config directory ${authZConfDir}${RESET}"
  # echo "${sshCmd} 'mkdir -p ${authZConfDir}'"
  ${sshCmd} "mkdir -p ${authZConfDir}"
  printf "%b${GREEN}...[SUCCESS]${RESET}\n"

  printf "%b${YELLOW}\tChanging owner to root:root on ${authZConfDir}${RESET}"
  ${sshCmd} "chown root:root ${authZConfDir}"
  printf "%b${GREEN}...[SUCCESS]${RESET}\n"

  printf "%b${YELLOW}\tSetting permissions to 0700 on ${authZConfDir}${RESET}"
  ${sshCmd} "chmod 777 ${authZConfDir}"
  printf "%b${GREEN}...[SUCCESS]${RESET}\n"
  
  printf "%b${YELLOW}\tCreating config file ${authZConfDir}/config.yml${RESET}"
  #${sshCmd} "echo 'api-host: jh-ssh-poc-tpp.lab.securafi.net' > ${authZConf}"
  #${sshCmd} "echo 'api-host: jh-ssh-poc-tpp.lab.securafi.net' > ${authZConf}"
  # echo "Running: ${scpCmd} ${authZConfigSrc}/config.yml ansbile@localhost:${authZConfDir}"
  ${scpCmd} ${authZConfigSrc}/config.yml ansible@localhost:${authZConfDir} > /dev/null 2>&1
  # ${scpCmd} ${authZConfigSrc}/.authzhelper_secret ansible@localhost:${authZConfDir}
  ${scpCmd} ${authZConfigSrc}/securafiroot.pem ansible@localhost:${authZConfDir} > /dev/null 2>&1
  # ${sshCmd} "cat /proc/sys/kernel/random/uuid > ${authZConfDir}/.authzid"
  #${sshCmd} "chmod 0600 ${authZConf}"
  #${sshCmd} "chmod -R 0600 ${authZConfDir}"

  ${sshCmd} "${authZBin} authenticate --user svc_authz --password password99! > /dev/null 2>&1"
  # TODO: If failed, don't continue
  printf "%b${GREEN}...[SUCCESS]${RESET}\n"

  printf "%b${YELLOW}\tBacking up sshd_config${RESET}"
  ${sshCmd} "cp /etc/ssh/sshd_config ${authZConfDir}"
  printf "%b${GREEN}...[SUCCESS]${RESET}\n"

  printf "%b${YELLOW}\tUpdating sshd_config${RESET}"
  ${scpCmd} ${sshdConf} ansible@localhost:/etc/ssh/sshd_config > /dev/null 2>&1
  ${sshCmd} "chmod 0600 /etc/ssh/sshd_config"
  printf "%b${GREEN}...[SUCCESS]${RESET}\n"
  
  printf "%b${YELLOW}\tRestarting SSHD${RESET}"
  ${sshCmd} "/ussh-data/startSSHD.sh > /dev/null 2>&1"
  printf "%b${GREEN}...[SUCCESS]${RESET}\n\n\n"
  
  
  #targetPorts=($(docker inspect --format '{{ (index (index .NetworkSettings.Ports "22/tcp") 0).HostPort }}'
done


