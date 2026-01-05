#!/bin/env bash

CONF_DIR="/etc/lego"
LEGO_BIN="/opt/lego/lego"
DOMAIN="$1"
CERT_PATH="${CONF_DIR}/certificates/${DOMAIN}.crt"

set -a
# Read configurations
test -f "${CONF_DIR}/config/env" && . "${CONF_DIR}/config/env"
test -f "${CONF_DIR}/config/${DOMAIN}" && . "${CONF_DIR}/config/${DOMAIN}"
set +a

set -e
if [ -f "${CERT_PATH}" ]; then
    echo "Renew ${DOMAIN} certificate if needed"
    "${LEGO_BIN}" --accept-tos --path "${CONF_DIR}" $ARGS $DOMAIN_ARGS renew --renew-hook "$HOOK"
else
    echo "Obtain ${DOMAIN} certificate"
    "${LEGO_BIN}" --accept-tos --path "${CONF_DIR}" $ARGS $DOMAIN_ARGS run --run-hook "$HOOK"
fi