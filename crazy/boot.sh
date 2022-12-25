#!/usr/bin/env sh

if [[ -f /etc/crazy/hooks/before_booting.sh ]]; then
    /bin/sh /etc/crazy/hooks/before_booting.sh
fi

/usr/bin/supervisorctl start caddy > /dev/null

ACME_WATING_SECONDS=${ACME_WATING_SECONDS:-180}
ACME_DIR=${ACME_DIR:-'acme-v02.api.letsencrypt.org-directory'}

if [[ "${DOMAIN}" != "" ]]; then
    ACME_CERT_FILE=/data/caddy/certificates/${ACME_DIR}/${DOMAIN}/${DOMAIN}.crt
    WAITING=0
    while [[ ! -f ${ACME_CERT_FILE}  && $WAITING -lt $ACME_WATING_SECONDS ]]; do
        echo "[crazy] Wating Acme Certificate (${WAITING}): ${DOMAIN}"; sleep 5;
        WAITING=$((WAITING+5))
    done
fi

if [[ "${DOMAIN_CDN}" != "" ]]; then
    ACME_CERT_FILE=/data/caddy/certificates/${ACME_DIR}/${DOMAIN_CDN}/${DOMAIN_CDN}.crt
    WAITING=0
    while [[ ! -f ${ACME_CERT_FILE}  && $WAITING -lt $ACME_WATING_SECONDS ]]; do
        echo "[crazy] Wating Acme Certificate (${WAITING}): ${DOMAIN_CDN}"; sleep 5;
        WAITING=$((WAITING+5))
    done
fi

if [[ ! ${WITHOUT_V2RAY} ]]; then
    /usr/bin/supervisorctl start v2ray > /dev/null
fi

if [[ ! ${WITHOUT_XRAY} ]]; then
    /usr/bin/supervisorctl start xray > /dev/null
fi

if [[ ! ${WITHOUT_SHADOWSOCKS} ]]; then
    /usr/bin/supervisorctl start ssserver > /dev/null
fi

/bin/sh ./scripts/cloudflare.sh

if [[ "${AWS_ACCESS_KEY_ID}" != "" && "${AWS_SECRET_ACCESS_KEY}" != "" ]]; then
    /bin/sh ./scripts/cloudfront.sh
fi

if [[ -f /etc/crazy/hooks/after_booted.sh ]]; then
    /bin/sh /etc/crazy/hooks/after_booted.sh
fi
