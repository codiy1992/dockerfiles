#!/usr/bin/env sh

CFN_TEMPLATE=/tmp/cloudfront.yaml
STACK_NAME=crazy-${INSTANCE_ID}

if [[ ! ${INSTANCE_ID} ]]; then
    echo "environment variable INSTANCE_ID not found";
    return;
fi

sed '/^[[:blank:]]*#/d;s/#.*//' /etc/crazy/scripts/cfn-cloudfront.yaml > ${CFN_TEMPLATE}
sed -i "s/ORIGIN_SERVER/${AWS_CLOUDFRONT_ORIGIN_SERVER-${DOMAIN}}/g" ${CFN_TEMPLATE}
sed -i "s/INSTANCE_ID/${INSTANCE_ID}/g" ${CFN_TEMPLATE}

# Custom Domain
if [[ ! ${AWS_ACM_CERTIFICATE_ID} || ! ${AWS_CLOUDFRONT_ALIAS} ]]; then
    sed -i '/Aliases:/d;/ViewerCertificate:/d;/AcmCertificateArn:/d' ${CFN_TEMPLATE}
    sed -i '/MinimumProtocolVersion:/d;/SslSupportMethod:/d' ${CFN_TEMPLATE}
else
    sed -i "s/AWS_CLOUDFRONT_ALIAS/${AWS_CLOUDFRONT_ALIAS}/g" ${CFN_TEMPLATE}
    sed -i "s/AWS_ACM_CERTIFICATE_ID/${AWS_ACM_CERTIFICATE_ID}/g" ${CFN_TEMPLATE}
fi

# Use Http or Https connect to origin
if [[ ${AWS_CLOUDFRONT_WITH_HTTP_PORT} ]]; then
    sed -i "/OriginSSLProtocols:/d" ${CFN_TEMPLATE}
    sed -i "s/OriginProtocolPolicy: https-only/OriginProtocolPolicy: http-only/g" ${CFN_TEMPLATE}
    sed -i "s/HTTPPort: 80/HTTPPort: ${AWS_CLOUDFRONT_WITH_HTTP_PORT}/g" ${CFN_TEMPLATE}
fi

aws cloudformation describe-stacks --stack-name ${STACK_NAME}

if [[ $? -ne 0 ]]; then

    # Create New Stack
    aws cloudformation create-stack --stack-name ${STACK_NAME} --template-body file://${CFN_TEMPLATE}

    STACK_STATUS=CREATING

    WAITING=0
    while [[ "${STACK_STATUS//\"/}" != *COMPLETE && ${WAITING} -lt 300 ]]; do
        echo "Creating Cloudfront Stack (${WAITING})"; sleep 15;
        STACK_STATUS=$(aws cloudformation describe-stacks --stack-name ${STACK_NAME} | jq '.Stacks[0].StackStatus')
        WAITING=$((WAITING+15))
    done

    if [[ "${STACK_STATUS//\"/}" == "CREATE_COMPLETE" ]]; then
        echo "Cloudfront Distribution Created Successfully"
    else
        echo "Cloudfront Distribution Creation Failed! Check error information in AWS Console"
        return ;
    fi
else

    # Create Change Set
    CHANGE_SET_NAME=crazy-$(date "+%Y-%m-%d-%H-%M-%S")
    aws cloudformation create-change-set --stack-name ${STACK_NAME} --template-body file://${CFN_TEMPLATE} \
        --change-set-name ${CHANGE_SET_NAME}

    WAITING=0
    CHANGE_SET_STATUS=CREATE_IN_PROGRESS
    while [[ "${CHANGE_SET_STATUS//\"/}" == "CREATE_IN_PROGRESS" && ${WAITING} -lt 60 ]]; do
        echo "Wating cloudformation ChangeSet (${WAITING})"; sleep 5;
        RESULT=$(aws cloudformation describe-change-set --stack-name ${STACK_NAME} --change-set-name ${CHANGE_SET_NAME})
        CHANGE_SET_STATUS=$(echo "${RESULT}"| jq '.Status')
        WAITING=$((WAITING+5))
    done

    CHANGE_SET_STATUS=$(echo ${RESULT} | jq '.ExecutionStatus')
    if [[ "${CHANGE_SET_STATUS//\"/}" == "AVAILABLE" ]]; then
        aws cloudformation execute-change-set --stack-name ${STACK_NAME} --change-set-name ${CHANGE_SET_NAME}
        STACK_STATUS=CREATING
        WAITING=0
        while [[ "${STACK_STATUS//\"/}" != *COMPLETE && ${WAITING} -lt 300 ]]; do
            echo "Updating Cloudfront (${WAITING})"; sleep 10;
            STACK_STATUS=$(aws cloudformation describe-stacks --stack-name ${STACK_NAME} | jq '.Stacks[0].StackStatus')
            WAITING=$((WAITING+10))
        done
        if [[ "${STACK_STATUS//\"/}" == "UPDATE_COMPLETE" ]]; then
            echo "Cloudfront Distribution Updated Successfully"
        else
            echo "Cloudfront Distribution Update Failed! Check error information in AWS Console"
            return ;
        fi
    else
        echo "Nothing Changed!"
        aws cloudformation delete-change-set --stack-name ${STACK_NAME} --change-set-name ${CHANGE_SET_NAME}
    fi

fi

# Query Distribution Domain Name
DISTRIBUTION_ID=$(aws cloudformation describe-stack-resource --stack-name ${STACK_NAME} \
    --logical-resource-id Distribution | jq '.StackResourceDetail.PhysicalResourceId')
DISTRIBUTION_DOMAIN=$(aws cloudfront get-distribution --id ${DISTRIBUTION_ID//\"/} | jq '.Distribution.DomainName')
DISTRIBUTION_DOMAIN=${DISTRIBUTION_DOMAIN//\"/}

# Creating CNAME Record for Alias
if [[ "${AWS_CLOUDFRONT_ALIAS}" != "" && ${CLOUDFLARE_ZONE_ID} ]]; then
    RESULT=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records?type=CNAME&content=${DISTRIBUTION_DOMAIN}&match=all" \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}")
    EXIST_NAME=$(echo "$RESULT" |jq '.result[0].name')
    if [[ "${EXIST_NAME}" != "null" && "${EXIST_NAME//\"/}" != "${AWS_CLOUDFRONT_ALIAS}" ]]; then
        echo "Deleting former DNS Records:"
        RECORD_IDS=$(echo "$RESULT" | jq '.result[].id')
        for RECORD_ID in ${RECORD_IDS}; do
            echo $(curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records/${RECORD_ID//\"/}" \
             -H "Content-Type: application/json" \
             -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}")
        done
        NEED_CREATE_NEW_RECORD=true
    fi

    if [[ "${EXIST_NAME}" == "null" || "${NEED_CREATE_NEW_RECORD}" != "" ]]; then
        echo "Creating DNS Record ${AWS_CLOUDFRONT_ALIAS} -> ${DISTRIBUTION_DOMAIN}:"
        echo $(curl -s --request POST \
          --url https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records \
          --header 'Content-Type: application/json' \
          --header "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
          --data "{ \
            \"type\": \"CNAME\", \
            \"comment\": \"Automatically Created by crazy\", \
            \"content\": \"${DISTRIBUTION_DOMAIN}\", \
            \"name\": \"${AWS_CLOUDFRONT_ALIAS}\", \
            \"priority\": 10, \
            \"proxied\": false, \
            \"ttl\": 1  \
        }")
    fi
fi
