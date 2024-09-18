resource "aws_vpc" "dev_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "${var.username}sVPC"
    User = var.username
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.dev_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.username}sPublicSubnet"
    User = var.username
  }
}

resource "aws_internet_gateway" "internet_gw" {
  vpc_id = aws_vpc.dev_vpc.id

  tags = {
    Name = "${var.username}sIGW"
    User = var.username
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.dev_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gw.id
  }

  tags = {
    Name = "${var.username}sRouteTable"
    User = var.username
  }
}

resource "aws_route_table_association" "public_route_table_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.dev_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.username}sPrivateSubnet"
    User = var.username
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "${var.username}sNATGateway"
    User = var.username
  }
}

resource "aws_eip" "nat_eip" {

  tags = {
    Name = "${var.username}sNATEIP"
    User = var.username
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.dev_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "${var.username}sPrivateRouteTable"
    User = var.username
  }
}

resource "aws_route_table_association" "private_route_table_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}
