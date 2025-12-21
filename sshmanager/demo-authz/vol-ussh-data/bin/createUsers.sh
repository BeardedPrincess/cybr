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

# Pick a random key type+params and generate it. Retries a few times in case
# the chosen type is disallowed by local policy (FIPS, min RSA size, etc).
gen_random_ssh_key() {
  local user="$1"
  local home="/home/${user}"
  local sshdir="${home}/.ssh"
  local authkeys="${sshdir}/authorized_keys"

  # Add/remove specs as you like. Keep weak RSA sizes only if you expect them to work.
  local -a specs=(
    "ed25519"
    "ed25519"
    "ed25519"
    "ecdsa:256"
    "ecdsa:256"
    "ecdsa:256"
    "ecdsa:256"
    "ecdsa:384"
    "ecdsa:384"
    "ecdsa:521"
    "rsa:2048"
    "rsa:2048"
    "rsa:2048"
    "rsa:2048"
    "rsa:2048"
    "rsa:2048"
    "rsa:2048"
    "rsa:2048"
    "rsa:3072"
    "rsa:3072"
    "rsa:4096"
    "rsa:4096"
    "rsa:4096"
    "rsa:1024"
    "rsa:1024"
    # "rsa:512"
  )

  local max_tries=6
  local try=1

  mkdir -p "$sshdir"
  touch "$authkeys"

  while (( try <= max_tries )); do
    local spec="${specs[RANDOM % ${#specs[@]}]}"
    local ktype="${spec%%:*}"
    local bits=""
    [[ "$spec" == *:* ]] && bits="${spec#*:}"

    local label="$ktype"
    [[ -n "$bits" ]] && label="${label}_${bits}"

    local keyfile="${sshdir}/id_${label}"

    # Build ssh-keygen args
    local -a args=(-q -N "" -C "${user}@unknown_host" -f "$keyfile" -t "$ktype")
    [[ -n "$bits" ]] && args+=(-b "$bits")

    # Try generate. If it fails (policy, etc), retry with a different spec.
    if ssh-keygen "${args[@]}" >/dev/null 2>&1; then
      # Keep your existing behavior
      chmod 644 "$authkeys"
      cat "$keyfile" > "${privKeys}/${user}"
      chmod 600 "${privKeys}/${user}"
      chown "$user:$user" "${sshdir}/id_${label}"*
      cat "${keyfile}.pub" >> "$authkeys"

      echo "Generated ${label} key for ${user}"
      return 0
    fi

    ((try++))
  done

  echo "ERROR: Failed to generate a key for ${user} after ${max_tries} attempts" >&2
  return 1
}

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

  declare -a key_types=("rsa" "ed25519" "ecdsa")

  # Usage inside your user-creation loop:
  gen_random_ssh_key "$user" || exit 1

  #ssh-keygen -t ecdsa -f /home/${user}/.ssh/id_ecdsa -N '' -C "${user}@unknown_host"
  #chmod 644 /home/${user}/.ssh/authorized_keys
  #cat /home/$user/.ssh/id_ecdsa > ${privKeys}/${user}
  #chmod 600 ${privKeys}/${user}
  #chown $user:$user /home/$user/.ssh/id_ecdsa*
  #cat /home/$user/.ssh/id_ecdsa.pub >> /home/$user/.ssh/authorized_keys
  
done

echo "User creation complete."
