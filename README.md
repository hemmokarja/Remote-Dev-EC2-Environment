# Remote Development EC2 Environment with Terraform

This project automates the setup of a secure, remote development environment on AWS using Terraform. It provisions key infrastructure components, such as EC2 instances and networking elements, to create an isolated and safe workspace for developers. By utilizing Terraform, the project ensures consistency and repeatability, reducing the complexity of managing AWS resources manually. The setup includes a development EC2 instance in a private subnet, accessible securely through a bastion host, ensuring that the development environment is shielded from direct exposure to the public internet.

The primary benefit of this project is the ability to quickly spin up a remote development environment that is scalable, secure, and easily accessible. This setup is ideal for developers needing isolated development spaces or compute capacity exceeding the local machine's limits. The solution also integrates network isolation, IAM roles for fine-grained security, and SSH access management, allowing users to focus on development without worrying about underlying infrastructure. Additionally, the environment includes essential tools like Python, Docker, and version control systems, making it ready for immediate use in a wide range of development tasks.

## Infrastructure Includes

- **Development EC2 Instance**: An EC2 instance with the most recent Ubuntu AMI, configured for development work.
- **Bastion EC2 Instance**: A bastion host that serves as a secure gateway to access the development EC2 instance. This instance is exposed to the public internet, allowing you to connect to it and then access the development instance.
- **VPC**: A Virtual Private Cloud for network isolation.
- **Private Subnet**: A subnet within the VPC where the development EC2 instance is located.
- **Public Subnet**: A subnet within the VPC where the bastion EC2 instance is located.
- **Internet and NAT Gateways**: For internet access and private network connectivity.
- **Routing Tables**: Configured for directing traffic within the VPC.
- **IAM Permissions**: The development EC2 instance has full access to EC2 and S3 actions. Permissions can be adjusted in `terraform/roles.tf` as needed.

## What You'll Need

- **Terraform**: Installed on your local machine (follow the [official installation guide](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)).
- **AWS Account**: An active AWS account to create and manage resources.
- **AWS CLI**: Installed on your local machine (follow the [official installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)).
- **AWS Access Keys**: Set up as environment variables (`AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`).
- **SSH**: Ensure `ssh` is installed on your machine to allow secure remote connections.

## Configuration

### Main Configuration

Edit the `config.sh` file to configure the following settings:
- **Region**: The AWS region where resources will be deployed (default: `eu-north-1`).
- **Development EC2 Instance Type**: Type of the EC2 instance used for development (default: `t3.micro`).
- **Bastion EC2 Instance Type**: Type of the EC2 instance used for the bastion host (default: `t3.micro`).
- **Username for Tagging Resources**: Username used for tagging AWS resources (default: `DevUser`).
  - Ensure that your AWS account does not have conflicting EC2 tags using the same username.
- **Development Instance SSH Alias**: Alias to be used in the SSH configuration file for connecting to the development EC2 instance (default: `remote-dev-ec2`).
  - Ensure that your SSH configuration file (`~/.ssh/config`) does not have conflicting aliases.
- **Bastion Instance SSH Alias**: Alias to be used in the SSH configuration file for connecting to the bastion EC2 instance (default: `remote-bastion-ec2`).
  - Ensure that your SSH configuration file (`~/.ssh/config`) does not have conflicting aliases.
- **Development Instance Private IP**: Private IP address assigned to the development EC2 instance (default: `10.0.2.10`).
  - There should not be a reason to change this. However, if you need to do so, ensure that the IP address is within the private subnet's CIDR block `10.0.2.0/24` and does not conflict with other private IP addresses within the network (e.g., AWS always reserves the first four and the last IP in a subnet for its own use).

### IAM Permissions

The deployment uses default EC2 and S3 full access for development instances. If these permissions are not sufficient for your use case, you can customize them as needed in the `terraform/roles.tf` file.

### Bootstrap Action

The deployment bootstraps the development EC2 with the following development toolkit:
- AWS CLI for programmatic interaction with AWS
- Pyenv for Python version management
- Poetry for dependency management
- Docker for containerization
- Python 3.12
- Bash prompt with current Git branch

If the default development toolkit is insufficient for your environment, you can customize the script `scripts/bootstrap.sh` to meet your needs.

(Note: Ubuntu AMI comes with Git installed by default.)

## How to Use

### Build Resources with `build.sh`
  - Generates SSH keys for accessing EC2 instances (stored in `terraform/.ssh/`).
  - Creates the necessary AWS resources using Terraform.
  - Configures `~/.ssh/config` with aliases specified in `config.sh` for easy SSH access.
  - Bootstraps the development EC2 instance with a basic Python development toolkit (see the "Bootstrap Action" section for more details).
  - **Important Security Check**: During the process, you will be prompted to confirm the authenticity of the hosts. You must verify that the IP addresses match those provided in the output. If they match, you can safely proceed with the connection.

### Use the Instance
  - **Via Terminal**: Connect to the development instance from your local machine via Terminal using:  
    ```bash
    ssh <DEV_INSTANCE_SSH_ALIAS>
    ```
  - **Via VS Code**: You can also easily connect to the development instance from VS Code. First, install the Remote-SSH extension. Then, press `Shift+Cmd+P` to open the command palette. Search for "Remote-SSH: Connect to Host", and press enter. You should see the configured `DEV_INSTANCE_SSH_ALIAS`. After selecting it, you can access the development instance's file system by pressing `Cmd+O`. For more info on Remote-SSH, see [here](https://code.visualstudio.com/docs/remote/ssh-tutorial)

### Start Instances with `start.sh`
  - Starts both the development and bastion EC2 instances.
  - This step is not required immediately after running `build.sh`, as the instances are already started.

### Stop Instances with `stop.sh`
  - Stops the development and bastion EC2 instances without terminating them.
  - Stopping instances preserves their state and all data on attached EBS volumes (disks).
  - The instances can be restarted later without data loss, as long as the EBS volumes are not set to delete on termination.

### Remove Resources with `destroy.sh`
  - Destroys all AWS resources created by Terraform.
  - Restores the original state of `~/.ssh/config`, removing the added SSH aliases.


## Costs

Running the remote instances involves costs that depend primarily on instance type. The costs may also vary between regions and are subject to change over time. As of September 16, 2024, the cost for a single default EC2 `t3.micro` instance with 1 GB of RAM in the `eu-north-1` region is $0.0108 per hour. Be sure to check the [latest AWS pricing](https://aws.amazon.com/ec2/pricing/on-demand/) for the most up-to-date information.


## Troubleshoot

### Why can't I access the development instance via SSH?

The deployment is configured so that the development instance can only be accessed via SSH from the public IP address of the user at the time the resources are built. This ensures security by restricting access to only your IP.

If your public IP has changed (for example, if you're using a dynamic IP or connected from a different network), the instance will no longer be accessible via SSH. 

#### Solution:
- **Update Security Group**: You will need to update the security group associated with the instance to allow SSH access from your new public IP. You can do this by modifying the security group rules of `BastionEC2SecurityGroup` in the AWS Console or using the AWS CLI:

  ```bash
  aws ec2 authorize-security-group-ingress --group-id <security-group-id> --protocol tcp --port 22 --cidr <your-new-ip>/32
  ```

- **Sync Terraform State**: After making manual changes to the security group, you should sync the local Terraform state to reflect these changes. This helps Terraform to stay aware of the current state of your infrastructure:

  ```bash
  cd terraform
  terraform refresh
  ```

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT). You are free to use, modify, and distribute the software as long as you include the original copyright and license notice. For more details, please refer to the full text of the license.
