#!/bin/bash

source config.sh

if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
  echo "AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY must be set as environment" \
    "variables! Exiting." >&2
  exit 1
fi

# get the instance IDs based on the tag
INSTANCE_IDS=$(aws ec2 describe-instances \
  --filters "Name=tag:User,Values=$USERNAME" \
  --query "Reservations[*].Instances[*].InstanceId" \
  --output text \
  --region $REGION)

if [ -z "$INSTANCE_IDS" ]; then
  echo "No instance found with tag 'User=$USERNAME'."
  exit 1
fi

aws ec2 stop-instances --instance-ids "$INSTANCE_IDS"
