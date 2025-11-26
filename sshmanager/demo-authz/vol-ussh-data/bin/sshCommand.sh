#!/bin/bash
# This is the script that is run when one of the remote connections are made.

source /tmp/.env
echo -e "$(date --rfc-3339=seconds)\t[${hn}]\tuser $(whoami) logged on from ${1}" >> ${logDir}/connections.log

