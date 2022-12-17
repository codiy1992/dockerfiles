#!/usr/bin/env sh

/usr/bin/supervisorctl start caddy > /dev/null

ACME_WATING_SECONDS=${ACME_WATING_SECONDS:-180}
ACME_DIR=${ACME_DIR:-'acme-v02.api.letsencrypt.org-directory'}

if [[ "${DOMAIN_V2RAY}" != "" ]]; then
    V2RAY_ACME_CERT_FILE=/data/caddy/certificates/${ACME_DIR}/${DOMAIN_V2RAY}/${DOMAIN_V2RAY}.crt
    WAITING=0
    while [[ ! -f ${V2RAY_ACME_CERT_FILE}  && $WAITING -lt $ACME_WATING_SECONDS ]]; do
        echo "[v2ray] Wating Acme Certificate (${WAITING})"; sleep 5;
        WAITING=$((WAITING+5))
    done
fi

/usr/bin/supervisorctl start v2ray > /dev/null

if [[ "${DOMAIN_XRAY}" != "" ]]; then
    XRAY_ACME_CERT_FILE=/data/caddy/certificates/${ACME_DIR}/${DOMAIN_XRAY}/${DOMAIN_XRAY}.crt
    WAITING=0
    while [[ ! -f ${XRAY_ACME_CERT_FILE}  && $WAITING -lt $ACME_WATING_SECONDS ]]; do
        echo "[xray] Wating Acme Certificate (${WAITING})"; sleep 5;
        WAITING=$((WAITING+5))
    done
fi

/usr/bin/supervisorctl start xray > /dev/null
