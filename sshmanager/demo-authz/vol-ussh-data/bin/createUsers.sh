#!/bin/bash
#
# c=$(ls /home | wc -l); if [ $c -gt 2 ]; then exit 0; fi;
#
umask 002
source /tmp/.env
privKeys=${myHostDir}/privateKeys

if [ -d ${privKeys} ]; then
  echo "Users already created, exiting without changes"
  exit 0
fi

mkdir -p ${privKeys}


# List of usernames to choose from
declare -a usernames
while read -r first _; do
  # Skip empty lines and lines whose first non-whitespace char is '#'
  [[ -z "${first}" || "${first}" == \#* ]] && continue

  # Take only the first word on the line
  usernames+=("${first}")
done < /ussh-data/usernames.txt

# We want somewhere between 4 and 10 users
num_users=$((RANDOM % 7 + 4))

# Randomly select the usernames
selected_users=()
already_used_indices=()
for i in $(seq 1 $num_users); do
  random_index=$((RANDOM % ${#usernames[@]}))
  # Ensure we don't select the same user twice
  while [[ " ${already_used_indices[@]} " =~ " ${random_index} " ]]; do
    random_index=$((RANDOM % ${#usernames[@]}))
  done
  already_used_indices+=("${random_index}")
  selected_users+=("${usernames[$random_index]}")
done

# Create the selected users
for user in "${selected_users[@]}"; do
  echo "Creating user ${user}"
  if [ -f "${privKeys}/${user}" ]; then
    echo "...already existed, removing previous ${privKeys}/${user}"
    rm -rf "${privKeys}/${user}"
  fi

  if [ -d /home/${user} ]; then 
    echo "...removing keys from /home/${user}/.ssh/id_*"
    rm -f /home/${user}/.ssh/id_*
  else
    echo "Creating user: $user"
    /usr/sbin/useradd -m -d /home/$user $user
    echo ${user}:nopasswdforrealls | /usr/sbin/chpasswd
  fi

  if [ ! -d /home/${user} ]; then
    echo "[ERR] Failed to create user ${user}"
    exit -1
  fi

  ssh-keygen -t ecdsa -f /home/${user}/.ssh/id_ecdsa -N '' -C "${user}@unknown_host"
  chmod 644 /home/${user}/.ssh/authorized_keys
  cat /home/$user/.ssh/id_ecdsa > ${privKeys}/${user}
  chmod 600 ${privKeys}/${user}
  chown $user:$user /home/$user/.ssh/id_ecdsa*
  cat /home/$user/.ssh/id_ecdsa.pub >> /home/$user/.ssh/authorized_keys
  
done

echo "User creation complete."
