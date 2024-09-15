resource "aws_instance" "bastion_instance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.bastion_instance_type
  subnet_id              = aws_subnet.public_subnet.id
  key_name               = aws_key_pair.ssh_key.key_name
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  tags = {
    Name = "${var.username}'sBastionHost"
    User = var.username
  }
}

resource "aws_security_group" "bastion_sg" {
  vpc_id = aws_vpc.dev_vpc.id
  name   = "BastionEC2SecurityGroup"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.local_public_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_eip" "bastion_eip" {
  instance = aws_instance.bastion_instance.id
  domain   = "vpc"
}
