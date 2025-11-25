#!/bin/bash
############################################################################
# Initial setup script for demo-authz
# This script sets up the necessary environment for the authzhelper demo
# and validates prerequisites.
#
# Usage: /bin/sh _initialSetup.sh
set -euo pipefail

source bin/_lib.sh 
common_init

get_root_cert_from "https://jhtpp253.lab.securafi.net" "root_cert.pem"