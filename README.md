# Remote Development EC2 Environment with Terraform

This project automates the setup of a secure, remote development environment on AWS using Terraform. It provisions key infrastructure components, such as EC2 instances and networking elements, to create an isolated and safe workspace for developers. By utilizing Terraform, the project ensures consistency and repeatability, reducing the complexity of managing AWS resources manually. The setup includes a development EC2 instance in a private subnet, accessible securely through a bastion host, ensuring that the development environment is shielded from direct exposure to the public internet.

The primary benefit of this project is the ability to quickly spin up a remote development environment that is scalable, secure, and easily accessible. This setup is ideal for developers needing isolated development spaces or compute capacity exceeding the local machine's limits. The solution also integrates network isolation, IAM roles for fine-grained security, and SSH access management, allowing users to focus on development without worrying about underlying infrastructure. Additionally, the environment includes essential tools like Python, Docker, and version control systems, making it ready for immediate use in a wide range of development tasks.

## Infrastructure Includes

- **Development EC2 Instance**: An EC2 instance configured for development work.
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

## Configuration

- **Main Configuration**: Edit the `config.sh` file to configure the following:
  - Region (default: `eu-north-1`)
  - Development EC2 instance type (default: `t3.micro`, only 1 GB or RAM)
  - Bastion SEC2 instance type (default: `t3.micro`)
  - Username for tagging resources (default: `DevUser`)
    - Note: Ensure your AWS account does not have conflicting EC2 tags.
- **IAM Permissions**: If the default EC2 and S3 full access is not sufficient, adjust the permissions in `terraform/roles.tf`.
- **Bootstrap Action**: If the default development toolkit is not sufficient (see "How to Use" for details), tailor the bootstrap script to suit your requirements in `scripts/bootstrap.sh`.

## How to Use

1. **Build Resources with `build.sh`**:
  - Generates SSH keys for accessing EC2 instances (stored in `terraform/.ssh/`).
  - Creates the necessary AWS resources.
  - Configures `~/.ssh/config` with aliases `remote-dev-ec2` and `remote-dev-bastion` for easy SSH access.
    - Note: Ensure your `~/.ssh/config` does not have conflicting aliases.
  - Bootstraps the development EC2 instance with a basic Python development toolkit:
    - Pyenv for Python version management along with Python 3.12
    - Poetry for dependency management.
    - Docker for containerization.
  - **Important Security Check**: During the process, you will be prompted to confirm the authenticity of the hosts. You need to verify that the IP addresses match those provided in the output above. If they match, you can safely continue with the connection.

2. **Use the Instance**:
   - Connect to the development instance from your local machine with `ssh remote-dev-ec2`.

3. **Start the Instaces with `start.sh`**:
   - Starts the development and bastion EC2 instances (not required directly after `build.sh`).

4. **Stop the Instances with `stop.sh`**:
  - Stops the development and bastion EC2 instances without terminating them.
    - Stopping instances will preserve the state of the instance and all data on the attached EBS volumes (disks).
    - The instances can be started again later without data loss, as long as the EBS volumes are not set to be deleted on termination.

5. **Remove All Resources with `destroy.sh`**:
  - Destroys all AWS resources created by Terraform.
  - Restores the original state of `~/.ssh/config`.

## Costs

Running the remote instances involves costs that depend primarily on instance type. The costs may also vary between regions and are subject to change over time. As of September 16, 2024, the cost for a single default EC2 `t3.micro` instance with 1 GB of RAM in the `eu-north-1` region is $0.0108 per hour. Be sure to check the [latest AWS pricing](https://aws.amazon.com/ec2/pricing/on-demand/) for the most up-to-date information.


## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT). You are free to use, modify, and distribute the software as long as you include the original copyright and license notice. For more details, please refer to the full text of the license.
