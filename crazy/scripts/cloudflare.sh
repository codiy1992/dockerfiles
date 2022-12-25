#!/usr/bin/env sh
CLOUDFLARE_API_ENDPOINT=https://api.cloudflare.com/client/v4

# Automatically Create new DNS Record
if [[ "${DOMAIN}" != "" && ${CLOUDFLARE_ZONE_ID} ]]; then
    echo "Creating DNS Record ${DOMAIN} -> ${IPV4_ADDRESS}:"
    echo $(curl -s --request POST \
      --url https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records \
      --header 'Content-Type: application/json' \
      --header "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
      --data "{ \
        \"type\": \"A\", \
        \"comment\": \"Automatically Created by crazy\", \
        \"content\": \"${IPV4_ADDRESS}\", \
        \"name\": \"${DOMAIN}\", \
        \"priority\": 10, \
        \"proxied\": false, \
        \"ttl\": 1  \
    }")
fi

ACME_DIR=${ACME_DIR:-'acme-v02.api.letsencrypt.org-directory'}
ACME_CERT_FILE_CDN=/data/caddy/certificates/${ACME_DIR}/${DOMAIN_CDN}/${DOMAIN_CDN}.crt
if [[ "${DOMAIN_CDN}" != "" && ${CLOUDFLARE_ZONE_ID} && -f ${ACME_CERT_FILE_CDN} ]]; then
    echo "Creating DNS Record ${DOMAIN_CDN} -> ${IPV4_ADDRESS}:"
    echo $(curl -s --request POST \
      --url https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records \
      --header 'Content-Type: application/json' \
      --header "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
      --data "{ \
        \"type\": \"A\", \
        \"comment\": \"Automatically Created by crazy\", \
        \"content\": \"${IPV4_ADDRESS}\", \
        \"name\": \"${DOMAIN_CDN}\", \
        \"priority\": 10, \
        \"proxied\": true, \
        \"ttl\": 1  \
    }")
fi

# Automatically Remove Old DNS records when CLOUDFLARE_ZONE_ID environment variable is set.
if [[ ${CLOUDFLARE_ZONE_ID} && "${IPV4_ADDRESS}" != "${IPV4_OLD}" && "${IPV4_OLD}" != "" ]]; then
    RESULT=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records?type=A&content=${IPV4_OLD}&match=all" \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}")

    echo "Deleting former DNS Records:"
    RECORD_IDS=$(echo "$RESULT" | jq '.result[].id')
    for RECORD_ID in ${RECORD_IDS}; do
        echo $(curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records/${RECORD_ID//\"/}" \
         -H "Content-Type: application/json" \
         -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}")
    done
fi


# Cloudflare Worker
if [[ ${CLOUDFLARE_ACCOUNT_ID} && ${CLOUDFLARE_ZONE_NAME} ]]; then
    SCRIPT_NAME="w${IPV4_NAME}"
    HOSTNAME="${SCRIPT_NAME}.${CLOUDFLARE_ZONE_NAME}"
    SCRIPT_NAME_OLD="w${IPV4_OLD//./}"
    HOSTNAME_OLD="${SCRIPT_NAME_OLD}.${CLOUDFLARE_ZONE_NAME}"
    SCRIPT_CONTENT=$(cat /etc/crazy/cloudflare_worker_scrpit.js 2> /dev/null)
    if [[ "${SCRIPT_CONTENT}" == "" ]]; then
        SCRIPT_CONTENT="addEventListener(
            'fetch', event => {
                let url = new URL(event.request.url);
                url.hostname = '${DOMAIN}';
                url.protocol = 'https';
                let request = new Request(url, event.request);
                event.respondWith(
                    fetch(request)
                )
            }
        )"
    fi

    # Upload Worker Script
    echo "Uploading Worker Script:"
    echo $(curl -s -X PUT "${CLOUDFLARE_API_ENDPOINT}/accounts/${CLOUDFLARE_ACCOUNT_ID}/workers/scripts/${SCRIPT_NAME}" \
      -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
      -H 'Content-Type: application/javascript' \
      --data "${SCRIPT_CONTENT}")

    # Attach to Domain
    echo "Attaching to Domain:"
    echo $(curl -s -X PUT "${CLOUDFLARE_API_ENDPOINT}/accounts/${CLOUDFLARE_ACCOUNT_ID}/workers/domains" \
      -H 'Content-Type: application/json' \
      -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
      --data "{ \
        \"zone_id\": \"${CLOUDFLARE_ZONE_ID}\", \
        \"hostname\": \"${HOSTNAME}\", \
        \"service\": \"${SCRIPT_NAME}\", \
        \"environment\": \"production\" \
    }")

    # Query Old Domain Record
    echo "Quering Old Records ..."
    RESULT=$(curl -s -X GET "${CLOUDFLARE_API_ENDPOINT}/accounts/${CLOUDFLARE_ACCOUNT_ID}/workers/domains?zone_id=${CLOUDFLARE_ZONE_ID}&hostname=${HOSTNAME_OLD}&service=${SCRIPT_NAME_OLD}&environment=production" \
         -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
         -H "Content-Type: application/json")
    RECORD_ID=$(echo "${RESULT}" | jq '.result[].id')

    # Detach from Domain
    echo "Detaching from Domain..."
    echo $(curl -s -X DELETE "${CLOUDFLARE_API_ENDPOINT}/accounts/${CLOUDFLARE_ACCOUNT_ID}/workers/domains/${RECORD_ID//\"/}" \
         -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
         -H "Content-Type: application/json")

    # Delete Old Script
    echo "Deleting from Domain..."
    echo $(curl -s -X DELETE "${CLOUDFLARE_API_ENDPOINT}/accounts/${CLOUDFLARE_ACCOUNT_ID}/workers/scripts/${SCRIPT_NAME_OLD}" \
         -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
         -H "Content-Type: application/json")

fi
