#!/bin/bash
umask 002
source /tmp/.env

echo -e "${hn}\t Checking ${hostsDir} for other hosts"

newtargets=($(ls -d ${hostsDir}/* | grep -v "${hn}"))
numHosts=${#newtargets[@]}
echo -e "${hn}\t Found ${numHosts} other hosts"

if [ ${numHosts} -gt 0 ]; then
  for i in "${!newtargets[@]}"; do
    tgthost=$(basename "${newtargets[$i]}")
    echo -e "${hn}\t Check target host '${tgthost}'"

    # Make sure we have a host entry in /etc/hosts for this target
    if [ "$(grep ${tgthost} /etc/hosts | wc -l)" -lt 1 ]; then
      echo -e "${hn}\t ${tgthost} does not exist in /etc/hosts, adding it now"
      cat ${newtargets[$i]}/host >> /etc/hosts 
    fi

    tgtUsers=($(ls ${newtargets[$i]}/privateKeys/))
    numTgtUsers=${#tgtUsers[@]}
    echo -e "${hn}\t Found ${numTgtUsers} users on new target host ${tgthost}"



    if [ ${numTgtUsers} -gt 0 ]; then
      # Copy the first target user's private key into our target hosts directory
      tgtuser=${tgtUsers[0]}
      echo -e "${hn}\t Target user: ${tgtuser}"
      
      # Create a targets directory for this host
      if [ ! -d ${myHostDir}/targets/${tgthost} ]; then
        mkdir -p ${myHostDir}/targets/${tgthost}
      fi

      mv ${newtargets[$i]}/privateKeys/${tgtuser} ${myHostDir}/targets/${tgthost}/${tgtuser}

      
    fi
  done
fi

targets=($(ls -d ${myHostDir}/targets/*/*))
numtargets=${#targets[@]}
echo -e "${hn}\t Found ${numtargets} targets"

for i in "${!targets[@]}"; do
  tgtuser=$(basename "${targets[$i]}")
  tgthost=$(basename "$(dirname "${targets[$i]}")")
  echo -e "${hn}\t Targeting user '${tgtuser}' on host '${tgthost}'"

  ssh -i ${targets[$i]} ${tgtuser}@${tgthost} /ussh-data/bin/sshCommand.sh ${hn}

done