#!/bin/sh

PREFIX=`etcdctl get /_arken.io/key`
USERNAME=${PREFIX}-${ENV_TECH_ID}
BUCKET=`etcdctl get /_arken.io/config/s3/bucket`

/opt/data/tools/awscli &> /dev/null
if [ ! $? -eq 2 ]; then
  echo "AWSCLI is missing."
  exit 1
fi

# Creating S3 user if needed
/opt/data/tools/awscli iam get-user --user-name $USERNAME &> /dev/null
if [ ! $? -eq 0 ]; then
  RAND=`openssl rand -hex 5`
  DIRECTORY=${ENV_TECH_ID}

  /opt/data/tools/awscli iam create-user --user-name $USERNAME --path /container/${PREFIX}/

  # UserPolicy to allow user only on his own directory
  USER_POLICY="{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"${RAND}1\",\"Effect\":\"Allow\",\"Action\":[\"s3:*\"],\"Resource\":[\"arn:aws:s3:::${BUCKET}\"]},{\"Sid\":\"${RAND}2\",\"Effect\":\"Allow\",\"Action\":[\"s3:*\"],\"Resource\":[\"arn:aws:s3:::${BUCKET}/${DIRECTORY}/*\"]},{\"Sid\":\"${RAND}3\",\"Effect\":\"Allow\",\"Action\":[\"s3:ListAllMyBuckets\"],\"Resource\":[\"arn:aws:s3:::${BUCKET}\"]}]}"
  /opt/data/tools/awscli iam put-user-policy --user-name ${USERNAME} --policy-name ${USERNAME} --policy-document "${USER_POLICY}"

  KEYS_RES=`/opt/data/tools/awscli iam create-access-key --user-name ${USERNAME}`

  etcdctl set /services/${ENV_TECH_ID}/config/s3/bucket ${BUCKET}
  etcdctl set /services/${ENV_TECH_ID}/config/s3/username ${USERNAME}
  etcdctl set /services/${ENV_TECH_ID}/config/s3/awsid `echo ${KEYS_RES} | awk '{print $2}'`
  etcdctl set /services/${ENV_TECH_ID}/config/s3/awssecret `echo ${KEYS_RES} | awk '{print $4}'`

  sleep 10
fi

# Check bucket/awscli up and running
exec /opt/data/tools/awscli s3api head-bucket --bucket ${BUCKET}
