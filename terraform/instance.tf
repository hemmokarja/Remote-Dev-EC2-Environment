resource "aws_security_group" "dev_sg" {
  vpc_id = aws_vpc.dev_vpc.id
  name   = "DevEC2SecurityGroup"

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
    # cidr_blocks = [var.local_public_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "dev_instance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.dev_instance_type
  subnet_id              = aws_subnet.private_subnet.id
  key_name               = aws_key_pair.ssh_key.key_name
  vpc_security_group_ids = [aws_security_group.dev_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.dev_instance_profile.name
  # security_groups      = [aws_security_group.dev_sg.name]

  private_ip = var.dev_instance_private_ip

  tags = {
    Name = "${var.username}'sDevEC2"
    User = var.username
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # canonical (Ubuntu) AWS account ID
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}
