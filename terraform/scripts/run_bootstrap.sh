#!/bin/bash

BOOTSTRAP_SCRIPT_PATH="$(pwd)/scripts/bootstrap.sh"
RETRIES=30
SLEEP_INTERVAL=10


# wait for connectivity
for i in $(seq 1 $RETRIES); do
  ssh remote-dev-ec2 'echo SSH connection successful' > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "SSH connection established on attempt #$i!"
    break
  fi
  echo "SSH connection failed. Retrying in $SLEEP_INTERVAL seconds... (Attempt $i/$RETRIES)"
  sleep $SLEEP_INTERVAL
done

if [ $i -eq $RETRIES ]; then
  echo "Failed to establish SSH connection after $RETRIES attempts. Cannot bootstrap" \
    "the EC2 with Pyenv, Poetry and Docker. Please, do it manually."
  exit 1
fi


# upload bootstrap script to dev instance
echo "Uploading bootstrap script to the remote dev instance..."
scp "$BOOTSTRAP_SCRIPT_PATH" remote-dev-ec2:/home/ubuntu/bootstrap.sh

if [ $? -eq 0 ]; then
  echo "Bootstrap script uploaded successfully!"
else
  echo "Failed to upload bootstrap script to remote instance. Exiting."
  exit 1
fi


# execute bootstrap
echo "Executing bootstrap script on the remote dev instance..."
ssh remote-dev-ec2 /home/ubuntu/bootstrap.sh

if [ $? -eq 0 ]; then
  echo "Bootstrap script executed successfully!"
else
  echo "Failed to execute the bootstrap script on the remote instance. Exiting."
  exit 1
fi
