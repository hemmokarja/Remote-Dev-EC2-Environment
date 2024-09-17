#!/bin/bash

source config.sh
source ./scripts/util.sh

KEY_NAME="dev-env-key"
SSH_DIR="$(pwd)/terraform/.ssh"
PRIVATE_KEY_PATH="$SSH_DIR/$KEY_NAME"
PUBLIC_KEY_PATH="$PRIVATE_KEY_PATH.pub"
SSH_CONFIG_BACKUP_PATH="$SSH_DIR/config.bak"
SSH_CONFIG_PATH="$HOME/.ssh/config"
RUN_BOOTSTRAP_SCRIPT_PATH="$(pwd)/scripts/run_bootstrap.sh"
LOCAL_PUBLIC_IP=""
BASTION_PUBLIC_IP=""

cd terraform

generate_ssh_keys() {
  if [ ! -d "$SSH_DIR" ]; then
    mkdir -p "$SSH_DIR"
  fi

  if [ -f "$PRIVATE_KEY_PATH" ]; then
    echo "SSH key already exists at $PRIVATE_KEY_PATH. Skipping key generation."
  else
    echo "Generating SSH key pair '$KEY_NAME' to '$SSH_DIR/'"
    ssh-keygen -t rsa -b 4096 -f "$PRIVATE_KEY_PATH" -C "$KEY_NAME" -N "" > /dev/null 2>&1
    chmod 600 "$PRIVATE_KEY_PATH"
    chmod 644 "$PUBLIC_KEY_PATH"
  fi
}

fetch_local_ip() {
  LOCAL_PUBLIC_IP=$(curl -s http://checkip.amazonaws.com)
  if [ -z "$LOCAL_PUBLIC_IP" ]; then
    echo "Failed to fetch public IP. Exiting."
    exit 1
  else
    echo "Your public IP is: $LOCAL_PUBLIC_IP"
  fi
}

init_terraform() {
  if [ ! -d ".terraform" ]; then
    echo "Initializing Terraform..."
    terraform init
  fi  
}

apply_terraform() {
  echo "Applying Terraform configuration (this might take a while)..."
  terraform apply \
    -var "username=$USERNAME" \
    -var "region=$REGION" \
    -var "dev_instance_type=$DEV_INSTANCE_TYPE" \
    -var "bastion_instance_type=$BASTION_INSTANCE_TYPE" \
    -var "key_pair_name=$KEY_NAME" \
    -var "public_key_path=$PUBLIC_KEY_PATH" \
    -var "local_public_ip=$LOCAL_PUBLIC_IP/32" \
    -var "dev_instance_private_ip=$DEV_INSTANCE_PRIVATE_IP" \
    -auto-approve
  
  if [ $? -ne 0 ]; then
    echo "Terraform apply failed. Exiting."
    exit 1
  fi

  BASTION_PUBLIC_IP=$(terraform output -raw bastion_public_ip 2>/dev/null)
  if [ $? -ne 0 ]; then
    echo "Failed to obtain Bastion Host's public IP from Terraform output. Exiting."
    exit 1
  fi

  if [ -z "$BASTION_PUBLIC_IP" ]; then
    echo "Bastion Host's public IP is empty. Exiting."
    exit 1
  fi
}

configure_ssh_access() {
  if [ ! -f "$SSH_CONFIG_PATH" ]; then
    touch "$SSH_CONFIG_PATH"
    echo "Created new SSH config file at $SSH_CONFIG_PATH."
  fi

  cp "$SSH_CONFIG_PATH" "$SSH_CONFIG_BACKUP_PATH"
  echo "Created a backup of SSH config file before modifications to" \
      "$SSH_CONFIG_BACKUP_PATH"

  SSH_CONFIG="
  Host $BASTION_SSH_ALIAS
    HostName $BASTION_PUBLIC_IP
    User ubuntu
    IdentityFile $PRIVATE_KEY_PATH

  Host $DEV_INSTANCE_SSH_ALIAS
    HostName $DEV_INSTANCE_PRIVATE_IP
    User ubuntu
    IdentityFile $PRIVATE_KEY_PATH
    ProxyJump $BASTION_SSH_ALIAS
  "

  if ! grep -q "Host $BASTION_SSH_ALIAS" "$SSH_CONFIG_PATH"; then
    echo "Adding SSH config for $BASTION_SSH_ALIAS and $DEV_INSTANCE_SSH_ALIAS to" \
      "~/.ssh/config..."
    echo "$SSH_CONFIG" >> "$SSH_CONFIG_PATH"
    echo "Config added."
  else
    echo "SSH config for for $BASTION_SSH_ALIAS and $DEV_INSTANCE_SSH_ALIAS already" \
      "exists." "Skipping addition."
  fi
}

run_bootstrap() {
  if [ -x "$RUN_BOOTSTRAP_SCRIPT_PATH" ]; then
    echo "Running bootstrap script..."
    $RUN_BOOTSTRAP_SCRIPT_PATH
  else
    echo "Bootstrap script not found or not executable: $RUN_BOOTSTRAP_SCRIPT_PATH"
    exit 1
  fi
}


check_commands
check_aws_env
generate_ssh_keys
fetch_local_ip
init_terraform
apply_terraform
configure_ssh_access

echo "The private IP of the dev instance is: $DEV_INSTANCE_PRIVATE_IP"
echo "The public IP of the bastion host is: $BASTION_PUBLIC_IP"

cd - > /dev/null

run_bootstrap

echo "Your instance is ready for use! Login by running 'ssh $DEV_INSTANCE_SSH_ALIAS'."
