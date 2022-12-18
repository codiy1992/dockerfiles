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
    curl -s --request POST \
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
    curl -s --request POST \
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

# Automatically Remove Old DNS records when CLOUDFLARE_ZONE_ID environment variable is set.
function json_parse() {
    awk -v json="$1" -v key="$2" -v defaultValue="$3" 'BEGIN{
        foundKeyCount = 0
        while (length(json) > 0) {
            pos = match(json, "\""key"\"[ \\t]*?:[ \\t]*");
            if (pos == 0) {if (foundKeyCount == 0) {print defaultValue;} exit 0;}

            ++foundKeyCount;
            start = 0; stop = 0; layer = 0;
            for (i = pos + length(key) + 1; i <= length(json); ++i) {
                lastChar = substr(json, i - 1, 1)
                currChar = substr(json, i, 1)

                if (start <= 0) {
                    if (lastChar == ":") {
                        start = currChar == " " ? i + 1: i;
                        if (currChar == "{" || currChar == "[") {
                            layer = 1;
                        }
                    }
                } else {
                    if (currChar == "{" || currChar == "[") {
                        ++layer;
                    }
                    if (currChar == "}" || currChar == "]") {
                        --layer;
                    }
                    if ((currChar == "," || currChar == "}" || currChar == "]") && layer <= 0) {
                        stop = currChar == "," ? i : i + 1 + layer;
                        break;
                    }
                }
            }

            if (start <= 0 || stop <= 0 || start > length(json) || stop > length(json) || start >= stop) {
                if (foundKeyCount == 0) {print defaultValue;} exit 0;
            } else {
                print substr(json, start, stop - start);
            }

            json = substr(json, stop + 1, length(json) - stop)
        }
    }'
}

if [[ ${CLOUDFLARE_ZONE_ID} && "${IPV4_ADDRESS}" != "${IPV4_OLD}" && "${IPV4_OLD}" != "" ]]; then
    RESULT=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records?type=A&content=${IPV4_OLD}&match=all&comment=Automatically Created by Cray" \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}")

    RECORD_IDS=$(json_parse $RESULT "id")
    for RECORD_ID in ${RECORD_IDS}; do
        curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records/${RECORD_ID}" \
         -H "Content-Type: application/json" \
         -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}"
    done
fi
