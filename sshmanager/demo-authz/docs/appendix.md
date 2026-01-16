# Appendix

## Environment variables
You may override some of the installation details by setting any of the following environment variables: 

| Variable               | Default Value                                 |
|------------------------|-----------------------------------------------|
| **DEMO_ROOT**          | `${HOME}/demo-authz`                          |
| **BP_GIT_DEST_FOLDER** | `${HOME}/.demo-authz-git-src`                 |
| **BP_REPO_URL**        | `https://github.com/BeardedPrincess/cybr.git` |
| **BP_REPO_BRANCH**     | `main`                                        |

The purpose of each variable is outlined below:

- **DEMO_ROOT** :
    > Which folder to place the main scripts used to control the authz demo. This is probably the one setting you likely want to customize. This will end up being a symbolic link to the sshmanager/demo-authz folder within the git source tree.
- **BP_REPO_URL**        :
    > Which repo to clone. Change this to target a different git repo (possibly your own fork)
- **BP_REPO_BRANCH**     :
    > Change this to control which branch to clone from git
- **BP_GIT_DEST_FOLDER**     :
    > This is the folder where this repo will be cloned into.  This will be separate from the BP_DEST_FOLDER to keep the path length shorter and easier to use.