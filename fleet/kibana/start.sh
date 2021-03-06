#!/bin/sh -

ESL_HOST=`etcdctl ls --recursive /services/elasticsearchlogs \
  | grep transport \
  | shuf -n 1 \
  | xargs etcdctl get \
  | sed -e 's/{"host":"\([^"]*\)","port":\([^"]*\)}/\1/'`
ESL_PORT=9201
COOKIE_EXPIRATION=0.5
COOKIE_SECRET=`openssl rand -hex 15`

GOOGLE_CLIENTID=`etcdctl get /services/kibana/config/google/clientid`
GOOGLE_CLIENTSECRET=`etcdctl get /services/kibana/config/google/clientsecret`
GOOGLE_DOMAIN=`etcdctl get /services/kibana/config/google/domain`

/opt/data/tools/docker-clean.sh ${KIBANA_NAME} &> /dev/null

/usr/bin/docker run --rm -P -t --name ${KIBANA_NAME} \
  -e ESL_HOST="${ESL_HOST}" \
  -e ESL_PORT="${ESL_PORT}" \
  -e COOKIE_EXPIRATION="${COOKIE_EXPIRATION}" \
  -e COOKIE_SECRET="${COOKIE_SECRET}" \
  -e GOOGLE_CLIENTID="${GOOGLE_CLIENTID}" \
  -e GOOGLE_CLIENTSECRET="${GOOGLE_CLIENTSECRET}" \
  -e GOOGLE_DOMAIN="${GOOGLE_DOMAIN}" \
  quay.io/nuxeoio/kibana
