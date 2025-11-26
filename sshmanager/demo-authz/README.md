# Demo SSH Manager Authorization (25.3)
This collection of scripts can be used to demonstrate the realtime observability of SSH key usage on many SSH hosts at once leveraging SSH Manager's `authzhelper` as an `AuthorizedKeysCommand` within `sshd_config` on the target hosts.

# Requirements
- A host running a recent/supported version of Linux (testing was done using Ubuntu 22.04 and 24.04)
- Docker engine installed. <a href="https://docs.docker.com/engine/install/" target="_blank" rel="noopener noreferrer">Installation Guide ↗︎</a>
- A copy of CyberArk authzhelper binary compatible with your SSH Manager / Trust Protection Foundation version.

> These scripts assume you are required to use `sudo` for executing docker commands. You will need to ensure your user has the appropriate entries in `sudoers` or your privilege elevation management solution to allow this. (using NOPASSWD is the least annoying approach!)
> 
> **#TODO:** document required sudo commands for setup and demo run.


# Installation
You may override some of the installation details by setting any of the following environment variables: 

| Variable               | Default Value                                 |
|------------------------|-----------------------------------------------|
| **DEMO_ROOT**     | `${HOME}/demo-authz`                          |
| **BP_GIT_DEST_FOLDER** | `${HOME}/.demo-authz-git-src`                 |
| **BP_REPO_URL**        | `https://github.com/BeardedPrincess/cybr.git` |
| **BP_REPO_BRANCH**     | `main`                                        |

The purpose of each variable is outlined below:

- **DEMO_ROOT** :
    > Which folder to place the main scripts used to control the authz demo. This is probably the one setting you may most likely want to customize. This will end up being a symbolic link to the sshmanager/demo-authz folder within the git source tree.
- **BP_REPO_URL**        :
    > Which repo to clone. Change this to target a different git repo (possibly your own fork)
- **BP_REPO_BRANCH**     :
    > Change this to control which branch to clone from git
- **BP_GIT_DEST_FOLDER**     :
    > This is the folder where this repo will be cloned into.  This will be separate from the BP_DEST_FOLDER to keep the path length shorter and easier to use.

## 1 - Clone this repo to your linux host

Clone this folder from the Github repo into a directory owned by your user account (by default current user's home folder).  The following snippet pulls just this subfolder.  

**Run these commands to clone this repo:**

```bash
git clone --depth 1 \
  "${BP_REPO_URL:-https://github.com/BeardedPrincess/cybr.git}" \
  "${BP_GIT_DEST_FOLDER:-${HOME}/.demo-authz-git-src}" && \
ln -s "${BP_GIT_DEST_FOLDER:-${HOME}/.demo-authz-git-src}/sshmanager/demo-authz" \
  "${DEMO_ROOT:-${HOME}/demo-authz}"
```

After this is complete, you should have two folders in your home directory: `.demo-authz-git-src` and `demo-authz`. If you modified the destination folder, your folder name will be different.  The remainder of these instructions assume you used the default locations.  

## 3 - Configure your environment specific environment variables

1. Copy `.env-SAMPLE` to `.env`

    **Run this command to create a starter `.env` file:**

    ```bash
    cp ${DEMO_ROOT:-${HOME}/demo-authz}/.env-SAMPLE ${DEMO_ROOT:-${HOME}/demo-authz}/.env
    ```

2. Edit `.env` and set appropriate values for your environment
 

The setup.sh script is designed to validate system prerequisites, and to set default configuration options that the demo scripts will need going forward.

**Run these commands to execute the initial setup and prerequisites script:**

```bash
cd ~/demo-authz
/bin/bash -f ./_initialSetup.sh
```

## 2 - Run Initial Setup Script

The setup.sh script is designed to validate system prerequisites, and to set default configuration options that the demo scripts will need going forward.

**Run these commands to execute the initial setup and prerequisites script:**

```bash
cd ~/demo-authz
/bin/bash -f ./_initialSetup.sh
```
