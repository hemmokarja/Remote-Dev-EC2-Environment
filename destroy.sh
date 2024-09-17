#!/bin/bash

source config.sh
source ./scripts/util.sh

cd terraform

KEY_NAME="dev-env-key"
SSH_DIR="$(pwd)/.ssh"
PUBLIC_KEY_PATH="$SSH_DIR/$KEY_NAME.pub"
DUMMY_IP="0.0.0.0"
SSH_CONFIG_BACKUP_PATH="$SSH_DIR/config.bak"
SSH_CONFIG_PATH="$HOME/.ssh/config"
BASTION_INSTANCE_NAME="$USERNAME'sBastionHost"
BASTION_PUBLIC_IP=""

fetch_bastion_ip() {
  BASTION_PUBLIC_IP=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=\"$BASTION_INSTANCE_NAME\"" \
    --query "Reservations[*].Instances[*].PublicIpAddress" \
    --output text \
    --region $REGION)

  if [ -z "$BASTION_PUBLIC_IP" ]; then
    echo "Error: No public IP found for instance with name $BASTION_INSTANCE_NAME in " \
      "region $REGION. SSH fingerprint won't be removed from known host successfully."
  fi
}

destroy_terraform() {
  echo "Destroying Terraform resources (this might take a while)..."
  terraform destroy \
    -var "username=$USERNAME" \
    -var "region=$REGION" \
    -var "dev_instance_type=$DEV_INSTANCE_TYPE" \
    -var "bastion_instance_type=$BASTION_INSTANCE_TYPE" \
    -var "key_pair_name=$KEY_NAME" \
    -var "public_key_path=$PUBLIC_KEY_PATH" \
    -var "local_public_ip=$DUMMY_IP/32" \
    -var "dev_instance_private_ip=$DUMMY_IP" \
    -auto-approve
}

restore_original_ssh_config() {
  if [ -f "$SSH_CONFIG_BACKUP_PATH" ]; then
    if [ -f "$SSH_CONFIG_PATH" ]; then
      cp "$SSH_CONFIG_BACKUP_PATH" "$SSH_CONFIG_PATH"
      echo "Restored SSH config from backup to $SSH_CONFIG_PATH."
    else
      echo "Original SSH config file not found. Restoring backup as the SSH config file."
      cp "$SSH_CONFIG_BACKUP_PATH" "$SSH_CONFIG_PATH"
    fi
  else
    echo "No backup found at $SSH_CONFIG_BACKUP_PATH. No changes made to SSH config." \
      "Review SSH config at $SSH_CONFIG_PATH and manually remove entries for" \
      "$DEV_INSTANCE_SSH_ALIAS and $BASTION_SSH_ALIAS."
  fi
}

remove_ssh_fingerprints() {
  ssh-keygen -R $DEV_INSTANCE_PRIVATE_IP > /dev/null 2>&1
  ssh-keygen -R $BASTION_PUBLIC_IP > /dev/null 2>&1
  echo "Removed SSH key fingerprints from known hosts."
}

remove_ssh_dir() {
  if [ -d "$SSH_DIR" ]; then
    rm -rf "$SSH_DIR"
    echo "Local configuration directory deleted."
  fi
}


check_commands
check_aws_env
fetch_bastion_ip
destroy_terraform
restore_original_ssh_config
remove_ssh_fingerprints
remove_ssh_dir

echo "All resources cleaned up!"

cd - > /dev/null