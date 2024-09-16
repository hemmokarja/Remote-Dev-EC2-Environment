#!/bin/bash

BOOTSTRAP_SCRIPT_PATH_="$(pwd)/scripts/bootstrap.sh"
RETRIES=30
SLEEP_INTERVAL=5


wait_for_ssh_connectivity() {
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
}

upload_bootstrap_to_dev_instance() {
  echo "Uploading bootstrap script to the remote dev instance..."
  scp "$BOOTSTRAP_SCRIPT_PATH_" remote-dev-ec2:$HOME/bootstrap.sh

  if [ $? -eq 0 ]; then
    echo "Bootstrap script uploaded successfully!"
  else
    echo "Failed to upload bootstrap script to remote instance. Exiting."
    exit 1
  fi
}

execute_bootstrap() {
  echo "Executing bootstrap script on the remote dev instance..."
  ssh remote-dev-ec2 $HOME/bootstrap.sh

  if [ $? -eq 0 ]; then
    echo "Bootstrap script executed successfully!"
  else
    echo "Failed to execute the bootstrap script on the remote instance. Exiting."
    exit 1
  fi
}

remove_bootstrap() {
  echo "Removing bootstrap script on the remote dev instance..."
  ssh remote-dev-ec2 "rm -f $HOME/bootstrap.sh"
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
