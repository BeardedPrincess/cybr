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

## Option 1: Clone this folder (or everything) from this repo
Clone this folder from the Github repo into a directory owned by your user account (home folder works).  The following snippet pulls just this subfolder.  This option is preferred if you want to be able to retrieve updates from this repo in the future.

### Run these commands to clone just this folder:
```bash
REPO_URL=https://github.com/BeardedPrincess/cybr.git
REPO_BRANCH=main
DEST_FOLDER=${HOME}/cybr-tools  ## Change this path if you want a different folder
git clone --depth 1 --no-checkout ${REPO_URL} ${DEST_FOLDER}
pushd ${DEST_FOLDER}
git sparse-checkout init --cone
git sparse-checkout set sshmanager/demo-authz
git checkout ${REPO_BRANCH}
popd
```

### Clone the whole repo
It's also fine to clone the whole repo, but only if you want ALL the other stuff too. May add extra stuff you don't want or need (now, or in the future)

```bash
REPO_URL=https://github.com/BeardedPrincess/cybr.git
REPO_BRANCH=main
DEST_FOLDER=${HOME}/cybr-tools  ## Change this path if you want a different folder
git clone --depth 1 --branch ${REPO_BRANCH} ${REPO_URL} ${DEST_FOLDER}
```


