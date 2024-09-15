variable "username" {
  description = "Username for the EC2 instances"
}

variable "region" {
  description = "The AWS region to deploy resources"
}

variable "dev_instance_type" {
  description = "EC2 instance type for the actual dev instance"
}

variable "bastion_instance_type" {
  description = "EC2 instance type for the bastion host instance"
}

variable "key_pair_name" {
  description = "Name of the SSH key pair"
}

variable "public_key_path" {
  description = "Path to the public key"
}

variable "local_public_ip" {
  description = "Your local machine's public IP address to allow SSH access"
}

variable "dev_instance_private_ip" {
  description = "Your remote dev machine's private IP address to "
}