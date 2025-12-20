#!/bin/bash
#
# c=$(ls /home | wc -l); if [ $c -gt 2 ]; then exit 0; fi;
#
umask 002
source /tmp/.env
privKeys=${myHostDir}/privateKeys
echo ${privKeys}

if [ -d ${privKeys} ]; then
  echo "Users already created, exiting without changes"
  exit 0
fi

mkdir -p ${privKeys}

# List of usernames to choose from
usernames=("svc_admin" "svc_dbbackup" "kjackson" "jwilson" "svc_filetransfer" "dbapp01" "u_brooks" "svc_networkmonitor" "svc_printer" "jbell" "svc_email" "u_taylor" "svc_devops" "svc_clouduser" "dgreen" "rjones" "u_williams" "svc_backup" "svc_infrastructure" "svc_appuser" "svc_docker" "dperez" "svc_monitoring" "u_lee" "svc_ciuser" "sreed" "svc_logs" "svc_auth" "svc_systems" "svc_devtools" "svc_storage" "u_bennett" "svc_vpn" "jmartinez" "svc_billing" "svc_inbox" "kbarrett" "jnewman" "svc_sharepoint" "svc_security" "svc_jira" "svc_projectx" "svc_backoffice" "svc_apiuser" "svc_deploy" "svc_gateway" "u_franklin" "svc_mailbox" "svc_smtp" "svc_proxy" "svc_appadmin" "svc_messaging" "svc_vault" "svc_datastore" "svc_cache" "svc_promotion" "svc_test" "svc_caching" "svc_webhook" "svc_gatewayadmin")

# Randomly select a number between 1 and 7
num_users=$((RANDOM % 7 + 1))

# Randomly select the usernames
selected_users=()
for i in $(seq 1 $num_users); do
  random_index=$((RANDOM % ${#usernames[@]}))
  selected_users+=("${usernames[$random_index]}")
done

# Create ansible user
# /usr/sbin/useradd -m -o -u 0 -s /bin/bash ansible 
# echo 'ansible:password99!' | /usr/sbin/chpasswd
# echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILYgHQvrZhyPx1lkVrSRM3fmWnuFhM3MeztbHUNcBf7W ansible@everywhere' > /home/ansible/.ssh/authorized_keys 
#echo "ansible:iaodsfjaoifjafj" | /usr/sbin/chpasswd

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
