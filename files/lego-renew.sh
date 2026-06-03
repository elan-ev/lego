#!/bin/env bash

CONF_DIR="/etc/lego"
LEGO_BIN="/opt/lego/lego"
HOOK_SCRIPT="/opt/lego/hook.sh"
DOMAIN="$1"
CERT_PATH="${CONF_DIR}/certificates/${DOMAIN}.crt"

set -a
# Read configurations
test -f "${CONF_DIR}/config/env" && . "${CONF_DIR}/config/env"
test -f "${CONF_DIR}/config/${DOMAIN}" && . "${CONF_DIR}/config/${DOMAIN}"
set +a

set -e
echo "Obtaining/renewing ${DOMAIN} certificate"
"${LEGO_BIN}" run --accept-tos --path "${CONF_DIR}" $ARGS $DOMAIN_ARGS --deploy-hook "$HOOK_SCRIPT"
