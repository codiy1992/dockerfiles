#!/usr/bin/env sh

ACME_DIR=${ACME_DIR:-'acme-v02.api.letsencrypt.org-directory'}
ACME_CERT_FILE=/data/caddy/certificates/${ACME_DIR}/${DOMAIN_V2RAY}/${DOMAIN_V2RAY}.crt

if [[ "${DOMAIN_V2RAY}" != "" && -f /etc/cray/v2ray.json && -f ${ACME_CERT_FILE} ]]; then
    cp /etc/cray/v2ray.json /etc/v2ray/config.json
    sed -i "s/ACME_DIR/${ACME_DIR}/g" /etc/v2ray/config.json
    sed -i "s/DOMAIN/${DOMAIN_V2RAY}/g" /etc/v2ray/config.json
fi

/usr/bin/v2ray run -c /etc/v2ray/config.json
