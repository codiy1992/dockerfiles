#!/usr/bin/env sh

ACME_DIR=${ACME_DIR:-'acme-v02.api.letsencrypt.org-directory'}

ACME_CERT_FILE=/data/caddy/certificates/${ACME_DIR}/${DOMAIN}/${DOMAIN}.crt
ACME_CERT_FILE_CDN=/data/caddy/certificates/${ACME_DIR}/${DOMAIN_CDN}/${DOMAIN_CDN}.crt

if [[ -f /etc/cray/shadowsocks.json ]] && [[ -f ${ACME_CERT_FILE} || -f ${ACME_CERT_FILE_CDN} ]]; then
    sed '/^[[:blank:]]*\/\//d;s/\/\/.*//' /etc/cray/shadowsocks.json > /etc/shadowsocks-rust/config.json
    sed -i "s/ACME_DIR/${ACME_DIR}/g" /etc/shadowsocks-rust/config.json
fi

if [[ -f ${ACME_CERT_FILE_CDN} ]]; then
    sed -i "s/DOMAIN_CDN/${DOMAIN_CDN}/g" /etc/shadowsocks-rust/config.json
fi

if [[ -f ${ACME_CERT_FILE} ]]; then
    sed -i "s/DOMAIN/${DOMAIN}/g" /etc/shadowsocks-rust/config.json
fi

/usr/bin/ssserver -c /etc/shadowsocks-rust/config.json
