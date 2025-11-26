#!/bin/bash
source /tmp/.env

SSH_PID_LOC=/var/run/sshd.pid

if [ ! -f ${SSH_PID_LOC} ]; then
  /usr/sbin/sshd -E ${logDir}/sshd.log
  sleep 1
  if [ -f ${SSH_PID_LOC} ]; then
    echo -e "${hn}\tSSHD started with PID $(cat ${SSH_PID_LOC})"
  else
    echo -e "${hn}\tSSHD failed to start"
  fi
else
  SSH_PID=$(cat ${SSH_PID_LOC})
  if [ -z "${SSH_PID}" ]; then
    echo -e "${hn}\tSSHD PID file is empty, restarting SSHD"
    /usr/sbin/sshd -E ${logDir}/sshd.log
    sleep 1
    if [ -f ${SSH_PID_LOC} ]; then
      echo -e "${hn}\tSSHD started with PID $(cat ${SSH_PID_LOC})"
    else
      echo -e "${hn}\tSSHD failed to start"
    fi
    exit 0
  fi

  if ! ps -p ${SSH_PID} > /dev/null 2>&1; then
    echo -e "${hn}\tSSHD process with PID ${SSH_PID} not found, restarting SSHD"
    /usr/sbin/sshd -E ${logDir}/sshd.log
    sleep 1
    if [ -f ${SSH_PID_LOC} ]; then
      echo -e "${hn}\tSSHD started with PID $(cat ${SSH_PID_LOC})"
    else
      echo -e "${hn}\tSSHD failed to start"
    fi
  else
    echo -e "${hn}\tRestarting SSHD w/PID ${SSH_PID}"
    kill ${SSH_PID}
    /usr/sbin/sshd -E ${logDir}/sshd.log
    echo -e "${hn}\tSSHD restarted. PID is now $(cat ${SSH_PID_LOC})"
  fi
fi