#!/bin/bash
#
umask 002

if [ -f /tmp/.env ]; then
  exit 0
fi

touch /tmp/.env

hn=$(hostname)
echo "hn=${hn}" >> /tmp/.env
echo ${hn} > /tmp/HOSTNAME

ip=$(hostname -I)
echo "ip=${ip}" >> /tmp/.env
echo ${ip} > /tmp/IP

rootDir="/ussh-data"
echo "rootDir=${rootDir}" >> /tmp/.env

logDir="${rootDir}/logs/${hn}"
echo "logDir=${logDir}" >> /tmp/.env
echo ${logDir} > /tmp/LOG

hostsDir="${rootDir}/servers"
echo "hostsDir=${hostsDir}" >> /tmp/.env

myHostDir="${hostsDir}/${hn}"
echo "myHostDir=${myHostDir}" >> /tmp/.env

if [ ! -d ${logDir} ]; then
  mkdir -p ${logDir} 
  touch ${logDir}/connections.log
  chmod 666 ${logDir}/connections.log
fi

if [ ! -d ${myHostDir} ]; then
  mkdir -p ${myHostDir}
fi

if [ ! -f ${myHostDir}/host ]; then
  echo -e "${ip}\t${hn}" > ${myHostDir}/host
fi


