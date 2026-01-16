# Demo SSH Manager Authorization (25.3)
This collection of scripts can be used to demonstrate the realtime observability of SSH key usage on many SSH hosts at once leveraging SSH Manager's `authzhelper` as an `AuthorizedKeysCommand` within `sshd_config` on the target hosts.

# Prerequisites
- Trust Protection Platform running 25.3 or later
- An account (TPP local, AD/LDAP) which has been given access to use the "CyberArk AuthZHelper" API Integration
- Stage the authzhelper installation bundle at: `C:\Program Files\Venafi\Web\ClientDistribution\sshmanager\authzhelper-linux-amd64-latest.tgz`
    > NOTE: The naming convention for the .tgz file differs from what ships in the installation!



# Requirements
- A host running a recent/supported version of Linux (testing was done using Ubuntu 22.04 and 24.04)
- Docker engine installed. <a href="https://docs.docker.com/engine/install/" target="_blank" rel="noopener noreferrer">Installation Guide ↗︎</a>
- A copy of CyberArk authzhelper binary compatible with your SSH Manager / Trust Protection Foundation version.

> These scripts assume you are required to use `sudo` for executing docker commands. You will need to ensure your user has the appropriate entries in `sudoers` or your privilege elevation management solution to allow this. (using NOPASSWD is the least annoying approach!)
> 
> **#TODO:** document required sudo commands for setup and demo run.


# Installation


## 1 - Clone this repo to your linux host

Clone this folder from the Github repo into a directory owned by your user account (by default current user's home folder).  The following snippet pulls just this subfolder.  

**Run these commands to clone this repo:**

```bash
BP_REPO_URL="${BP_REPO_URL:-https://github.com/BeardedPrincess/cybr.git}"
# BP_REPO_URL="${BP_REPO_URL:-ssh://git@github.com/BeardedPrincess/cybr.git}"
git clone --depth 1 "${BP_REPO_URL}" "${BP_GIT_DEST_FOLDER:-${HOME}/.demo-authz-git-src}" && \
ln -s "${BP_GIT_DEST_FOLDER:-${HOME}/.demo-authz-git-src}/sshmanager/demo-authz" \
  "${DEMO_ROOT:-${HOME}/demo-authz}"
```

After this is complete, you should have two folders in your home directory: `.demo-authz-git-src` and `demo-authz`. If you modified the destination folder, your folder name will be different.  The remainder of these instructions assume you used the default locations.  

## 2 - Configure your environment specific environment variables

- Copy `bin/.env-SAMPLE` to `bin/.env`

    **Run this command to create a starter `.env` file:**

    ```bash
    cp ${DEMO_ROOT:-${HOME}/demo-authz}/bin/.env-SAMPLE ${DEMO_ROOT:-${HOME}/demo-authz}/bin/.env
    ```

- Edit `/bin/.env` and set appropriate values for your environment

    **NOTE:** The variables `TPP_HOST`, `TPP_USER`, and `TPP_PASS` should be the only settings required for most installations.


## 3 - Run Update Script (to *initialize* your environment)

The setup.sh script is designed to validate system prerequisites, and to set default configuration options that the demo scripts will need going forward.

**Run these commands to execute the initial setup and prerequisites script:**

```bash
cd ~/demo-authz
/bin/bash -f bin/update-demo-authz.sh
```

