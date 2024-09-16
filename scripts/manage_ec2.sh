#!/bin/bash

source config.sh

if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
  echo "AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY must be set as environment" \
    "variables! Exiting." >&2
  exit 1
fi

# fetch ids of dev instance and bastion host in one call
INSTANCE_IDS=$(aws ec2 describe-instances \
  --filters "Name=tag:User,Values=\"$USERNAME\"" \
  --query "Reservations[*].Instances[*].InstanceId" \
  --output text \
  --region "$REGION")

if [ -z "$INSTANCE_IDS" ]; then
  echo "No instance found with tag 'Name=$USERNAME'."
  exit 1
fi

ACTION=$1
if [ "$ACTION" == "start" ]; then
  aws ec2 start-instances --instance-ids $INSTANCE_IDS
elif [ "$ACTION" == "stop" ]; then
  aws ec2 stop-instances --instance-ids $INSTANCE_IDS
else
  echo "Invalid action: $ACTION. Use 'start' or 'stop'."
  exit 1
fi
