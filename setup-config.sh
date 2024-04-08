#!/bin/bash

#export TAP_URL='https://...'
export TAP_TOKEN=`bdcli account tap-client-token --disable-spinner | jq -r .bdTapToken`

if [ -z "${TAP_TOKEN}" ];
then
    echo "==> Please set TAP_TOKEN environment variable (bdcli account tap-client-token)"
    ERROR=1
fi

if [ -z "${TAP_URL}" ];
then
    echo "==> Please set TAP_URL environment variable (see the Data Tap deployment output of the Lambda Function URL)"
    ERROR=1
fi

if [ $ERROR ];
then
    exit 1
fi

TAP_HOST=`echo $TAP_URL | sed 's@https:@@g' | sed 's@/@@g'`
cat __fluent-bit.conf | sed "s|TAP_TOKEN|\"${TAP_TOKEN}\"|g" | sed "s|TAP_HOST|\"${TAP_HOST}\"|g" > fluent-bit.conf
