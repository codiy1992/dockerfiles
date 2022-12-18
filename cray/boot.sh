#!/usr/bin/env sh

/usr/bin/supervisorctl start caddy > /dev/null

ACME_WATING_SECONDS=${ACME_WATING_SECONDS:-180}
ACME_DIR=${ACME_DIR:-'acme-v02.api.letsencrypt.org-directory'}

if [[ "${DOMAIN}" != "" ]]; then
    ACME_CERT_FILE=/data/caddy/certificates/${ACME_DIR}/${DOMAIN}/${DOMAIN}.crt
    WAITING=0
    while [[ ! -f ${ACME_CERT_FILE}  && $WAITING -lt $ACME_WATING_SECONDS ]]; do
        echo "[cray] Wating Acme Certificate (${WAITING}): ${DOMAIN}"; sleep 5;
        WAITING=$((WAITING+5))
    done
fi

if [[ "${DOMAIN_CDN}" != "" ]]; then
    ACME_CERT_FILE=/data/caddy/certificates/${ACME_DIR}/${DOMAIN_CDN}/${DOMAIN_CDN}.crt
    WAITING=0
    while [[ ! -f ${ACME_CERT_FILE}  && $WAITING -lt $ACME_WATING_SECONDS ]]; do
        echo "[cray] Wating Acme Certificate (${WAITING}): ${DOMAIN_CDN}"; sleep 5;
        WAITING=$((WAITING+5))
    done
fi

/usr/bin/supervisorctl start v2ray > /dev/null

/usr/bin/supervisorctl start xray > /dev/null

if [[ "${DOMAIN}" != "" && ${CLOUDFLARE_ZONE_ID} ]]; then
    curl --request POST \
      --url https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records \
      --header 'Content-Type: application/json' \
      --header "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
      --data "{ \
        \"type\": \"A\", \
        \"comment\": \"Automatically Created by Cray\", \
        \"content\": \"${IPV4_ADDRESS}\", \
        \"name\": \"${DOMAIN}\", \
        \"priority\": 10, \
        \"proxied\": false, \
        \"ttl\": 1  \
    }"
fi

ACME_CERT_FILE_CDN=/data/caddy/certificates/${ACME_DIR}/${DOMAIN_CDN}/${DOMAIN_CDN}.crt
if [[ "${DOMAIN_CDN}" != "" && ${CLOUDFLARE_ZONE_ID} && -f ${ACME_CERT_FILE_CDN} ]]; then
    curl --request POST \
      --url https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records \
      --header 'Content-Type: application/json' \
      --header "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
      --data "{ \
        \"type\": \"A\", \
        \"comment\": \"Automatically Created by Cray\", \
        \"content\": \"${IPV4_ADDRESS}\", \
        \"name\": \"${DOMAIN_CDN}\", \
        \"priority\": 10, \
        \"proxied\": true, \
        \"ttl\": 1  \
    }"
fi
