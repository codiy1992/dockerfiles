#!/usr/bin/env sh

ACME_DIR=${ACME_DIR:-'acme-v02.api.letsencrypt.org-directory'}
ACME_CERT_FILE=/data/caddy/certificates/${ACME_DIR}/${DOMAIN_XRAY}/${DOMAIN_XRAY}.crt

if [[ "${DOMAIN_XRAY}" != "" && -f /etc/cray/xray.json && -f ${ACME_CERT_FILE} ]]; then
    cp /etc/cray/xray.json /etc/xray/config.json
    sed -i "s/ACME_DIR/${ACME_DIR}/g" /etc/xray/config.json
    sed -i "s/DOMAIN/${DOMAIN_XRAY}/g" /etc/xray/config.json
fi

/usr/bin/xray run -c /etc/xray/config.json
