#!/bin/bash

source config.sh

echo "ssh alias: $DEV_INSTANCE_SSH_ALIAS"

BOOTSTRAP_SCRIPT_PATH_="$(pwd)/scripts/bootstrap.sh"


wait_for_ssh_connectivity() {
  local retries=30
  local sleep_interval=5

  for ((i=1; i<=retries; i++)); do
    ssh "$DEV_INSTANCE_SSH_ALIAS" 'echo SSH connection successful' > /dev/null 2>&1
    if [ $? -eq 0 ]; then
      echo "Established SSH connectivity!"
      return 0
    else
      echo "Waiting for SSH connectivity... (attempt $i/$retries)"
      sleep $sleep_interval
    fi
  done

  echo "SSH connection timed out after $retries attempts. Could not bootstrap " \
    "the dev instance with dev toolkit. Exiting."
  exit 1
}

upload_bootstrap_to_dev_instance() {
  echo "Uploading bootstrap script to the remote dev instance..."
  scp "$BOOTSTRAP_SCRIPT_PATH_" "$DEV_INSTANCE_SSH_ALIAS:/home/ubuntu/bootstrap.sh"

  if [ $? -eq 0 ]; then
    echo "Bootstrap script uploaded successfully!"
  else
    echo "Failed to upload bootstrap script to remote instance. Exiting."
    exit 1
  fi
}

execute_bootstrap() {
  echo "Executing bootstrap script on the remote dev instance..."
  ssh "$DEV_INSTANCE_SSH_ALIAS" /home/ubuntu/bootstrap.sh

  if [ $? -eq 0 ]; then
    echo "Bootstrap script executed successfully!"
  else
    echo "Failed to execute the bootstrap script on the remote instance. Exiting."
    exit 1
  fi
}

remove_bootstrap() {
  echo "Removing bootstrap script on the remote dev instance..."
  ssh "$DEV_INSTANCE_SSH_ALIAS" "rm -f /home/ubuntu/bootstrap.sh"
  if [ $? -eq 0 ]; then
    echo "Bootstrap script removed successfully!"
  else
    echo "Failed to remove the bootstrap script on the remote instance. Exiting."
    exit 1
  fi
}


wait_for_ssh_connectivity
upload_bootstrap_to_dev_instance
execute_bootstrap
remove_bootstrap
