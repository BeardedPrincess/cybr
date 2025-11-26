#!/bin/bash
set -euo pipefail

###################################################################
# Library of common functions, used by multiple demo_admin scripts
# Author: Justin Hansen (justin.hansen@cyberark.com)
# Date: 20 November 2025
#
# Updates:
# 20 November 2025 - Initial creation, tested with TPP 25.3.0
###################################################################

### Colors (for console only)
if [[ -t 1 ]]; then
    RED="\033[31m";    GREEN="\033[32m";   YELLOW="\033[33m"; BLUE="\033[34m"
    MAGENTA="\033[35m"; CYAN="\033[36m";   WHITE="\033[37m"
    BOLD="\033[1m";    UNDERLINE="\033[4m"; DIM="\033[2m"
    RESET="\033[0m"
else
    RED=""; GREEN=""; YELLOW=""; BLUE=""; MAGENTA=""; CYAN=""; WHITE=""
    BOLD=""; UNDERLINE=""; DIM=""; RESET=""
fi
export RED GREEN YELLOW BLUE MAGENTA CYAN WHITE BOLD UNDERLINE DIM RESET

debug () {
  if [[ -n "${SHOW_DEBUG:-}" ]]; then
    echo -e "${DIM}${BLUE}[DEBUG]${RESET}${DIM} $*${RESET}" >&2
  fi
}

info () {
  echo -e "${WHITE}[INFO]${RESET} $*" >&2
}

warn () {
  echo -e "${YELLOW}[WARN]${RESET} $*" >&2
  if [[ -z "${FORCE_CONTINUE:-}" ]]; then
    printf "\n${YELLOW}Continue anyway?${RESET} [y/N]: " >&2 
    read -r -n 1
    echo ## Newline
    if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
        die "Aborted by user."
    fi
  fi
}

error () {
  echo -e "${RED}[ERROR]${RESET} $*" >&2
}

die () {
  echo -e "${RED}${BOLD}[FATAL]${RESET} $*" >&2
  exit 1
}

common_init () {


  debug "Running common_init from bin/_lib.sh"
  # Set script root
  scriptRoot=$(dirname "$(realpath "${0}")")
  if [ "${PWD}" == "${scriptRoot}" ]; then    
    scriptRoot='.'
  fi
  # Load environment variables
  if [ -f ${scriptRoot}/.env ]; then
    debug "Sourcing environment from ${scriptRoot}/.env"
    source ${scriptRoot}/.env
  else
    die "${scriptRoot}/.env not found, cannot continue"
  fi

  # Ensure required variables have been set
  requiredVars=(TPP_HOST TPP_USER TPP_PASS VOL_DIR DOCKER_BIN DOCKER_CMD DOCKER_IMAGE_NAME)
  missingVars=""
  for var in "${requiredVars[@]}"; do
    if [ -z "${!var:-}" ]; then
      missingVars="${missingVars}\n\tMissing required variable: '${var}'"
    fi
  done
  if [ -n "${missingVars}" ]; then
    echo -e "${missingVars}"
    exit 1
  fi

  # Set script root
  scriptRoot=${SCRIPT_DIR:-$(dirname "$(realpath "${0}")")}
  if [ "${PWD}" == "${scriptRoot}" ]; then    
    scriptRoot='.'
  fi
  # Load environment variables
  if [ -f ${scriptRoot}/.env ]; then
    debug "Sourcing environment from ${scriptRoot}/.env"
    source ${scriptRoot}/.env
  else
  echo -e "${RED}[ERROR] ${scriptRoot}/.env not found, cannot continue${RESET}"
  exit 1
  fi

  # Ensure required variables have been set
  requiredVars=(VOL_DIR TPP_HOST TPP_USER TPP_PASS)
  missingVars=""
  for var in "${requiredVars[@]}"; do
  if [ -z "${!var:-}" ]; then
      set missingVars = "${missingVars}\nERROR: Required variable '${var}' is not set, cannot continue"
  fi
  done
  if [ -n "${missingVars}" ]; then
  echo -e "${missingVars}"
  exit 1
  fi



  debug "Loaded demo_admin/_lib.sh successfully"
  debug "  VOL_DIR='${VOL_DIR}'"
  debug "  TPP_HOST='${TPP_HOST}'"
  debug "  TPP_USER='${TPP_USER}'"
  debug "  TPP_PASS='******************'"  # Don't print passwords

}

get_root_cert_from() {
  url="$1"
  debug "get_root_cert_from(): called with URL '${url}' and output file '$2'"
  [ -z "$url" ] && die "get_root_cert_from(): missing URL/host parameter"

  output_file="$2"
  [ -z "$output_file" ] && die "get_root_cert_from(): missing output file parameter"
  [ -f "$output_file" ] && warn "get_root_cert_from(): output file '${output_file}' already exists. It will be overwritten."

  debug "get_root_cert_from(): resolving endpoint from '${url}'"

  # Strip scheme and path; default to port 443 if none specified
  hostport=$(printf '%s\n' "$url" \
    | sed -E 's~^https?://~~; s~/.*~~')
  case "$hostport" in
    *:*) : ;;  # already has port
    *)   hostport="${hostport}:443" ;;
  esac

  host="${hostport%%:*}"
  debug "Connecting to ${hostport} (SNI: ${host})"

  tmpdir=$(mktemp -d 2>/dev/null) || die "Failed to create temp dir"
  chain_prefix="${tmpdir}/cert"

  # Helper to ensure cleanup on error
  _cleanup_and_die() {
    msg="$1"
    rm -rf "${tmpdir}"
    die "${msg}"
  }

  # Helper to format cert metadata into one line
  _cert_summary() {
    cert_file="$1"
    [ -f "${cert_file}" ] || return 1

    subj=$(openssl x509 -in "${cert_file}" -noout -subject 2>/dev/null | sed 's/^subject= *//')
    issuer=$(openssl x509 -in "${cert_file}" -noout -issuer 2>/dev/null | sed 's/^issuer= *//')
    serial=$(openssl x509 -in "${cert_file}" -noout -serial 2>/dev/null | sed 's/^serial= *//')
    fp=$(openssl x509 -in "${cert_file}" -noout -fingerprint -sha1 2>/dev/null \
         | sed 's/^.*Fingerprint=//; s/^SHA1 Fingerprint=//')
    start=$(openssl x509 -in "${cert_file}" -noout -startdate 2>/dev/null | sed 's/^notBefore=//')
    end=$(openssl x509 -in "${cert_file}" -noout -enddate 2>/dev/null | sed 's/^notAfter=//')

    printf '\n\tSubject="%s"\n\tIssuer="%s"\n\tSerial="%s"\n\tThumbprint(SHA1)="%s"\n\tValidFrom="%s"\n\tValidTo="%s"' \
      "${subj}" "${issuer}" "${serial}" "${fp}" "${start}" "${end}"
  }

  # Get leaf certificate
  if ! echo | openssl s_client -showcerts -servername "${host}" -connect "${hostport}" 2>/dev/null \
      | awk '/BEGIN CERTIFICATE/{flag=1} flag{print} /END CERTIFICATE/{exit}' \
      > "${chain_prefix}-00.pem"
  then
    rm -rf "${tmpdir}"
    die "Failed to retrieve leaf certificate from ${hostport}"
  fi

  debug "Leaf certificate saved to ${chain_prefix}-00.pem"

  # Track all cert paths in the chain (leaf → root)
  cert_paths=()
  cert_paths+=("${chain_prefix}-00.pem")

  i=0
  root_cert=""

  # Walk AIA chain up to root
  while :; do
    cur="${cert_paths[$i]}"

    [ -f "${cur}" ] || _cleanup_and_die "Expected certificate not found at ${cur}"

    subject=$(openssl x509 -in "${cur}" -noout -subject 2>/dev/null | sed 's/^subject= *//')
    issuer=$(openssl x509 -in "${cur}" -noout -issuer 2>/dev/null | sed 's/^issuer= *//')
    

    # Self-signed? (subject == issuer)
    if [ -n "${subject}" ] && [ "${subject}" = "${issuer}" ]; then
      debug "Reached self-signed certificate at ${cur}; assuming root"
      root_cert="${cur}"
      break
    fi

    # Try to get AIA CA Issuers URL
    aia_url=$(
      openssl x509 -in "${cur}" -noout -text 2>/dev/null \
        | awk '/CA Issuers - URI:/{print $NF; exit}' \
        | sed 's/URI://'
    )

    if [ -z "${aia_url}" ]; then
      warn "No CA Issuers AIA found for ${cur}; treating as root"
      root_cert="${cur}"
      break
    fi

    debug "AIA CA Issuers URL: ${aia_url}"

    next="$(printf '%s-%02d.pem' "${chain_prefix}" "$((i+1))")"
    tmp_raw="${tmpdir}/issuer.tmp"

    # Fetch issuer certificate (often DER)
    if ! curl -fsSL "${aia_url}" -o "${tmp_raw}"; then
      _cleanup_and_die "Failed to fetch issuer certificate from ${aia_url}"
    fi

    # Try DER → PEM; if that fails, assume PEM input
    if ! openssl x509 -inform der -in "${tmp_raw}" -out "${next}" 2>/dev/null; then
      if ! openssl x509 -in "${tmp_raw}" -out "${next}" 2>/dev/null; then
        rm -f "${tmp_raw}"
        _cleanup_and_die "Failed to parse issuer certificate from ${aia_url}"
      fi
    fi
    rm -f "${tmp_raw}"

    cert_paths+=("${next}")
    debug "Issuer certificate saved to ${next}"

    i=$((i+1))

    # Simple safety cap to avoid infinite loops
    if [ "${i}" -gt 10 ]; then
      _cleanup_and_die "AIA chain appears too long; aborting"
    fi
  done

  if [ -z "${root_cert}" ] || [ ! -f "${root_cert}" ]; then
    rm -rf "${tmpdir}"
    die "Could not determine root certificate"
  fi

  # Emit metadata for the chain:
  # - debug() for intermediates
  # - info() for the root
  count=${#cert_paths[@]}
  idx=0
  while [ "${idx}" -lt "${count}" ]; do
    cert_file="${cert_paths[$idx]}"
    summary="$(_cert_summary "${cert_file}")" || summary="(unable to parse cert ${cert_file})"

    if [ "${idx}" -eq $((count - 1)) ]; then
      info "Found root certificate: ${summary}"
    else
      debug "Chain certificate [${idx}]: ${summary}"
    fi

    idx=$((idx+1))
  done

  # Output the root PEM only (no extra text)
  cat "${root_cert}" > "${output_file}"

  rm -rf "${tmpdir}"
}